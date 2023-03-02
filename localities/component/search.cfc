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

<!--- function setupClause setup variables to put into a where clause of a query for a text field.

	Expected use: 

	<cfif isdefined("country") AND len(country) gt 0>
		<cfset setup = setupClause(field="geog_auth_rec.country",value="#country#")>
		<cfif len(setup["value"]) EQ 0>
			AND #setup["pre"]# #setup["post"]#
		<cfelse>
			AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
		</cfif>
	</cfif>
	

 @param field the field name, possibly needing to be prefixed by the tablename
	field must be supplied a string value, not a variable, and must not be supplied 
   from a user, otherwise could be used for sql injection.
 @param the value to be queried for, supports the following:
	NULL, NOT NULL, operators as leading characters =, !, $, !$, ~, !~,
   and a comma separated list
 @return a struct with the properties pre, value, list, and post.
 @see setupNumericClause for numeric fields.
--->
<cffunction name="setupClause" access="private" returntype="struct">
	<cfargument name="field" type="string" required="yes">
	<cfargument name="value" type="string" required="yes">
	<cfset retval = StructNew()>
	<cfset pre = "#field#">
	<cfset outvalue = "">
	<cfset post = "">
	<cfset list = "no">
	<cfif ucase(value) EQ "NULL">
		<cfset outvalue= "">
		<cfset post= "IS NULL">
	<cfelseif ucase(value) EQ "NOT NULL">
		<cfset outvalue= "">
		<cfset post= "IS NOT NULL">
	<cfelseif left(value,1) is "=">
		<cfset pre="upper(#field#) =">
		<cfset outvalue="#ucase(right(value,len(value)-1))#">
	<cfelseif left(value,1) is "~">
		<cfset pre="utl_match.jaro_winkler(#field#,">
		<cfset outvalue="#right(value,len(value)-1)#">
		<cfset post = ") >= 0.90"><!--- " --->
	<cfelseif left(value,2) is "!~">
		<cfset pre="utl_match.jaro_winkler(#field#,"> 
		<cfset outvalue="#right(value,len(value)-2)#">
		<cfset post=") < 0.90">
	<cfelseif left(value,1) is "$">
		<cfset pre="soundex(#field#) =  soundex(">
		<cfset outvalue="#ucase(right(value,len(value)-1))#">
		<cfset post=")">
	<cfelseif left(value,2) is "!$">
		<cfset pre="soundex(#field#) <> soundex("><!--- ") --->
		<cfset outvalue="#ucase(right(value,len(value)-2))#">
		<cfset post=")">
	<cfelseif left(value,1) is "!">
		<cfset pre="upper(#field#) <>"><!--- " --->
		<cfset outvalue="#ucase(right(value,len(value)-1))#">
		<cfset post="">
	<cfelseif find(',',value) GT 0>
		<cfset pre="upper(#field#) in (">
		<cfset outvalue="#ucase(value)#">
		<cfset post = ")">
		<cfset list="yes">
	<cfelse>
		<cfset pre="upper(#field#) LIKE ">
		<cfset outvalue="%#ucase(value)#%">
		<cfset post ="">
	</cfif>
	<cfset retval["pre"]=pre>
	<cfset retval["value"]=outvalue>
	<cfset retval["post"]=post>
	<cfset retval["list"]=list>
	<cfreturn retval>
</cffunction>

<!--- function setupNumericClause setup variables to put into a where clause of a query for a
  numeric field.

	Example use, note the between clause

	<cfif isdefined("maximum_elevation") AND len(maximum_elevation) gt 0>
		<cfset setup = setupNumericClause(field="locality.maximum_elevation",value="#maximum_elevation#")>
		<cfif len(setup["value"]) EQ 0>
			AND #setup["pre"]# #setup["post"]#
		<cfelseif setup["between"] EQ "true">
			AND #setup["pre"]# 
				BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" > 
				AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#"> 
		<cfelse>
			AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
		</cfif>
	</cfif>

 @param field the field name, possibly needing to be prefixed by the tablename
	field must be supplied a string value, not a variable, and must not be supplied 
   from a user, otherwise could be used for sql injection.
 @param the value to be queried for, supports the following:
	NULL, NOT NULL, operators as leading characters =, !, <, <=, >, >=, 
   between two values and a comma separated list
 @return a struct with the properties pre, value, list, between, and post.
 @see setupClause for preparing text queries.
--->
<cffunction name="setupNumericClause" access="private" returntype="struct">
	<cfargument name="field" type="string" required="yes">
	<cfargument name="value" type="string" required="yes">
	<cfset retval = StructNew()>
	<cfset pre = "#field#">
	<cfset outvalue = "">
	<cfset outvalue2 = "">
	<cfset post = "">
	<cfset list = "no">
	<cfset between = "false">
	<cfif ucase(value) EQ "NULL">
		<cfset outvalue= "">
		<cfset post= "IS NULL">
	<cfelseif ucase(value) EQ "NOT NULL">
		<cfset outvalue= "">
		<cfset post= "IS NOT NULL">
	<cfelseif left(value,1) is "=">
		<cfset pre = "#field# = ">
		<cfset outvalue="#right(value,len(value)-1)#">
	<cfelseif left(value,1) is "!">
		<cfset pre = "#field# <> "><!--- " --->
		<cfset outvalue="#right(value,len(value)-1)#">
	<cfelseif left(value,2) is "<=" or left(value,2) IS "=<">
		<cfset pre = "#field# <= "><!--- " --->
		<cfset outvalue="#right(value,len(value)-2)#">
	<cfelseif left(value,2) is ">=" or left(value,2) IS "=>"><!--- " --->
		<cfset pre = "#field# >= "><!--- " --->
		<cfset outvalue="#right(value,len(value)-2)#">
	<cfelseif left(value,1) is "<">
		<cfset pre = "#field# < ">
		<cfset outvalue="#right(value,len(value)-1)#">
	<cfelseif left(value,1) is ">"><!--- " --->
		<cfset pre = "#field# > "><!--- " --->
		<cfset outvalue="#right(value,len(value)-1)#">
	<cfelseif find('-',value) GT 1>
		<cfset bits = listToArray(value,'-')>
		<cfif arrayLen(bits) GT 1>
			<cfset pre = "#field# ">
			<cfset between="true">
			<cfset outvalue="#bits[1]#">
			<cfset outvalue2="#bits[2]#">
		<cfelse>
			<cfset pre = "#field# = ">
			<cfset outvalue="#bits[1]#">
		</cfif>
	<cfelse>
		<cfset pre = "#field# = ">
		<cfset outvalue="#value#">
	</cfif>
	<cfset retval["pre"]=pre>
	<cfset retval["value"]=outvalue>
	<cfset retval["value2"]=outvalue2>
	<cfset retval["post"]=post>
	<cfset retval["list"]=list>
	<cfset retval["between"]=between>
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
	<cfargument name="source_authority" type="string" required="no">
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
					<cfset setup = setupClause(field="geog_auth_rec.continent_ocean",value="#continent_ocean#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("country") AND len(country) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.country",value="#country#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("state_prov") AND len(state_prov) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.state_prov",value="#state_prov#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("county") AND len(county) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.county",value="#county#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("quad") AND len(quad) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.quad",value="#quad#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("feature") AND len(feature) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.feature",value="#feature#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("island") AND len(island) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.island",value="#island#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("island_group") AND len(island_group) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.island_group",value="#island_group#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("ocean_region") AND len(ocean_region) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.ocean_region",value="#ocean_region#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("ocean_subregion") AND len(ocean_subregion) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.ocean_subregion",value="#ocean_subregion#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("sea") AND len(sea) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.sea",value="#sea#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("water_feature") AND len(water_feature) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.water_feature",value="#water_feature#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("source_authority") AND len(source_authority) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.source_authority",value="#source_authority#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("highergeographyid") AND len(highergeographyid) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.highergeographyid",value="#highergeographyid#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("highergeographyid_guid_type") AND len(highergeographyid_guid_type) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.highergeographyid_guid_type",value="#highergeographyid_guid_type#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
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
	<cfargument name="any_geography" type="string" required="no"><!--- keyword index search --->
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
	<cfargument name="source_authority" type="string" required="no">
	<cfargument name="return_wkt" type="string" required="no">
	<cfargument name="locality_id" type="string" required="no">
	<cfargument name="spec_locality" type="string" required="no">
	<cfargument name="locality_remarks" type="string" required="no">
	<cfargument name="orig_elev_units" type="string" required="no">
	<cfargument name="minElevOper" type="string" required="no">
	<cfargument name="minimum_elevation" type="string" required="no">
	<cfargument name="minimum_elevation_m" type="string" required="no">
	<cfargument name="maxElevOper" type="string" required="no">
	<cfargument name="maximum_elevation" type="string" required="no">
	<cfargument name="maximum_elevation_m" type="string" required="no">
	<cfargument name="depth_units" type="string" required="no">
	<cfargument name="minDepthOper" type="string" required="no">
	<cfargument name="min_depth" type="string" required="no">
	<cfargument name="min_depth_m" type="string" required="no">
	<cfargument name="maxDepthOper" type="string" required="no">
	<cfargument name="max_depth" type="string" required="no">
	<cfargument name="max_depth_m" type="string" required="no">
	<cfargument name="accentInsenstive" type="string" required="no">
	<cfargument name="collection_id" type="string" required="no">
	<cfargument name="collnOper" type="string" required="no">
	<cfargument name="include_counts" type="string" required="no"><!--- locality counts by collection --->
	<cfargument name="township" type="string" required="no">
	<cfargument name="range" type="string" required="no">
	<cfargument name="township_direction" type="string" required="no">
	<cfargument name="range_direction" type="string" required="no">
	<cfargument name="section" type="string" required="no">
	<cfargument name="section_part" type="string" required="no">
	<cfargument name="dec_lat" type="string" required="no">
	<cfargument name="dec_long" type="string" required="no">
	<cfargument name="datum" type="string" required="no">
	<cfargument name="max_error_distance" type="string" required="no">
	<cfargument name="georef_updated_date" type="string" required="no">
	<cfargument name="georef_by" type="string" required="no">
	<cfargument name="geolocate_precision" type="string" required="no">
	<cfargument name="geolocate_score" type="string" required="no">
	<cfargument name="geolocate_score2" type="string" required="no">
	<cfargument name="gs_comparator" type="string" required="no">
	<cfargument name="coordinateDeterminer" type="string" required="no">
	<cfargument name="georeference_verified_by_id" type="string" required="no">
	<cfargument name="georeference_verified_by" type="string" required="no">
	<!--- 
	"LEGACY_SPEC_LOCALITY_FG" NUMBER,  Unused
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
	<cfset includeCounts = false>
	<cfif isdefined("include_counts") AND include_counts EQ 1 >
		<cfset includeCounts=true>
	</cfif>
	<cfif not isdefined("gs_comparator") and len(gs_comparator) gt 0>
		<cfset gs_comparator = "">
	</cfif>

	<!--- convert min/max ElevOper variables to operators as leading characters of min/max elevation --->
	<cfif isdefined("maximum_elevation") AND len(maximum_elevation) gt 0>
		<cfif isDefined("maxElevOper") and maxElevOper EQ "!" and left(maximum_elevation,1) NEQ "!">
			<cfset maximum_elevation="!#maximum_elevation#">
		</cfif>
		<cfif isDefined("maxElevOper") and maxElevOper EQ "<>" and left(maximum_elevation,2) NEQ "<>">
			<cfset maximum_elevation="!#maximum_elevation#"><!--- " --->
		</cfif>
		<cfif isDefined("maxElevOper") and maxElevOper EQ "<" and left(maximum_elevation,1) NEQ "<">
			<cfset maximum_elevation="<#maximum_elevation#">
		</cfif>
		<cfif isDefined("maxElevOper") and maxElevOper EQ ">" and left(maximum_elevation,1) NEQ ">">
			<cfset maximum_elevation=">#maximum_elevation#"><!--- " --->
		</cfif>
	</cfif>
	<cfif isdefined("minimum_elevation") AND len(minimum_elevation) gt 0>
		<cfif isDefined("minElevOper") and minElevOper EQ "!" and left(minimum_elevation,1) NEQ "!">
			<cfset minimum_elevation="!#minimum_elevation#">
		</cfif>
		<cfif isDefined("minElevOper") and minElevOper EQ "<>" and left(minimum_elevation,2) NEQ "<>">
			<cfset minimum_elevation="!#minimum_elevation#"><!--- " --->
		</cfif>
		<cfif isDefined("minElevOper") and minElevOper EQ "<" and left(minimum_elevation,1) NEQ "<">
			<cfset minimum_elevation="<#minimum_elevation#">
		</cfif>
		<cfif isDefined("minElevOper") and minElevOper EQ ">" and left(minimum_elevation,1) NEQ ">">
			<cfset minimum_elevation=">#minimum_elevation#"><!--- " --->
		</cfif>
	</cfif>
	<cfif isdefined("maximum_elevation_m") AND len(maximum_elevation_m) gt 0>
		<cfif isDefined("maxElevOperM") and maxElevOperM EQ "!" and left(maximum_elevation_m,1) NEQ "!">
			<cfset maximum_elevation_m="!#maximum_elevation_m#">
		</cfif>
		<cfif isDefined("maxElevOperM") and maxElevOperM EQ "<>" and left(maximum_elevation_m,2) NEQ "<>">
			<cfset maximum_elevation_m="!#maximum_elevation_m#"><!--- " --->
		</cfif>
		<cfif isDefined("maxElevOperM") and maxElevOperM EQ "<" and left(maximum_elevation_m,1) NEQ "<">
			<cfset maximum_elevation_m="<#maximum_elevation_m#">
		</cfif>
		<cfif isDefined("maxElevOperM") and maxElevOperM EQ ">" and left(maximum_elevation_m,1) NEQ ">">
			<cfset maximum_elevation_m=">#maximum_elevation_m#"><!--- " --->
		</cfif>
	</cfif>
	<cfif isdefined("minimum_elevation_m") AND len(minimum_elevation_m) gt 0>
		<cfif isDefined("MinElevOperM") and minElevOperM EQ "!" and left(minimum_elevation_m,1) NEQ "!">
			<cfset minimum_elevation_m="!#minimum_elevation_m#">
		</cfif>
		<cfif isDefined("MinElevOperM") and minElevOperM EQ "<>" and left(minimum_elevation_m,2) NEQ "<>">
			<cfset minimum_elevation_m="!#minimum_elevation_m#"><!--- " --->
		</cfif>
		<cfif isDefined("MinElevOperM") and minElevOperM EQ "<" and left(minimum_elevation_m,1) NEQ "<">
			<cfset minimum_elevation_m="<#minimum_elevation_m#">
		</cfif>
		<cfif isDefined("MinElevOperM") and minElevOperM EQ ">" and left(minimum_elevation_m,1) NEQ ">">
			<cfset minimum_elevation_m=">#minimum_elevation_m#"><!--- " --->
		</cfif>
	</cfif>
	<!--- convert min/max DepthOper variables to operators as leading characters of min/max depth --->
	<cfif isdefined("max_depth") AND len(max_depth) gt 0>
		<cfif isDefined("maxDepthOper") and maxDepthOper EQ "!" and left(max_depth,1) NEQ "!">
			<cfset max_depth="!#max_depth#">
		</cfif>
		<cfif isDefined("maxDepthOper") and maxDepthOper EQ "<>" and left(max_depth,2) NEQ "<>">
			<cfset max_depth="!#max_depth#"><!--- " --->
		</cfif>
		<cfif isDefined("maxDepthOper") and maxDepthOper EQ "<" and left(max_depth,1) NEQ "<">
			<cfset max_depth="<#max_depth#">
		</cfif>
		<cfif isDefined("maxDepthOper") and maxDepthOper EQ ">" and left(max_depth,1) NEQ ">">
			<cfset max_depth=">#max_depth#"><!--- " --->
		</cfif>
	</cfif>
	<cfif isdefined("min_depth") AND len(min_depth) gt 0>
		<cfif isDefined("minDepthOper") and minDepthOper EQ "!" and left(min_depth,1) NEQ "!">
			<cfset min_depth="!#min_depth#">
		</cfif>
		<cfif isDefined("minDepthOper") and minDepthOper EQ "<>" and left(min_depth,2) NEQ "<>">
			<cfset min_depth="!#min_depth#"><!--- " --->
		</cfif>
		<cfif isDefined("minDepthOper") and minDepthOper EQ "<" and left(min_depth,1) NEQ "<">
			<cfset min_depth="<#min_depth#">
		</cfif>
		<cfif isDefined("minDepthOper") and minDepthOper EQ ">" and left(min_depth,1) NEQ ">">
			<cfset min_depth=">#min_depth#"><!--- " --->
		</cfif>
	</cfif>
	<cfif isdefined("max_depth_m") AND len(max_depth_m) gt 0>
		<cfif isDefined("maxDepthOperM") and maxDepthOperM EQ "!" and left(max_depth_m,1) NEQ "!">
			<cfset max_depth_m="!#max_depth_m#">
		</cfif>
		<cfif isDefined("maxDepthOperM") and maxDepthOperM EQ "<>" and left(max_depth_m,2) NEQ "<>">
			<cfset max_depth_m="!#max_depth_m#"><!--- " --->
		</cfif>
		<cfif isDefined("maxDepthOperM") and maxDepthOperM EQ "<" and left(max_depth_m,1) NEQ "<">
			<cfset max_depth_m="<#max_depth_m#">
		</cfif>
		<cfif isDefined("maxDepthOperM") and maxDepthOperM EQ ">" and left(max_depth_m,1) NEQ ">">
			<cfset max_depth_m=">#max_depth_m#"><!--- " --->
		</cfif>
	</cfif>
	<cfif isdefined("min_depth_m") AND len(min_depth_m) gt 0>
		<cfif isDefined("MinDepthOperM") and minDepthOperM EQ "!" and left(min_depth_m,1) NEQ "!">
			<cfset min_depth_m="!#min_depth_m#">
		</cfif>
		<cfif isDefined("MinDepthOperM") and minDepthOperM EQ "<>" and left(min_depth_m,2) NEQ "<>">
			<cfset min_depth_m="!#min_depth_m#"><!--- " --->
		</cfif>
		<cfif isDefined("MinDepthOperM") and minDepthOperM EQ "<" and left(min_depth_m,1) NEQ "<">
			<cfset min_depth_m="<#min_depth_m#">
		</cfif>
		<cfif isDefined("MinDepthOperM") and minDepthOperM EQ ">" and left(min_depth_m,1) NEQ ">">
			<cfset min_depth_m=">#min_depth_m#"><!--- " --->
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
				to_meters(locality.minimum_elevation,locality.orig_elev_units) min_elevation_meters,
				to_meters(locality.maximum_elevation,locality.orig_elev_units) max_elevation_meters,
				locality.max_depth,
				locality.min_depth,
				locality.depth_units,
				to_meters(locality.min_depth,locality.depth_units) min_depth_meters,
				to_meters(locality.max_depth,locality.depth_units) max_depth_meters,
				locality.curated_fg,
				locality.sovereign_nation,
				locality.georef_updated_date,
				locality.georef_by,
				locality.nogeorefbecause,
				trim(upper(section_part) || ' ' || nvl2(section,'S','') || section ||  nvl2(township,' T',' ') || township || upper(township_direction) || nvl2(range,' R',' ') || range || upper(range_direction)) as plss,
				concatGeologyAttributeDetail(locality.locality_id) geolAtts,
				<cfif includeCounts >
					MCZBASE.get_collcodes_for_locality(locality.locality_id)  as collcountlocality,
				<cfelse>
					null as collcountlocality,
				</cfif>
  				accepted_lat_long.LAT_LONG_ID,
				accepted_lat_long.dec_lat,
				accepted_lat_long.dec_long,
				accepted_lat_long.datum,
				accepted_lat_long.max_error_distance,
				to_meters(accepted_lat_long.max_error_distance, accepted_lat_long.max_error_units) coordinateUncertaintyInMeters,
				accepted_lat_long.extent,
				accepted_lat_long.verificationstatus,
				accepted_lat_long.georefmethod,
				georef_verified_agent.agent_name georef_verified_by_agent,
				georef_determined_agent.agent_name georef_determined_by_agent,
				count(flatTableName.collection_object_id) as specimen_count
			FROM 
				locality
				join geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
				left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>flat<cfelse>filtered_flat</cfif> flatTableName on locality.locality_id=flatTableName.locality_id
				left join accepted_lat_long on locality.locality_id = accepted_lat_long.locality_id
				<cfif (isdefined("geology_attribute") AND len(#geology_attribute#) gt 0) OR (isdefined("geo_att_value") AND len(#geo_att_value#) gt 0)>
					left join geology_attributes on locality.locality_id = geology_attributes.locality_id
				</cfif>
				left join preferred_agent_name georef_verified_agent on accepted_lat_long.verified_by_agent_id = georef_verified_agent.agent_id
				left join preferred_agent_name georef_determined_agent on accepted_lat_long.determined_by_agent_id = georef_determined_agent.agent_id
			WHERE
				locality.locality_id is not null
				<cfif isDefined("any_geography") and len(any_geography) gt 0>
					and locality.locality_id in (select locality_id from flat where contains(HIGHER_GEOG,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#any_geography#">,1) > 0)
				</cfif>
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
					<cfset setup = setupClause(field="geog_auth_rec.continent_ocean",value="#continent_ocean#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("country") AND len(country) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.country",value="#country#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("state_prov") AND len(state_prov) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.state_prov",value="#state_prov#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("county") AND len(county) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.county",value="#county#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("quad") AND len(quad) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.quad",value="#quad#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("feature") AND len(feature) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.feature",value="#feature#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("island") AND len(island) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.island",value="#island#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("island_group") AND len(island_group) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.island_group",value="#island_group#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("ocean_region") AND len(ocean_region) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.ocean_region",value="#ocean_region#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("ocean_subregion") AND len(ocean_subregion) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.ocean_subregion",value="#ocean_subregion#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("sea") AND len(sea) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.sea",value="#sea#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("water_feature") AND len(water_feature) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.water_feature",value="#water_feature#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("source_authority") AND len(source_authority) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.source_authority",value="#source_authority#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("highergeographyid") AND len(highergeographyid) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.highergeographyid",value="#highergeographyid#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("highergeographyid_guid_type") AND len(highergeographyid_guid_type) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.highergeographyid_guid_type",value="#highergeographyid_guid_type#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
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
					<cfset setup = setupClause(field="locality.spec_locality",value="#spec_locality#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("locality_remarks") AND len(locality_remarks) gt 0>
					<cfset setup = setupClause(field="locality.locality_remarks",value="#locality_remarks#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("orig_elev_units") AND len(orig_elev_units) gt 0>
					<cfset setup = setupClause(field="locality.orig_elev_units",value="#orig_elev_units#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("minimum_elevation") AND len(minimum_elevation) gt 0>
					<cfset setup = setupNumericClause(field="locality.minimum_elevation",value="#minimum_elevation#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelseif setup["between"] EQ "true">
						AND #setup["pre"]# 
						BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" > 
						AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#"> 
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("minimum_elevation_m") and len(#minimum_elevation_m#) gt 0>
					<cfset setup = setupNumericClause(field="TO_METERS(locality.minimum_elevation,locality.orig_elev_units)",value="#minimum_elevation_m#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelseif setup["between"] EQ "true">
						AND #setup["pre"]# 
						BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" > 
						AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#"> 
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("maximum_elevation") AND len(maximum_elevation) gt 0>
					<cfset setup = setupNumericClause(field="locality.maximum_elevation",value="#maximum_elevation#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelseif setup["between"] EQ "true">
						AND #setup["pre"]# 
						BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" > 
						AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#"> 
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("maximum_elevation_m") and len(#maximum_elevation_m#) gt 0>
					<cfset setup = setupNumericClause(field="TO_METERS(locality.maximum_elevation,locality.orig_elev_units)",value="#maximum_elevation_m#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelseif setup["between"] EQ "true">
						AND #setup["pre"]# 
						BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" > 
						AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#"> 
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("depth_units") AND len(depth_units) gt 0>
					<cfset setup = setupClause(field="locality.depth_units",value="#depth_units#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("min_depth") AND len(min_depth) gt 0>
					<cfset setup = setupNumericClause(field="locality.min_depth",value="#min_depth#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelseif setup["between"] EQ "true">
						AND #setup["pre"]# 
						BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" > 
						AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#"> 
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("min_depth_m") and len(#min_depth_m#) gt 0>
					<cfset setup = setupNumericClause(field="TO_METERS(locality.min_depth,locality.depth_units)",value="#min_depth_m#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelseif setup["between"] EQ "true">
						AND #setup["pre"]# 
						BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" > 
						AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#"> 
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("max_depth") AND len(max_depth) gt 0>
					<cfset setup = setupNumericClause(field="locality.max_depth",value="#max_depth#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelseif setup["between"] EQ "true">
						AND #setup["pre"]# 
						BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" > 
						AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#"> 
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("max_depth_m") and len(#max_depth_m#) gt 0>
					<cfset setup = setupNumericClause(field="TO_METERS(locality.max_depth,locality.depth_units)",value="#max_depth_m#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelseif setup["between"] EQ "true">
						AND #setup["pre"]# 
						BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" > 
						AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#"> 
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("section") AND len(section) gt 0>
					<cfset setup = setupNumericClause(field="locality.section",value="#section#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelseif setup["between"] EQ "true">
						AND #setup["pre"]# 
						BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" > 
						AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#"> 
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("township") AND len(township) gt 0>
					<cfset setup = setupNumericClause(field="locality.township",value="#township#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelseif setup["between"] EQ "true">
						AND #setup["pre"]# 
						BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" > 
						AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#"> 
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("range") AND len(range) gt 0>
					<cfset setup = setupNumericClause(field="locality.range",value="#range#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelseif setup["between"] EQ "true">
						AND #setup["pre"]# 
						BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" > 
						AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#"> 
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("township_direction") AND len(township_direction) gt 0>
					<cfif ucase(township_direction) EQ "NULL">
						and locality.township_direction IS NULL
					<cfelseif ucase(township_direction) EQ "NOT NULL">
						and locality.township_direction IS NOT NULL	
					<cfelse>
						AND upper(locality.township_direction) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#township_direction#">
					</cfif>
				</cfif>
				<cfif isdefined("range_direction") AND len(range_direction) gt 0>
					<cfif ucase(range_direction) EQ "NULL">
						and locality.range_direction IS NULL
					<cfelseif ucase(range_direction) EQ "NOT NULL">
						and locality.range_direction IS NOT NULL	
					<cfelse>
						AND upper(locality.range_direction) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#range_direction#">
					</cfif>
				</cfif>
				<cfif isdefined("section_part") AND len(section_part) gt 0>
					<cfset setup = setupClause(field="locality.section_part",value="#section_part#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
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
				<cfif isdefined("geology_attribute") and len(#geology_attribute#) gt 0>
					AND geology_attributes.geology_attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geology_attribute#">
				</cfif>
				<cfif isdefined("geo_att_value") and len(#geo_att_value#) gt 0>
					<cfif isdefined("geology_attribute_hier") and #geology_attribute_hier# is 1>
						AND geology_attributes.geo_att_value
							IN ( SELECT attribute_value
								FROM geology_attribute_hierarchy
								START WITH upper(attribute_value) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(geo_att_value)#%">
								CONNECT BY PRIOR geology_attribute_hierarchy_id = parent_id )
					<cfelse>
						AND upper(geology_attributes.geo_att_value) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(geo_att_value)#%">
					</cfif>
				</cfif>
				<cfif isdefined("georef_updated_date") and len(georef_updated_date) gt 0>
					<cfif georef_updated_date is "NULL">
						AND georef_updated_date IS NULL
					<cfelseif georef_updated_date is "NOT NULL">
						AND georef_updated_date IS NOT NULL
					<cfelseif refind("^[0-9]{4}-[0-9]{2}-[0-9]{2}$",georef_update_date) EQ 1>
						AND georef_updated_date = <cfqueryparam cfsqltype="CF_SQL_DATE" value="#date_format(georef_updated_date,'yyyy-mm-dd')#">
					<cfelseif refind("^[0-9]{4}$",georef_update_date) EQ 1>
						<cfset startDate = "#georef_update_date#-01-01">
						<cfset endDate = "#georef_update_date#-12-31">
						AND georef_updated_date 
							between <cfqueryparam cfsqltype="CF_SQL_DATE" value="#date_format(startDate,'yyyy-mm-dd')#">
							and<cfqueryparam cfsqltype="CF_SQL_DATE" value="#date_format(endDate,'yyyy-mm-dd')#">
					<cfelseif refind("^[0-9]{4}-[0-9]{2}-[0-9]{2}/[0-9]{4}-[0-9]{2}-[0-9]{2}$",georef_update_date) EQ 1>
						<cfset bits = listToArray(georef_update_date,'/')>
						<cfset startDate = bits[1]>
						<cfset endDate = bits[2]>
						AND georef_updated_date 
							between <cfqueryparam cfsqltype="CF_SQL_DATE" value="#date_format(startDate,'yyyy-mm-dd')#">
							and<cfqueryparam cfsqltype="CF_SQL_DATE" value="#date_format(endDate,'yyyy-mm-dd')#">
					<cfelseif refind("^[0-9]{4}}/[0-9]{4}$",georef_update_date) EQ 1>
						<cfset bits = listToArray(georef_update_date,'/')>
						<cfset startDate = "#bits[1]#-01-01">
						<cfset endDate = "#bits[2]#-12-31">
						AND georef_updated_date 
							between <cfqueryparam cfsqltype="CF_SQL_DATE" value="#date_format(startDate,'yyyy-mm-dd')#">
							and<cfqueryparam cfsqltype="CF_SQL_DATE" value="#date_format(endDate,'yyyy-mm-dd')#">
					<cfelse>
						<cfthrow message = "unsupported date search format for georef_updated_date.  Use: yyyy-mm-dd, yyyy, yyyy/yyyy, yyyy-mm-dd/yyyy-mm-dd, NULL or NOT NULL.">
					</cfif>
				</cfif>
				<cfif isdefined("georef_by") AND len(georef_by) gt 0>
					<cfset setup = setupClause(field="locality.georef_by",value="#georef_by#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("NoGeorefBecause") AND len(#NoGeorefBecause#) gt 0>
					AND upper(NoGeorefBecause) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(NoGeorefBecause)#%">
				</cfif>
				<cfif isdefined("VerificationStatus") AND len(#VerificationStatus#) gt 0>
					AND VerificationStatus = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VerificationStatus#">
				</cfif>
				<cfif isdefined("GeorefMethod") AND len(#GeorefMethod#) gt 0>
					AND GeorefMethod = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#GeorefMethod#">
				</cfif>
				<cfif isdefined("nullNoGeorefBecause") and len(#nullNoGeorefBecause#) gt 0>
					AND NoGeorefBecause IS NULL
				</cfif>
				<cfif isdefined("isIncomplete") AND len(#isIncomplete#) gt 0>
					AND ( (GPSACCURACY IS NULL AND EXTENT IS NULL) OR MAX_ERROR_DISTANCE = 0 or MAX_ERROR_DISTANCE IS NULL or datum IS NULL or coordinate_precision IS NULL )
				</cfif>
				<cfif isdefined("findNoAccGeoRef") and len(#findNoAccGeoRef#) gt 0>
					AND locality.locality_id IN (select locality_id from lat_long)
					AND locality.locality_id NOT IN (select locality_id from lat_long where accepted_lat_long_fg=1)
				</cfif>
				<cfif isdefined("findNoAccGeoRefStrict") and len(#findNoAccGeoRefStrict#) gt 0>
					AND locality.locality_id NOT IN (select locality_id from lat_long where accepted_lat_long_fg=1)
				</cfif>
				<cfif isdefined("findNoGeoRef") and len(#findNoGeoRef#) gt 0>
					AND locality.locality_id NOT IN (select locality_id from lat_long)
				</cfif>
				<cfif isdefined("findHasGeoRef") and len(#findHasGeoRef#) gt 0>
					AND locality.locality_id IN (select locality_id from lat_long)
				</cfif>
				<cfif isdefined("onlyShared") and len(#onlyShared#) gt 0>
					AND locality.locality_id in (select locality_id from FLAT group by locality_id having count(distinct collection_cde) > 1)
				</cfif>
				<cfif isdefined("dec_lat") and len(#dec_lat#) gt 0>
					<cfset setup = setupNumericClause(field="accepted_lat_long.dec_lat",value="#dec_lat#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelseif setup["between"] EQ "true">
						AND #setup["pre"]# 
						BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" > 
						AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#"> 
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("dec_long") and len(#dec_long#) gt 0>
					<cfset setup = setupNumericClause(field="accepted_lat_long.dec_long",value="#dec_long#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelseif setup["between"] EQ "true">
						AND #setup["pre"]# 
						BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" > 
						AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#"> 
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("datum") AND len(datum) gt 0>
					<cfset setup = setupClause(field="accepted_lat_long.datum",value="#datum#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("max_error_distance") and len(#max_error_distance#) gt 0>
					<cfset setup = setupNumericClause(field="accepted_lat_long.max_error_distance",value="#max_error_distance#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelseif setup["between"] EQ "true">
						AND #setup["pre"]# 
						BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" > 
						AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#"> 
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("georeference_verified_by_id") and len(#georeference_verified_by_id#) gt 0>
					and georef_verified_agent.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#georeference_verified_by_id#">
				<cfelseif isdefined("georeference_verified_by") and len(#georeference_verified_by#) gt 0>
					<cfset setup = setupClause(field="georef_verified_agent.agent_name",value="#georeference_verified_by#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("georeference_determined_by_id") and len(#georeference_determined_by_id#) gt 0>
					AND georef_determined_agent.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#georeference_determined_by_id#">
				<cfelseif isdefined("coordinateDeterminer") and len(#coordinateDeterminer#) gt 0>
					<cfset setup = setupClause(field="georef_determined_agent.agent_name",value="#coordinateDeterminer#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("geolocate_precision") and len(#geolocate_precision#) gt 0>
					AND lower(accepted_lat_long.geolocate_precision) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geolocate_precision#">
				</cfif>
				<cfif isdefined("geolocate_score") and len(#geolocate_score#) gt 0>
					<cfif ArrayLen(REMatch("^[0-9]+\-[0-9]+$",geolocate_score))>0 >
						<!--- new operator parser on single geolocate_score --->
						<cfset bits = ListToArray(geolocate_score,"-")>
						AND accepted_lat_long.geolocate_score
							BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bits[1]#">
							AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bits[2]#">
					<cfelseif geolocate_score EQ 'NULL'>
						AND accepted_lat_long.geolocate_score IS NULL
					<cfelseif geolocate_score EQ 'NOT NULL'>
						AND accepted_lat_long.geolocate_score IS NOT NULL
					<cfelse>
						<!--- old form fields --->
						<cfswitch expression="#gs_comparator#">
							<cfcase value = "between">
								AND accepted_lat_long.geolocate_score
									BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geolocate_score#">
									AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geolocate_score2#">
							</cfcase>
							<cfcase value = ">"><!--- " --->
								AND accepted_lat_long.geolocate_score > <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geolocate_score#">
							</cfcase>
							<cfcase value = "<">
								AND accepted_lat_long.geolocate_score < <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geolocate_score#">
							</cfcase>
							<cfcase value = "<>"><!--- " --->
								AND accepted_lat_long.geolocate_score <> <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geolocate_score#">
							</cfcase>
							<cfdefaultcase>
								AND accepted_lat_long.geolocate_score = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geolocate_score#">
							</cfdefaultcase>
						</cfswitch>
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
				locality.max_depth,
				locality.min_depth,
				locality.depth_units,
				locality.curated_fg,
				locality.sovereign_nation,
				locality.nogeorefbecause,
				locality.georef_updated_date,
				locality.georef_by,
				locality.township, locality.township_direction, locality.range, locality.range_direction,
				locality.section, locality.section_part,
  				accepted_lat_long.LAT_LONG_ID,
				accepted_lat_long.dec_lat,
				accepted_lat_long.dec_long,
				accepted_lat_long.datum,
				accepted_lat_long.max_error_distance,
				accepted_lat_long.max_error_units,
				accepted_lat_long.extent,
				accepted_lat_long.verificationstatus,
				accepted_lat_long.georefmethod,
				georef_verified_agent.agent_name,
				georef_determined_agent.agent_name,
				concatGeologyAttributeDetail(locality.locality_id)
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


<!---   Function getCollectingEvents
   Obtain a list of collecting events in a form suitable for display in a jqxgrid

	@return json containing data about collecting events matching specified search criteria.
--->
<cffunction name="getCollectingEvents" access="remote" returntype="any" returnformat="json">
	<cfargument name="any_geography" type="string" required="no"><!--- keyword index search --->
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
	<cfargument name="source_authority" type="string" required="no">
	<cfargument name="return_wkt" type="string" required="no">
	<cfargument name="locality_id" type="string" required="no">
	<cfargument name="spec_locality" type="string" required="no">
	<cfargument name="locality_remarks" type="string" required="no">
	<cfargument name="orig_elev_units" type="string" required="no">
	<cfargument name="minElevOper" type="string" required="no">
	<cfargument name="minimum_elevation" type="string" required="no">
	<cfargument name="minimum_elevation_m" type="string" required="no">
	<cfargument name="maxElevOper" type="string" required="no">
	<cfargument name="maximum_elevation" type="string" required="no">
	<cfargument name="maximum_elevation_m" type="string" required="no">
	<cfargument name="depth_units" type="string" required="no">
	<cfargument name="minDepthOper" type="string" required="no">
	<cfargument name="min_depth" type="string" required="no">
	<cfargument name="min_depth_m" type="string" required="no">
	<cfargument name="maxDepthOper" type="string" required="no">
	<cfargument name="max_depth" type="string" required="no">
	<cfargument name="max_depth_m" type="string" required="no">
	<cfargument name="accentInsenstive" type="string" required="no">
	<cfargument name="collection_id" type="string" required="no">
	<cfargument name="collnOper" type="string" required="no">
	<cfargument name="include_counts" type="string" required="no"><!--- locality counts by collection --->
	<cfargument name="township" type="string" required="no">
	<cfargument name="range" type="string" required="no">
	<cfargument name="township_direction" type="string" required="no">
	<cfargument name="range_direction" type="string" required="no">
	<cfargument name="section" type="string" required="no">
	<cfargument name="section_part" type="string" required="no">
	<cfargument name="dec_lat" type="string" required="no">
	<cfargument name="dec_long" type="string" required="no">
	<cfargument name="datum" type="string" required="no">
	<cfargument name="max_error_distance" type="string" required="no">
	<cfargument name="georef_updated_date" type="string" required="no">
	<cfargument name="georef_by" type="string" required="no">
	<cfargument name="geolocate_precision" type="string" required="no">
	<cfargument name="geolocate_score" type="string" required="no">
	<cfargument name="geolocate_score2" type="string" required="no">
	<cfargument name="gs_comparator" type="string" required="no">
	<cfargument name="coordinateDeterminer" type="string" required="no">
	<cfargument name="georeference_verified_by_id" type="string" required="no">
	<cfargument name="georeference_verified_by" type="string" required="no">
	<cfargument name="verbatim_locality" type="string" required="no">
	<cfargument name="verbatimdepth" type="string" required="no">
	<cfargument name="verbatimelevation" type="string" required="no">
	<cfargument name="verbatim_date" type="string" required="no">
	<cfargument name="collecting_source" type="string" required="no">
	<cfargument name="collecting_method" type="string" required="no">
	<cfargument name="habitat_desc" type="string" required="no">
	<cfargument name="coll_event_remarks" type="string" required="no">
	<cfargument name="began_date" type="string" required="no">
	<cfargument name="ended_date" type="string" required="no">
	<cfargument name="verbatimCoordinates" type="string" required="no">
	<!--- 
	"LEGACY_SPEC_LOCALITY_FG" NUMBER,  Unused
	--->
	<!--- 
	"VALID_DISTRIBUTION_FG" NUMBER, 
	"DATE_DETERMINED_BY_AGENT_ID" NUMBER, 
	"FISH_FIELD_NUMBER" VARCHAR2(50 CHAR), 
	"COLLECTING_TIME" VARCHAR2(50), 
	"VERBATIMLATITUDE" VARCHAR2(50 CHAR), 
	"VERBATIMLONGITUDE" VARCHAR2(50 CHAR), 
	"VERBATIMCOORDINATESYSTEM" VARCHAR2(50 CHAR), 
	"VERBATIMSRS" VARCHAR2(50 CHAR), 
	"STARTDAYOFYEAR" NUMBER(3,0), 
	"ENDDAYOFYEAR" NUMBER(3,0), 
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
	<cfset includeCounts = false>
	<cfif isdefined("include_counts") AND include_counts EQ 1 >
		<cfset includeCounts=true>
	</cfif>
	<cfif not isdefined("gs_comparator") and len(gs_comparator) gt 0>
		<cfset gs_comparator = "">
	</cfif>

	<!--- convert min/max ElevOper variables to operators as leading characters of min/max elevation --->
	<cfif isdefined("maximum_elevation") AND len(maximum_elevation) gt 0>
		<cfif isDefined("maxElevOper") and maxElevOper EQ "!" and left(maximum_elevation,1) NEQ "!">
			<cfset maximum_elevation="!#maximum_elevation#">
		</cfif>
		<cfif isDefined("maxElevOper") and maxElevOper EQ "<>" and left(maximum_elevation,2) NEQ "<>">
			<cfset maximum_elevation="!#maximum_elevation#"><!--- " --->
		</cfif>
		<cfif isDefined("maxElevOper") and maxElevOper EQ "<" and left(maximum_elevation,1) NEQ "<">
			<cfset maximum_elevation="<#maximum_elevation#">
		</cfif>
		<cfif isDefined("maxElevOper") and maxElevOper EQ ">" and left(maximum_elevation,1) NEQ ">">
			<cfset maximum_elevation=">#maximum_elevation#"><!--- " --->
		</cfif>
	</cfif>
	<cfif isdefined("minimum_elevation") AND len(minimum_elevation) gt 0>
		<cfif isDefined("minElevOper") and minElevOper EQ "!" and left(minimum_elevation,1) NEQ "!">
			<cfset minimum_elevation="!#minimum_elevation#">
		</cfif>
		<cfif isDefined("minElevOper") and minElevOper EQ "<>" and left(minimum_elevation,2) NEQ "<>">
			<cfset minimum_elevation="!#minimum_elevation#"><!--- " --->
		</cfif>
		<cfif isDefined("minElevOper") and minElevOper EQ "<" and left(minimum_elevation,1) NEQ "<">
			<cfset minimum_elevation="<#minimum_elevation#">
		</cfif>
		<cfif isDefined("minElevOper") and minElevOper EQ ">" and left(minimum_elevation,1) NEQ ">">
			<cfset minimum_elevation=">#minimum_elevation#"><!--- " --->
		</cfif>
	</cfif>
	<cfif isdefined("maximum_elevation_m") AND len(maximum_elevation_m) gt 0>
		<cfif isDefined("maxElevOperM") and maxElevOperM EQ "!" and left(maximum_elevation_m,1) NEQ "!">
			<cfset maximum_elevation_m="!#maximum_elevation_m#">
		</cfif>
		<cfif isDefined("maxElevOperM") and maxElevOperM EQ "<>" and left(maximum_elevation_m,2) NEQ "<>">
			<cfset maximum_elevation_m="!#maximum_elevation_m#"><!--- " --->
		</cfif>
		<cfif isDefined("maxElevOperM") and maxElevOperM EQ "<" and left(maximum_elevation_m,1) NEQ "<">
			<cfset maximum_elevation_m="<#maximum_elevation_m#">
		</cfif>
		<cfif isDefined("maxElevOperM") and maxElevOperM EQ ">" and left(maximum_elevation_m,1) NEQ ">">
			<cfset maximum_elevation_m=">#maximum_elevation_m#"><!--- " --->
		</cfif>
	</cfif>
	<cfif isdefined("minimum_elevation_m") AND len(minimum_elevation_m) gt 0>
		<cfif isDefined("MinElevOperM") and minElevOperM EQ "!" and left(minimum_elevation_m,1) NEQ "!">
			<cfset minimum_elevation_m="!#minimum_elevation_m#">
		</cfif>
		<cfif isDefined("MinElevOperM") and minElevOperM EQ "<>" and left(minimum_elevation_m,2) NEQ "<>">
			<cfset minimum_elevation_m="!#minimum_elevation_m#"><!--- " --->
		</cfif>
		<cfif isDefined("MinElevOperM") and minElevOperM EQ "<" and left(minimum_elevation_m,1) NEQ "<">
			<cfset minimum_elevation_m="<#minimum_elevation_m#">
		</cfif>
		<cfif isDefined("MinElevOperM") and minElevOperM EQ ">" and left(minimum_elevation_m,1) NEQ ">">
			<cfset minimum_elevation_m=">#minimum_elevation_m#"><!--- " --->
		</cfif>
	</cfif>
	<!--- convert min/max DepthOper variables to operators as leading characters of min/max depth --->
	<cfif isdefined("max_depth") AND len(max_depth) gt 0>
		<cfif isDefined("maxDepthOper") and maxDepthOper EQ "!" and left(max_depth,1) NEQ "!">
			<cfset max_depth="!#max_depth#">
		</cfif>
		<cfif isDefined("maxDepthOper") and maxDepthOper EQ "<>" and left(max_depth,2) NEQ "<>">
			<cfset max_depth="!#max_depth#"><!--- " --->
		</cfif>
		<cfif isDefined("maxDepthOper") and maxDepthOper EQ "<" and left(max_depth,1) NEQ "<">
			<cfset max_depth="<#max_depth#">
		</cfif>
		<cfif isDefined("maxDepthOper") and maxDepthOper EQ ">" and left(max_depth,1) NEQ ">">
			<cfset max_depth=">#max_depth#"><!--- " --->
		</cfif>
	</cfif>
	<cfif isdefined("min_depth") AND len(min_depth) gt 0>
		<cfif isDefined("minDepthOper") and minDepthOper EQ "!" and left(min_depth,1) NEQ "!">
			<cfset min_depth="!#min_depth#">
		</cfif>
		<cfif isDefined("minDepthOper") and minDepthOper EQ "<>" and left(min_depth,2) NEQ "<>">
			<cfset min_depth="!#min_depth#"><!--- " --->
		</cfif>
		<cfif isDefined("minDepthOper") and minDepthOper EQ "<" and left(min_depth,1) NEQ "<">
			<cfset min_depth="<#min_depth#">
		</cfif>
		<cfif isDefined("minDepthOper") and minDepthOper EQ ">" and left(min_depth,1) NEQ ">">
			<cfset min_depth=">#min_depth#"><!--- " --->
		</cfif>
	</cfif>
	<cfif isdefined("max_depth_m") AND len(max_depth_m) gt 0>
		<cfif isDefined("maxDepthOperM") and maxDepthOperM EQ "!" and left(max_depth_m,1) NEQ "!">
			<cfset max_depth_m="!#max_depth_m#">
		</cfif>
		<cfif isDefined("maxDepthOperM") and maxDepthOperM EQ "<>" and left(max_depth_m,2) NEQ "<>">
			<cfset max_depth_m="!#max_depth_m#"><!--- " --->
		</cfif>
		<cfif isDefined("maxDepthOperM") and maxDepthOperM EQ "<" and left(max_depth_m,1) NEQ "<">
			<cfset max_depth_m="<#max_depth_m#">
		</cfif>
		<cfif isDefined("maxDepthOperM") and maxDepthOperM EQ ">" and left(max_depth_m,1) NEQ ">">
			<cfset max_depth_m=">#max_depth_m#"><!--- " --->
		</cfif>
	</cfif>
	<cfif isdefined("min_depth_m") AND len(min_depth_m) gt 0>
		<cfif isDefined("MinDepthOperM") and minDepthOperM EQ "!" and left(min_depth_m,1) NEQ "!">
			<cfset min_depth_m="!#min_depth_m#">
		</cfif>
		<cfif isDefined("MinDepthOperM") and minDepthOperM EQ "<>" and left(min_depth_m,2) NEQ "<>">
			<cfset min_depth_m="!#min_depth_m#"><!--- " --->
		</cfif>
		<cfif isDefined("MinDepthOperM") and minDepthOperM EQ "<" and left(min_depth_m,1) NEQ "<">
			<cfset min_depth_m="<#min_depth_m#">
		</cfif>
		<cfif isDefined("MinDepthOperM") and minDepthOperM EQ ">" and left(min_depth_m,1) NEQ ">">
			<cfset min_depth_m=">#min_depth_m#"><!--- " --->
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
				to_meters(locality.minimum_elevation,locality.orig_elev_units) min_elevation_meters,
				to_meters(locality.maximum_elevation,locality.orig_elev_units) max_elevation_meters,
				locality.max_depth,
				locality.min_depth,
				locality.depth_units,
				to_meters(locality.min_depth,locality.depth_units) min_depth_meters,
				to_meters(locality.max_depth,locality.depth_units) max_depth_meters,
				locality.curated_fg,
				locality.sovereign_nation,
				locality.georef_updated_date,
				locality.georef_by,
				locality.nogeorefbecause,
				trim(upper(section_part) || ' ' || nvl2(section,'S','') || section ||  nvl2(township,' T',' ') || township || upper(township_direction) || nvl2(range,' R',' ') || range || upper(range_direction)) as plss,
				concatGeologyAttributeDetail(locality.locality_id) geolAtts,
				<cfif includeCounts >
					MCZBASE.get_collcodes_for_locality(locality.locality_id)  as collcountlocality,
				<cfelse>
					null as collcountlocality,
				</cfif>
  				accepted_lat_long.LAT_LONG_ID,
				accepted_lat_long.dec_lat,
				accepted_lat_long.dec_long,
				accepted_lat_long.datum,
				accepted_lat_long.max_error_distance,
				to_meters(accepted_lat_long.max_error_distance, accepted_lat_long.max_error_units) coordinateUncertaintyInMeters,
				accepted_lat_long.extent,
				accepted_lat_long.verificationstatus,
				accepted_lat_long.georefmethod,
				georef_verified_agent.agent_name georef_verified_by_agent,
				georef_determined_agent.agent_name georef_determined_by_agent,
				collecting_event.collecting_event_id,
				collecting_event.verbatim_locality,
				collecting_event.verbatimdepth,
				collecting_event.verbatimelevation,
				collecting_event.verbatim_date,
				collecting_event.began_date,
				collecting_event.ended_date,
				collecting_event.collecting_time,
				collecting_event.startdayofyear,
				collecting_event.enddayofyear,
				collecting_event.habitat_desc,
				collecting_event.collecting_source,
				collecting_event.collecting_method,
				collecting_event.valid_distribution_fg,
				collecting_event.habitat_desc,
				collecting_event.fish_field_number,
				collecting_event.verbatimcoordinates,
				collecting_event.verbatimlatitude,
				collecting_event.verbatimlongitude,
				collecting_event.verbatimcoordinatesystem,
				collecting_event.verbatimsrs,
				collecting_event.coll_event_remarks,
				count(flatTableName.collection_object_id) as specimen_count
			FROM 
				collecting_event
				join locality on collecting_event.locality_id = locality.locality_id
				join geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
				left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>flat<cfelse>filtered_flat</cfif> flatTableName on collecting_event.collecting_event_id=flatTableName.collecting_event_id
				left join accepted_lat_long on locality.locality_id = accepted_lat_long.locality_id
				<cfif (isdefined("geology_attribute") AND len(#geology_attribute#) gt 0) OR (isdefined("geo_att_value") AND len(#geo_att_value#) gt 0)>
					left join geology_attributes on locality.locality_id = geology_attributes.locality_id
				</cfif>
				left join preferred_agent_name georef_verified_agent on accepted_lat_long.verified_by_agent_id = georef_verified_agent.agent_id
				left join preferred_agent_name georef_determined_agent on accepted_lat_long.determined_by_agent_id = georef_determined_agent.agent_id
			WHERE
				locality.locality_id is not null
				<cfif isDefined("any_geography") and len(any_geography) gt 0>
					and locality.locality_id in (select locality_id from flat where contains(HIGHER_GEOG,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#any_geography#">,1) > 0)
				</cfif>
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
				<cfif isDefined("collecting_event_id") and len(collecting_event_id) gt 0>
						and locality.collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
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
					<cfset setup = setupClause(field="geog_auth_rec.continent_ocean",value="#continent_ocean#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("country") AND len(country) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.country",value="#country#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("state_prov") AND len(state_prov) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.state_prov",value="#state_prov#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("county") AND len(county) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.county",value="#county#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("quad") AND len(quad) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.quad",value="#quad#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("feature") AND len(feature) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.feature",value="#feature#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("island") AND len(island) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.island",value="#island#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("island_group") AND len(island_group) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.island_group",value="#island_group#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("ocean_region") AND len(ocean_region) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.ocean_region",value="#ocean_region#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("ocean_subregion") AND len(ocean_subregion) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.ocean_subregion",value="#ocean_subregion#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("sea") AND len(sea) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.sea",value="#sea#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("water_feature") AND len(water_feature) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.water_feature",value="#water_feature#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("source_authority") AND len(source_authority) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.source_authority",value="#source_authority#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("highergeographyid") AND len(highergeographyid) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.highergeographyid",value="#highergeographyid#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("highergeographyid_guid_type") AND len(highergeographyid_guid_type) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.highergeographyid_guid_type",value="#highergeographyid_guid_type#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
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
					<cfset setup = setupClause(field="locality.spec_locality",value="#spec_locality#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("locality_remarks") AND len(locality_remarks) gt 0>
					<cfset setup = setupClause(field="locality.locality_remarks",value="#locality_remarks#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("orig_elev_units") AND len(orig_elev_units) gt 0>
					<cfset setup = setupClause(field="locality.orig_elev_units",value="#orig_elev_units#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("minimum_elevation") AND len(minimum_elevation) gt 0>
					<cfset setup = setupNumericClause(field="locality.minimum_elevation",value="#minimum_elevation#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelseif setup["between"] EQ "true">
						AND #setup["pre"]# 
						BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" > 
						AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#"> 
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("minimum_elevation_m") and len(#minimum_elevation_m#) gt 0>
					<cfset setup = setupNumericClause(field="TO_METERS(locality.minimum_elevation,locality.orig_elev_units)",value="#minimum_elevation_m#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelseif setup["between"] EQ "true">
						AND #setup["pre"]# 
						BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" > 
						AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#"> 
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("maximum_elevation") AND len(maximum_elevation) gt 0>
					<cfset setup = setupNumericClause(field="locality.maximum_elevation",value="#maximum_elevation#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelseif setup["between"] EQ "true">
						AND #setup["pre"]# 
						BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" > 
						AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#"> 
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("maximum_elevation_m") and len(#maximum_elevation_m#) gt 0>
					<cfset setup = setupNumericClause(field="TO_METERS(locality.maximum_elevation,locality.orig_elev_units)",value="#maximum_elevation_m#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelseif setup["between"] EQ "true">
						AND #setup["pre"]# 
						BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" > 
						AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#"> 
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("depth_units") AND len(depth_units) gt 0>
					<cfset setup = setupClause(field="locality.depth_units",value="#depth_units#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("min_depth") AND len(min_depth) gt 0>
					<cfset setup = setupNumericClause(field="locality.min_depth",value="#min_depth#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelseif setup["between"] EQ "true">
						AND #setup["pre"]# 
						BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" > 
						AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#"> 
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("min_depth_m") and len(#min_depth_m#) gt 0>
					<cfset setup = setupNumericClause(field="TO_METERS(locality.min_depth,locality.depth_units)",value="#min_depth_m#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelseif setup["between"] EQ "true">
						AND #setup["pre"]# 
						BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" > 
						AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#"> 
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("max_depth") AND len(max_depth) gt 0>
					<cfset setup = setupNumericClause(field="locality.max_depth",value="#max_depth#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelseif setup["between"] EQ "true">
						AND #setup["pre"]# 
						BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" > 
						AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#"> 
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("max_depth_m") and len(#max_depth_m#) gt 0>
					<cfset setup = setupNumericClause(field="TO_METERS(locality.max_depth,locality.depth_units)",value="#max_depth_m#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelseif setup["between"] EQ "true">
						AND #setup["pre"]# 
						BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" > 
						AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#"> 
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("section") AND len(section) gt 0>
					<cfset setup = setupNumericClause(field="locality.section",value="#section#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelseif setup["between"] EQ "true">
						AND #setup["pre"]# 
						BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" > 
						AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#"> 
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("township") AND len(township) gt 0>
					<cfset setup = setupNumericClause(field="locality.township",value="#township#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelseif setup["between"] EQ "true">
						AND #setup["pre"]# 
						BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" > 
						AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#"> 
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("range") AND len(range) gt 0>
					<cfset setup = setupNumericClause(field="locality.range",value="#range#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelseif setup["between"] EQ "true">
						AND #setup["pre"]# 
						BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" > 
						AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#"> 
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("township_direction") AND len(township_direction) gt 0>
					<cfif ucase(township_direction) EQ "NULL">
						and locality.township_direction IS NULL
					<cfelseif ucase(township_direction) EQ "NOT NULL">
						and locality.township_direction IS NOT NULL	
					<cfelse>
						AND upper(locality.township_direction) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#township_direction#">
					</cfif>
				</cfif>
				<cfif isdefined("range_direction") AND len(range_direction) gt 0>
					<cfif ucase(range_direction) EQ "NULL">
						and locality.range_direction IS NULL
					<cfelseif ucase(range_direction) EQ "NOT NULL">
						and locality.range_direction IS NOT NULL	
					<cfelse>
						AND upper(locality.range_direction) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#range_direction#">
					</cfif>
				</cfif>
				<cfif isdefined("section_part") AND len(section_part) gt 0>
					<cfset setup = setupClause(field="locality.section_part",value="#section_part#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
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
				<cfif isdefined("geology_attribute") and len(#geology_attribute#) gt 0>
					AND geology_attributes.geology_attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geology_attribute#">
				</cfif>
				<cfif isdefined("geo_att_value") and len(#geo_att_value#) gt 0>
					<cfif isdefined("geology_attribute_hier") and #geology_attribute_hier# is 1>
						AND geology_attributes.geo_att_value
							IN ( SELECT attribute_value
								FROM geology_attribute_hierarchy
								START WITH upper(attribute_value) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(geo_att_value)#%">
								CONNECT BY PRIOR geology_attribute_hierarchy_id = parent_id )
					<cfelse>
						AND upper(geology_attributes.geo_att_value) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(geo_att_value)#%">
					</cfif>
				</cfif>
				<cfif isdefined("georef_updated_date") and len(georef_updated_date) gt 0>
					<cfif georef_updated_date is "NULL">
						AND georef_updated_date IS NULL
					<cfelseif georef_updated_date is "NOT NULL">
						AND georef_updated_date IS NOT NULL
					<cfelseif refind("^[0-9]{4}-[0-9]{2}-[0-9]{2}$",georef_update_date) EQ 1>
						AND georef_updated_date = <cfqueryparam cfsqltype="CF_SQL_DATE" value="#date_format(georef_updated_date,'yyyy-mm-dd')#">
					<cfelseif refind("^[0-9]{4}$",georef_update_date) EQ 1>
						<cfset startDate = "#georef_update_date#-01-01">
						<cfset endDate = "#georef_update_date#-12-31">
						AND georef_updated_date 
							between <cfqueryparam cfsqltype="CF_SQL_DATE" value="#date_format(startDate,'yyyy-mm-dd')#">
							and<cfqueryparam cfsqltype="CF_SQL_DATE" value="#date_format(endDate,'yyyy-mm-dd')#">
					<cfelseif refind("^[0-9]{4}-[0-9]{2}-[0-9]{2}/[0-9]{4}-[0-9]{2}-[0-9]{2}$",georef_update_date) EQ 1>
						<cfset bits = listToArray(georef_update_date,'/')>
						<cfset startDate = bits[1]>
						<cfset endDate = bits[2]>
						AND georef_updated_date 
							between <cfqueryparam cfsqltype="CF_SQL_DATE" value="#date_format(startDate,'yyyy-mm-dd')#">
							and<cfqueryparam cfsqltype="CF_SQL_DATE" value="#date_format(endDate,'yyyy-mm-dd')#">
					<cfelseif refind("^[0-9]{4}}/[0-9]{4}$",georef_update_date) EQ 1>
						<cfset bits = listToArray(georef_update_date,'/')>
						<cfset startDate = "#bits[1]#-01-01">
						<cfset endDate = "#bits[2]#-12-31">
						AND georef_updated_date 
							between <cfqueryparam cfsqltype="CF_SQL_DATE" value="#date_format(startDate,'yyyy-mm-dd')#">
							and<cfqueryparam cfsqltype="CF_SQL_DATE" value="#date_format(endDate,'yyyy-mm-dd')#">
					<cfelse>
						<cfthrow message = "unsupported date search format for georef_updated_date.  Use: yyyy-mm-dd, yyyy, yyyy/yyyy, yyyy-mm-dd/yyyy-mm-dd, NULL or NOT NULL.">
					</cfif>
				</cfif>
				<cfif isdefined("georef_by") AND len(georef_by) gt 0>
					<cfset setup = setupClause(field="locality.georef_by",value="#georef_by#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("NoGeorefBecause") AND len(#NoGeorefBecause#) gt 0>
					AND upper(NoGeorefBecause) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(NoGeorefBecause)#%">
				</cfif>
				<cfif isdefined("VerificationStatus") AND len(#VerificationStatus#) gt 0>
					AND VerificationStatus = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VerificationStatus#">
				</cfif>
				<cfif isdefined("GeorefMethod") AND len(#GeorefMethod#) gt 0>
					AND GeorefMethod = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#GeorefMethod#">
				</cfif>
				<cfif isdefined("nullNoGeorefBecause") and len(#nullNoGeorefBecause#) gt 0>
					AND NoGeorefBecause IS NULL
				</cfif>
				<cfif isdefined("isIncomplete") AND len(#isIncomplete#) gt 0>
					AND ( (GPSACCURACY IS NULL AND EXTENT IS NULL) OR MAX_ERROR_DISTANCE = 0 or MAX_ERROR_DISTANCE IS NULL or datum IS NULL or coordinate_precision IS NULL )
				</cfif>
				<cfif isdefined("findNoAccGeoRef") and len(#findNoAccGeoRef#) gt 0>
					AND locality.locality_id IN (select locality_id from lat_long)
					AND locality.locality_id NOT IN (select locality_id from lat_long where accepted_lat_long_fg=1)
				</cfif>
				<cfif isdefined("findNoAccGeoRefStrict") and len(#findNoAccGeoRefStrict#) gt 0>
					AND locality.locality_id NOT IN (select locality_id from lat_long where accepted_lat_long_fg=1)
				</cfif>
				<cfif isdefined("findNoGeoRef") and len(#findNoGeoRef#) gt 0>
					AND locality.locality_id NOT IN (select locality_id from lat_long)
				</cfif>
				<cfif isdefined("findHasGeoRef") and len(#findHasGeoRef#) gt 0>
					AND locality.locality_id IN (select locality_id from lat_long)
				</cfif>
				<cfif isdefined("onlyShared") and len(#onlyShared#) gt 0>
					AND locality.locality_id in (select locality_id from FLAT group by locality_id having count(distinct collection_cde) > 1)
				</cfif>
				<cfif isdefined("dec_lat") and len(#dec_lat#) gt 0>
					<cfset setup = setupNumericClause(field="accepted_lat_long.dec_lat",value="#dec_lat#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelseif setup["between"] EQ "true">
						AND #setup["pre"]# 
						BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" > 
						AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#"> 
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("dec_long") and len(#dec_long#) gt 0>
					<cfset setup = setupNumericClause(field="accepted_lat_long.dec_long",value="#dec_long#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelseif setup["between"] EQ "true">
						AND #setup["pre"]# 
						BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" > 
						AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#"> 
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("datum") AND len(datum) gt 0>
					<cfset setup = setupClause(field="accepted_lat_long.datum",value="#datum#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("max_error_distance") and len(#max_error_distance#) gt 0>
					<cfset setup = setupNumericClause(field="accepted_lat_long.max_error_distance",value="#max_error_distance#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelseif setup["between"] EQ "true">
						AND #setup["pre"]# 
						BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" > 
						AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#"> 
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("georeference_verified_by_id") and len(#georeference_verified_by_id#) gt 0>
					and georef_verified_agent.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#georeference_verified_by_id#">
				<cfelseif isdefined("georeference_verified_by") and len(#georeference_verified_by#) gt 0>
					<cfset setup = setupClause(field="georef_verified_agent.agent_name",value="#georeference_verified_by#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("georeference_determined_by_id") and len(#georeference_determined_by_id#) gt 0>
					AND georef_determined_agent.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#georeference_determined_by_id#">
				<cfelseif isdefined("coordinateDeterminer") and len(#coordinateDeterminer#) gt 0>
					<cfset setup = setupClause(field="georef_determined_agent.agent_name",value="#coordinateDeterminer#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("geolocate_precision") and len(#geolocate_precision#) gt 0>
					AND lower(accepted_lat_long.geolocate_precision) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geolocate_precision#">
				</cfif>
				<cfif isdefined("geolocate_score") and len(#geolocate_score#) gt 0>
					<cfif ArrayLen(REMatch("^[0-9]+\-[0-9]+$",geolocate_score))>0 >
						<!--- new operator parser on single geolocate_score --->
						<cfset bits = ListToArray(geolocate_score,"-")>
						AND accepted_lat_long.geolocate_score
							BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bits[1]#">
							AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bits[2]#">
					<cfelseif geolocate_score EQ 'NULL'>
						AND accepted_lat_long.geolocate_score IS NULL
					<cfelseif geolocate_score EQ 'NOT NULL'>
						AND accepted_lat_long.geolocate_score IS NOT NULL
					<cfelse>
						<!--- old form fields --->
						<cfswitch expression="#gs_comparator#">
							<cfcase value = "between">
								AND accepted_lat_long.geolocate_score
									BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geolocate_score#">
									AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geolocate_score2#">
							</cfcase>
							<cfcase value = ">"><!--- " --->
								AND accepted_lat_long.geolocate_score > <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geolocate_score#">
							</cfcase>
							<cfcase value = "<">
								AND accepted_lat_long.geolocate_score < <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geolocate_score#">
							</cfcase>
							<cfcase value = "<>"><!--- " --->
								AND accepted_lat_long.geolocate_score <> <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geolocate_score#">
							</cfcase>
							<cfdefaultcase>
								AND accepted_lat_long.geolocate_score = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geolocate_score#">
							</cfdefaultcase>
						</cfswitch>
					</cfif>
				</cfif>
				<cfif isdefined("verbatim_locality") and len(#verbatim_locality#) gt 0>
					<cfset setup = setupClause(field="collecting_event.verbatim_locality",value="#verbatim_locality#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("verbatim_date") and len(#verbatim_date#) gt 0>
					<cfset setup = setupClause(field="collecting_event.verbatim_date",value="#verbatim_date#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("verbatimdepth") and len(#verbatimdepth#) gt 0>
					<cfset setup = setupClause(field="collecting_event.verbatimdepth",value="#verbatimdepth#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("verbatimelevation") and len(#verbatimelevation#) gt 0>
					<cfset setup = setupClause(field="collecting_event.verbatimelevation",value="#verbatimelevation#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("verbatimCoordinates") AND len(verbatimCoordinates) gt 0>
					<cfset setup = setupClause(field="collecting_event.verbatimCoordinates",value="#verbatimCoordinates#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("habitat_desc") AND len(habitat_desc) gt 0>
					<cfset setup = setupClause(field="collecting_event.habitat_desc",value="#habitat_desc#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("collecting_source") AND len(collecting_source) gt 0>
					<cfset setup = setupClause(field="collecting_event.collecting_source",value="#collecting_source#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("collecting_method") AND len(collecting_method) gt 0>
					<cfset setup = setupClause(field="collecting_event.collecting_method",value="#collecting_method#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("coll_event_remarks") AND len(coll_event_remarks) gt 0>
					<cfset setup = setupClause(field="collecting_event.coll_event_remarks",value="#coll_event_remarks#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("began_date") and len(#began_date#) gt 0>
					<cfswitch expression="#begDateOper#">
						<cfcase value = ">"><!--- " --->
							AND began_date > <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#began_date#">
						</cfcase>
						<cfcase value = "<"><!--- " --->
							AND began_date < <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#began_date#">
						</cfcase>
						<cfdefaultcase>
							AND began_date = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#began_date#">
						</cfdefaultcase>
					</cfswitch>
				</cfif>
				<cfif isdefined("ended_date") and len(#ended_date#) gt 0>
					<cfswitch expression="#endDateOper#">
						<cfcase value = ">"><!--- " --->
							AND ended_date > <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ended_date#">
						</cfcase>
						<cfcase value = "<"><!--- " --->
							AND ended_date < <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ended_date#">
						</cfcase>
						<cfdefaultcase>
							AND ended_date = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ended_date#">
						</cfdefaultcase>
					</cfswitch>
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
				locality.max_depth,
				locality.min_depth,
				locality.depth_units,
				locality.curated_fg,
				locality.sovereign_nation,
				locality.nogeorefbecause,
				locality.georef_updated_date,
				locality.georef_by,
				locality.township, locality.township_direction, locality.range, locality.range_direction,
				locality.section, locality.section_part,
  				accepted_lat_long.LAT_LONG_ID,
				accepted_lat_long.dec_lat,
				accepted_lat_long.dec_long,
				accepted_lat_long.datum,
				accepted_lat_long.max_error_distance,
				accepted_lat_long.max_error_units,
				accepted_lat_long.extent,
				accepted_lat_long.verificationstatus,
				accepted_lat_long.georefmethod,
				georef_verified_agent.agent_name,
				georef_determined_agent.agent_name,
				collecting_event.collecting_event_id,
				collecting_event.verbatim_locality,
				collecting_event.verbatimdepth,
				collecting_event.verbatimelevation,
				collecting_event.verbatim_date,
				collecting_event.began_date,
				collecting_event.ended_date,
				collecting_event.collecting_time,
				collecting_event.startdayofyear,
				collecting_event.enddayofyear,
				collecting_event.habitat_desc,
				collecting_event.collecting_source,
				collecting_event.collecting_method,
				collecting_event.valid_distribution_fg,
				collecting_event.habitat_desc,
				collecting_event.fish_field_number,
				collecting_event.verbatimcoordinates,
				collecting_event.verbatimlatitude,
				collecting_event.verbatimlongitude,
				collecting_event.verbatimcoordinatesystem,
				collecting_event.verbatimsrs,
				collecting_event.coll_event_remarks,
				concatGeologyAttributeDetail(locality.locality_id)
			ORDER BY
				geog_auth_rec.higher_geog,
				locality.spec_locality,
				locality.locality_id
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
