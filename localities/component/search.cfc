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
	<cfelseif left(value,2) is "!%">
		<cfset pre="upper(#field#) NOT LIKE ">
		<cfset outvalue="%#ucase(value)#%">
		<cfset post ="">
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
	<cfelseif REFind('^-{0,1}[0-9.]+-{1,2}[0-9.]+$',value) GT 0>
		<cfset bits = listToArray(value,'-')>
		<cfif arrayLen(bits) GT 1>
			<cfif REFind('^[0-9.]+-[0-9.]+$',value) GT 0>
				<cfset pre = "#field# ">
				<cfset between="true">
				<cfset outvalue="#bits[1]#">
				<cfset outvalue2="#bits[2]#">
			<cfelseif REFind('^[0-9.]+--[0-9.]+$',value) GT 0>
				<cfset pre = "#field# ">
				<cfset between="true">
				<cfset outvalue="#bits[1]#">
				<cfset outvalue2="-#bits[2]#">
			<cfelseif REFind('^-[0-9.]+-[0-9.]+$',value) GT 0>
				<cfset pre = "#field# ">
				<cfset between="true">
				<cfset outvalue="-#bits[1]#">
				<cfset outvalue2="#bits[2]#">
			<cfelseif REFind('^-[0-9.]+--[0-9.]+$',value) GT 0>
				<cfset pre = "#field# ">
				<cfset between="true">
				<cfset outvalue="-#bits[1]#">
				<cfset outvalue2="-#bits[2]#">
			<cfelse>
				<cfset pre = "#field# = ">
				<cfset outvalue="#bits[1]#">
			</cfif>
			<cfif len(outvalue) GT 0 and len(outvalue2) GT 0 and val(outvalue) GT val(outvalue2)>
				<!--- switch order for range search to low to high --->
				<cfset temp=outvalue2>
				<cfset outvalue2=outvalue>
				<cfset outvalue=temp>
			</cfif> 
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
Function getSovereignNationAutocomplete.  Search for sovereign_nation by name with a substring match on name, returning json suitable for jquery-ui autocomplete.

@param term sovereign_nation to search for.
@return a json structure containing id and value, with matching with matched sovereign_nation in value and id.
--->
<cffunction name="getSovereignNationAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<!--- perform wildcard search anywhere in ctsovereign_nation.sovereign_nation --->
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result">
			SELECT 
				sovereign_nation
			FROM 
				ctsovereign_nation
			WHERE
				upper(sovereign_nation) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
			ORDER BY
				sovereign_nation
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.sovereign_nation#">
			<cfset row["value"] = "#search.sovereign_nation#" >
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
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result">
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
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result">
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
Function getHigherGeogAutocomplete.  Search for higher geographies by higher_geog with a substring match, returning json suitable for jquery-ui autocomplete.

@param term higher geography to search for.
@return a json structure containing id and value, with matching higher_geog in value and geog_auth_rec_id in id.
--->
<cffunction name="getHigherGeogAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<!--- perform wildcard search anywhere in geog_auth_rec.higher_geog --->
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result">
			SELECT 
				geog_auth_rec_id, higher_geog
			FROM 
				geog_auth_rec
			WHERE
				upper(higher_geog) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
			ORDER BY
				higher_geog
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.geog_auth_rec_id#">
			<cfset row["value"] = "#search.higher_geog#" >
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
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result">
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
	<cfargument name="show_unused" type="string" required="no">
	<cfargument name="curated_fg" type="string" required="no">

	<cfif NOT isDefined("return_wkt")><cfset return_wkt=""></cfif>
	<cfset linguisticFlag = false>
	<cfif isdefined("accentInsensitive") AND accentInsensitive EQ 1>
		<cfset linguisticFlag=true>
	</cfif>
	<cfif isDefined("geog_auth_rec_id") AND len(geog_auth_rec_id) GT 0>
		<!--- strip extraneous characters out of geog_auth_rec_id (ignores = operator) --->
		<cfset geog_auth_rec_id = rereplace(geog_auth_rec_id,"[^0-9,]","","all")>
	</cfif>

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfif linguisticFlag >
			<!--- Set up the session to run an accent insensitive search --->
			<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				ALTER SESSION SET NLS_COMP = LINGUISTIC
			</cfquery>
			<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				ALTER SESSION SET NLS_SORT = GENERIC_M_AI
			</cfquery>
		</cfif>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result">
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
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_geography")>
					geog_auth_rec.curated_fg,
				</cfif>
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
				<cfif isDefined("show_unused") and show_unused EQ "unused_only">
					AND geog_auth_rec.geog_auth_rec_id not in (select geog_auth_rec_id from flat)
				</cfif>
				<cfif isDefined("geog_auth_rec_id") and len(geog_auth_rec_id) gt 0>
						and geog_auth_rec.geog_auth_rec_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#" list="yes">)
				<cfelse>
					<cfif isDefined("higher_geog") and len(higher_geog) gt 0>
						<cfif left(higher_geog,1) is "=">
							AND upper(geog_auth_rec.higher_geog) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(higher_geog,len(higher_geog)-1))#">
						<cfelse>
							and upper(geog_auth_rec.higher_geog) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(higher_geog)#%">
						</cfif>
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
				<cfif isdefined("curated_fg") AND len(curated_fg) gt 0 AND isdefined("session.roles") AND listfindnocase(session.roles,"manage_geography")>
					<cfif curated_fg EQ "1">
						and geog_auth_rec.curated_fg = 1
					<cfelseif curated_fg EQ "0">
						and geog_auth_rec.curated_fg = 0
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
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_geography")>
					 geog_auth_rec.curated_fg,
				</cfif>
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
			<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
	<cfargument name="show_unused" type="string" required="no">
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
	<cfif isDefined("geog_auth_rec_id") AND len(geog_auth_rec_id) GT 0>
		<!--- strip extraneous characters out of geog_auth_rec_id (ignores = operator) --->
		<cfset geog_auth_rec_id = rereplace(geog_auth_rec_id,"[^0-9,]","","all")>
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
			<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				ALTER SESSION SET NLS_COMP = LINGUISTIC
			</cfquery>
			<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				ALTER SESSION SET NLS_SORT = GENERIC_M_AI
			</cfquery>
		</cfif>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result">
			SELECT distinct
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
				listagg(geology_attributes.geology_attribute || nvl2(geology_attributes.geology_attribute, ':', '') || geo_att_value,'; ') within group (order by geo_att_value) over (partition by locality.locality_id) geolAtts,
				<cfif includeCounts >
					MCZBASE.get_collcodes_for_locality(locality.locality_id)  as collcountlocality,
				<cfelse>
					null as collcountlocality,
				</cfif>
  				accepted_lat_long.LAT_LONG_ID,
				to_char(accepted_lat_long.dec_lat, '99' || rpad('.',nvl(accepted_lat_long.coordinate_precision,5) + 1, '0')) dec_lat,
				to_char(accepted_lat_long.dec_long, '999' || rpad('.',nvl(accepted_lat_long.coordinate_precision,5) + 1, '0')) dec_long,
				accepted_lat_long.datum,
				accepted_lat_long.max_error_distance,
				accepted_lat_long.max_error_units,
				to_meters(accepted_lat_long.max_error_distance, accepted_lat_long.max_error_units) coordinateUncertaintyInMeters,
				accepted_lat_long.extent,
				accepted_lat_long.verificationstatus,
				accepted_lat_long.georefmethod,
				georef_verified_agent.agent_name georef_verified_by_agent,
				georef_determined_agent.agent_name georef_determined_by_agent,
				count(flatTableName.collection_object_id) as specimen_count,
				count(distinct flatTableName.collecting_event_id) as collecting_event_count
			FROM 
				locality
				join geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
				left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>flat<cfelse>filtered_flat</cfif> flatTableName on locality.locality_id=flatTableName.locality_id
				left join accepted_lat_long on locality.locality_id = accepted_lat_long.locality_id
				left join preferred_agent_name georef_verified_agent on accepted_lat_long.verified_by_agent_id = georef_verified_agent.agent_id
				left join preferred_agent_name georef_determined_agent on accepted_lat_long.determined_by_agent_id = georef_determined_agent.agent_id
				left join geology_attributes on locality.locality_id = geology_attributes.locality_id 
				left join ctgeology_attributes on geology_attributes.geology_attribute = ctgeology_attributes.geology_attribute
			WHERE
				locality.locality_id is not null
				<cfif isDefined("show_unused") and show_unused EQ "unused_only">
					AND locality.locality_id not in (select locality_id from flat)
				</cfif>
				<cfif isDefined("any_geography") and len(any_geography) gt 0>
					and locality.locality_id in (select locality_id from flat where contains(HIGHER_GEOG,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#any_geography#">,1) > 0)
				</cfif>
				<cfif isDefined("geog_auth_rec_id") and len(geog_auth_rec_id) gt 0>
						and geog_auth_rec.geog_auth_rec_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#" list="yes">)
				<cfelse>
					<cfif isDefined("higher_geog") and len(higher_geog) gt 0>
						<cfif left(higher_geog,1) is "=">
							AND upper(geog_auth_rec.higher_geog) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(higher_geog,len(higher_geog)-1))#">
						<cfelse>
							and upper(geog_auth_rec.higher_geog) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(higher_geog)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isDefined("locality_id") and len(locality_id) gt 0>
					<cfif Find(",",locality_id) GT 0>
						and locality.locality_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#" list="yes">)
					<cfelse>
						and locality.locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
					</cfif>
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
					AND accepted_lat_long.verificationstatus = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#verificationstatus#">
				</cfif>
				<cfif isdefined("georefmethod") AND len(#georefmethod#) gt 0>
					AND accepted_lat_long.georefmethod = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#georefmethod#">
				</cfif>
				<cfif isdefined("nullNoGeorefBecause") and len(#nullNoGeorefBecause#) gt 0>
					AND NoGeorefBecause IS NULL
				</cfif>
				<cfif isdefined("isIncomplete") AND len(#isIncomplete#) gt 0>
					AND ( (accepted_lat_long.GPSACCURACY IS NULL AND accepted_lat_long.EXTENT IS NULL) 
							OR accepted_lat_long.MAX_ERROR_DISTANCE = 0 
							OR accepted_lat_long.MAX_ERROR_DISTANCE IS NULL 
							OR accepted_lat_long.datum IS NULL 
							OR accepted_lat_long.coordinate_precision IS NULL 
					)
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
				   <cfif left(dec_lat,1) is "=">
						AND to_char(accepted_lat_long.dec_lat,'TM') = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(dec_lat,len(dec_lat)-1)#">
					<cfelse>
						<cfset setup = setupNumericClause(field="accepted_lat_long.dec_lat",value="#dec_lat#")>
						<cfif len(setup["value"]) EQ 0>
							AND #setup["pre"]# #setup["post"]#
						<cfelseif setup["between"] EQ "true">
							AND #setup["pre"]# 
							BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" scale="10" > 
							AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#" scale="10"> 
						<cfelse>
							AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#" scale="10"> #setup["post"]#
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("dec_long") and len(#dec_long#) gt 0>
				   <cfif left(dec_long,1) is "=">
						AND to_char(accepted_lat_long.dec_long,'TM') = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(dec_long,len(dec_long)-1)#">
					<cfelse>
						<cfset setup = setupNumericClause(field="accepted_lat_long.dec_long",value="#dec_long#")>
						<cfif len(setup["value"]) EQ 0>
							AND #setup["pre"]# #setup["post"]#
						<cfelseif setup["between"] EQ "true">
							AND #setup["pre"]# 
							BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" scale="10" > 
							AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#" scale="10"> 
						<cfelse>
							AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#" scale="10"> #setup["post"]#
						</cfif>
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
				to_char(accepted_lat_long.dec_lat, '99' || rpad('.',nvl(accepted_lat_long.coordinate_precision,5) + 1, '0')),
				to_char(accepted_lat_long.dec_long, '999' || rpad('.',nvl(accepted_lat_long.coordinate_precision,5) + 1, '0')),
				accepted_lat_long.datum,
				accepted_lat_long.max_error_distance,
				accepted_lat_long.max_error_units,
				accepted_lat_long.extent,
				accepted_lat_long.verificationstatus,
				accepted_lat_long.georefmethod,
				georef_verified_agent.agent_name,
				georef_determined_agent.agent_name,
				geo_att_value, geology_attributes.geology_attribute
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
			<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
   @deprecated use getCollectingEvents_queryExecute instead.
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
	<cfargument name="collnEvOper" type="string" required="no">
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
	<cfargument name="verbatimsrs" type="string" required="no">
	<cfargument name="verbatimcoordinatesystem" type="string" required="no">
	<cfargument name="verbatimlatitude" type="string" required="no">
	<cfargument name="verbatimlongitude" type="string" required="no">
	<cfargument name="startdayofyear" type="string" required="no">
	<cfargument name="enddayofyear" type="string" required="no">
	<cfargument name="collectingtime" type="string" required="no">
	<cfargument name="fish_field_number" type="string" required="no">
	<cfargument name="verbatim_collectors" type="string" required="no">
	<cfargument name="verbatim_field_numbers" type="string" required="no"><!--- unused, function becomes too long --->
	<cfargument name="verbatim_habitat" type="string" required="no"><!--- unused, function becomes too long --->
	<cfargument name="date_determined_by_agent_id" type="string" required="no">
	<cfargument name="date_determined_by_agent" type="string" required="no">
	<cfargument name="valid_distribution_fg" type="string" required="no">
	<cfargument name="show_unused" type="string" required="no">

	<!--- NOTE: Fields just about at limit, adding more invocations of setupClause to query will result in "Branch target offset too large for short " error. --->

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
	<cfif isDefined("geog_auth_rec_id") AND len(geog_auth_rec_id) GT 0>
		<!--- strip extraneous characters out of geog_auth_rec_id (ignores = operator) --->
		<cfset geog_auth_rec_id = rereplace(geog_auth_rec_id,"[^0-9,]","","all")>
	</cfif>
	<cfif NOT isDefined("collnEvOper")><cfset collnEvOper=""></cfif>

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
			<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				ALTER SESSION SET NLS_COMP = LINGUISTIC
			</cfquery>
			<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				ALTER SESSION SET NLS_SORT = GENERIC_M_AI
			</cfquery>
		</cfif>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result">
			SELECT distinct
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
				listagg(geology_attributes.geology_attribute || nvl2(geology_attributes.geology_attribute, ':', '') || geo_att_value,'; ') within group (order by geo_att_value) over (partition by collecting_event.collecting_event_id) geolAtts,
				<cfif includeCounts >
					MCZBASE.get_collcodes_for_locality(locality.locality_id)  as collcountlocality,
				<cfelse>
					null as collcountlocality,
				</cfif>
  				accepted_lat_long.LAT_LONG_ID,
				to_char(accepted_lat_long.dec_lat, '99' || rpad('.',nvl(accepted_lat_long.coordinate_precision,5) + 1, '0')) dec_lat,
				to_char(accepted_lat_long.dec_long, '999' || rpad('.',nvl(accepted_lat_long.coordinate_precision,5) + 1, '0')) dec_long,
				accepted_lat_long.datum,
				accepted_lat_long.max_error_distance,
				accepted_lat_long.max_error_units,
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
				collecting_event.verbatim_collectors,
				collecting_event.verbatim_field_numbers,
				collecting_event.verbatim_habitat,
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
				left join preferred_agent_name georef_verified_agent on accepted_lat_long.verified_by_agent_id = georef_verified_agent.agent_id
				left join preferred_agent_name georef_determined_agent on accepted_lat_long.determined_by_agent_id = georef_determined_agent.agent_id
				left join preferred_agent_name date_determined_agent on collecting_event.date_determined_by_agent_id = date_determined_agent.agent_id
				left join geology_attributes on locality.locality_id = geology_attributes.locality_id 
				left join ctgeology_attributes on geology_attributes.geology_attribute = ctgeology_attributes.geology_attribute
			WHERE
				collecting_event.collecting_event_id is not null
				<cfif isDefined("show_unused") AND show_unused EQ "unused_only">
					AND collecting_event.collecting_event_id not in (select collecting_event_id from flat)
				</cfif>
				<cfif isDefined("any_geography") and len(any_geography) gt 0>
					and locality.locality_id in (select locality_id from flat where contains(HIGHER_GEOG,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#any_geography#">,1) > 0)
				</cfif>
				<cfif isDefined("geog_auth_rec_id") and len(geog_auth_rec_id) gt 0>
						and geog_auth_rec.geog_auth_rec_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#" list="yes">)
				<cfelse>
					<cfif isDefined("higher_geog") and len(higher_geog) gt 0>
						<cfif left(higher_geog,1) is "=">
							AND upper(geog_auth_rec.higher_geog) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(higher_geog,len(higher_geog)-1))#">
						<cfelse>
							and upper(geog_auth_rec.higher_geog) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(higher_geog)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isDefined("locality_id") and len(locality_id) gt 0>
					<cfif Find(",",locality_id) GT 0>
						and locality.locality_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#" list="yes">)
					<cfelse>
						and locality.locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
					</cfif>
				</cfif>
				<cfif isDefined("collecting_event_id") and len(collecting_event_id) gt 0>
					<cfif Find(",",collecting_event_id) GT 0>
						and collecting_event.collecting_event_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#" list="yes">)
					<cfelse>
						and collecting_event.collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
					</cfif>
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
					<cfelseif collnOper is "eventUsedOnlyBy"><!--- event..By terms from old API --->
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
					<!--- collnEvOper from new API for event...By terms --->
					<cfif collnEvOper IS "eventUsedOnlyBy">
						AND collecting_event.collecting_event_id in
								(select collecting_event_id from cataloged_item where collection_id =  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#"> )
						AND collecting_event.collecting_event_id not in
								(select collecting_event_id from cataloged_item where collection_id <>  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#"> and collection_id <> 0 )
					<cfelseif collnEvOper IS "eventUsedBy">
						AND collecting_event.collecting_event_id in
								(select collecting_event_id from cataloged_item where collection_id =  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#"> )
					<cfelseif collnEvOper IS "eventSharedOnlyBy">
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
					AND accepted_lat_long.verificationstatus = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VerificationStatus#">
				</cfif>
				<cfif isdefined("georefmethod") AND len(#georefmethod#) gt 0>
					AND accepted_lat_long.georefmethod = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#georefmethod#">
				</cfif>
				<cfif isdefined("nullNoGeorefBecause") and len(#nullNoGeorefBecause#) gt 0>
					AND NoGeorefBecause IS NULL
				</cfif>
				<cfif isdefined("isIncomplete") AND len(#isIncomplete#) gt 0>
					AND ( (accepted_lat_long.GPSACCURACY IS NULL AND accepted_lat_long.EXTENT IS NULL) 
							OR accepted_lat_long.MAX_ERROR_DISTANCE = 0 
							OR accepted_lat_long.MAX_ERROR_DISTANCE IS NULL 
							OR accepted_lat_long.datum IS NULL 
							OR accepted_lat_long.coordinate_precision IS NULL 
					)
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
				   <cfif left(dec_lat,1) is "=">
						AND to_char(accepted_lat_long.dec_lat,'TM') = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(dec_lat,len(dec_lat)-1)#">
					<cfelse>
						<cfset setup = setupNumericClause(field="accepted_lat_long.dec_lat",value="#dec_lat#")>
						<cfif len(setup["value"]) EQ 0>
							AND #setup["pre"]# #setup["post"]#
						<cfelseif setup["between"] EQ "true">
							AND #setup["pre"]# 
							BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" scale="10" > 
							AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#" scale="10"> 
						<cfelse>
							AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#" scale="10"> #setup["post"]#
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("dec_long") and len(#dec_long#) gt 0>
				   <cfif left(dec_long,1) is "=">
						AND to_char(accepted_lat_long.dec_long,'TM') = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(dec_long,len(dec_long)-1)#">
					<cfelse>
						<cfset setup = setupNumericClause(field="accepted_lat_long.dec_long",value="#dec_long#")>
						<cfif len(setup["value"]) EQ 0>
							AND #setup["pre"]# #setup["post"]#
						<cfelseif setup["between"] EQ "true">
							AND #setup["pre"]# 
							BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" scale="10" > 
							AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value2']#" scale="10"> 
						<cfelse>
							AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#setup['value']#" list="#setup['list']#" scale="10"> #setup["post"]#
						</cfif>
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
							AND collecting_event.began_date > <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#began_date#">
						</cfcase>
						<cfcase value = "<"><!--- " --->
							AND collecting_event.began_date < <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#began_date#">
						</cfcase>
						<cfdefaultcase>
							AND collecting_event.began_date = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#began_date#">
						</cfdefaultcase>
					</cfswitch>
				</cfif>
				<cfif isdefined("ended_date") and len(#ended_date#) gt 0>
					<cfswitch expression="#endDateOper#">
						<cfcase value = ">"><!--- " --->
							AND collecting_event.ended_date > <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ended_date#">
						</cfcase>
						<cfcase value = "<"><!--- " --->
							AND collecting_event.ended_date < <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ended_date#">
						</cfcase>
						<cfdefaultcase>
							AND collecting_event.ended_date = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ended_date#">
						</cfdefaultcase>
					</cfswitch>
				</cfif>
				<cfif isdefined("startdayofyear") and len(#startdayofyear#) gt 0>
					<cfset setup = setupNumericClause(field="collecting_event.startdayofyear",value="#startdayofyear#")>
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
				<cfif isdefined("enddayofyear") and len(#enddayofyear#) gt 0>
					<cfset setup = setupNumericClause(field="collecting_event.enddayofyear",value="#enddayofyear#")>
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
				<cfif isdefined("fish_field_number") AND len(fish_field_number) gt 0>
					<cfset setup = setupClause(field="collecting_event.fish_field_number",value="#fish_field_number#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("verbatim_collectors") AND len(verbatim_collectors) gt 0>
					<cfset setup = setupClause(field="collecting_event.verbatim_collectors",value="#verbatim_collectors#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("collecting_time") AND len(collecting_time) gt 0>
					<cfset setup = setupClause(field="collecting_event.collecting_time",value="#collecting_time#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("verbatimsrs") AND len(verbatimsrs) gt 0>
					<cfset setup = setupClause(field="collecting_event.verbatimsrs",value="#verbatimsrs#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("verbatimcoordinatesystem") AND len(verbatimcoordinatesystem) gt 0>
					<cfset setup = setupClause(field="collecting_event.verbatimcoordinatesystem",value="#verbatimcoordinatesystem#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("date_determined_by_agent_id") and len(#date_determined_by_agent_id#) gt 0>
					and georef_verified_agent.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#date_determined_by_agent_id#">
				<cfelseif isdefined("date_determined_by_agent") and len(#date_determined_by_agent#) gt 0>
					<cfset setup = setupClause(field="date_determined_agent.agent_name",value="#date_determined_by_agent#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("verbatimlatitude") AND len(verbatimlatitude) gt 0>
					<cfset setup = setupClause(field="collecting_event.verbatimlatitude",value="#verbatimlatitude#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("verbatimlongitude") AND len(verbatimlongitude) gt 0>
					<cfset setup = setupClause(field="collecting_event.verbatimlongitude",value="#verbatimlongitude#")>
					<cfif len(setup["value"]) EQ 0>
						AND #setup["pre"]# #setup["post"]#
					<cfelse>
						AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("collector_agent_id") and len(#collector_agent_id#) gt 0>
					AND collecting_event.collecting_event_id IN (
						SELECT flatTableName.collecting_event_id 
						FROM
							collector 
							LEFT JOIN <cfif ucase(#session.flatTableName#) EQ 'FLAT'>flat<cfelse>filtered_flat</cfif> flatTableName 
								ON collector.collection_object_id=flatTableName.collection_object_id
						WHERE
							collector_role = 'c'
							AND collector.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collector_agent_id#">
					)
				<cfelseif isdefined("collector_agent") and len(#collector_agent#) gt 0>
					<cfset setup = setupClause(field="agent_name.agent_name",value="#collector_agent#")>
					AND collecting_event.collecting_event_id IN (
						SELECT flatTableName.collecting_event_id 
						FROM
							collector 
							LEFT JOIN <cfif ucase(#session.flatTableName#) EQ 'FLAT'>flat<cfelse>filtered_flat</cfif> flatTableName 
								ON collector.collection_object_id=flatTableName.collection_object_id
							LEFT JOIN agent_name on collector.agent_id = agent_name.agent_id
						WHERE
							collector_role = 'c'
							<cfif len(setup["value"]) EQ 0>
								AND #setup["pre"]# #setup["post"]#
							<cfelse>
								AND #setup["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#setup['value']#" list="#setup['list']#"> #setup["post"]#
							</cfif>
					)
				</cfif>
				<cfif isdefined("valid_distribution_fg") AND len(valid_distribution_fg) gt 0>
					<cfif valid_distribution_fg EQ 'NULL'>
						AND valid_distribution_fg IS NULL
					<cfelseif valid_distribution_fg EQ 'NOT NULL'>
						AND valid_distribution_fg IS NOT NULL
					<cfelse>
						AND valid_distribution_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#valid_distribution_fg#">
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
				to_char(accepted_lat_long.dec_lat, '99' || rpad('.',nvl(accepted_lat_long.coordinate_precision,5) + 1, '0')),
				to_char(accepted_lat_long.dec_long, '999' || rpad('.',nvl(accepted_lat_long.coordinate_precision,5) + 1, '0')),
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
				collecting_event.verbatim_collectors,
				collecting_event.verbatim_field_numbers,
				collecting_event.verbatim_habitat,
				collecting_event.verbatimcoordinates,
				collecting_event.verbatimlatitude,
				collecting_event.verbatimlongitude,
				collecting_event.verbatimcoordinatesystem,
				collecting_event.verbatimsrs,
				collecting_event.coll_event_remarks,
				geo_att_value, geology_attributes.geology_attribute
			ORDER BY
				geog_auth_rec.higher_geog,
				locality.spec_locality,
				locality.locality_id,
				collecting_event.began_date,
				collecting_event.ended_date
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
			<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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


<!--- Function addNamedQueryParam to add a named typed parameter to a queryExecute parameter struct.

@param params struct of named query parameters to append to.
@param paramBase trusted internal base name for generating a unique parameter name.
	Must be code-defined (never user-provided) and match [A-Za-z_][A-Za-z0-9_]*.
@param value parameter value to bind.
@param cfsqltype SQL type to use for binding.
@param list true to bind value as a list parameter.
@param scale optional numeric scale for decimal bindings.
@return generated named parameter token (e.g. :param_name_1) for use in SQL text.
--->
<cffunction name="addNamedQueryParam" access="private" returntype="string">
	<cfargument name="params" type="struct" required="yes">
	<cfargument name="paramBase" type="string" required="yes">
	<cfargument name="value" required="yes">
	<cfargument name="cfsqltype" type="string" required="yes">
	<cfargument name="list" type="boolean" required="no" default="false">
	<cfargument name="scale" type="numeric" required="no">
	<cfset var paramName = "">
	<cfset var paramStruct = { value = arguments.value, cfsqltype = arguments.cfsqltype }>
	<cfif REFind("^[A-Za-z_][A-Za-z0-9_]*$",arguments.paramBase) EQ 0>
		<cfthrow type="Application" message="Invalid parameter base name for queryExecute binding.">
	</cfif>
	<cfset paramName = arguments.paramBase & "_" & (structCount(arguments.params) + 1)>
	<cfif arguments.list>
		<cfset paramStruct["list"] = true>
	</cfif>
	<cfif structKeyExists(arguments,"scale")>
		<cfset paramStruct["scale"] = arguments.scale>
	</cfif>
	<cfset arguments.params[paramName] = paramStruct>
	<cfreturn ":" & paramName>
</cffunction>

<!--- Function appendSetupClauseCondition to add a text field clause prepared by setupClause to a WHERE clause array.

@param whereClauses array of SQL WHERE clause fragments.
@param params struct of named query parameters for queryExecute.
@param field SQL field/expression to query.
@param value user supplied query value to parse with setupClause.
@param paramBase trusted internal base name used when creating named parameters;
	never pass user-provided content.
@return updated whereClauses array including appended clause.
--->
<cffunction name="appendSetupClauseCondition" access="private" returntype="array">
	<cfargument name="whereClauses" type="array" required="yes">
	<cfargument name="params" type="struct" required="yes">
	<cfargument name="field" type="string" required="yes">
	<cfargument name="value" type="string" required="yes">
	<cfargument name="paramBase" type="string" required="yes">
	<cfset var setup = setupClause(field=arguments.field,value=arguments.value)>
	<cfset var clause = "">
	<cfif len(setup["value"]) EQ 0>
		<cfset clause = "#setup['pre']# #setup['post']#">
	<cfelse>
		<cfset clause = "#setup['pre']# #addNamedQueryParam(params=arguments.params,paramBase=arguments.paramBase,value=setup['value'],cfsqltype='CF_SQL_VARCHAR',list=(setup['list'] EQ 'yes'))# #setup['post']#">
	</cfif>
	<cfset arrayAppend(arguments.whereClauses,trim(clause))>
	<cfreturn arguments.whereClauses>
</cffunction>

<!--- Function appendSetupNumericClauseCondition to add a numeric field clause prepared by setupNumericClause to a WHERE clause array.

@param whereClauses array of SQL WHERE clause fragments.
@param params struct of named query parameters for queryExecute.
@param field SQL field/expression to query.
@param value user supplied numeric query value to parse with setupNumericClause.
@param paramBase trusted internal base name used when creating named parameters;
	never pass user-provided content.
@param scale optional numeric scale for decimal bindings.
@return updated whereClauses array including appended clause.
--->
<cffunction name="appendSetupNumericClauseCondition" access="private" returntype="array">
	<cfargument name="whereClauses" type="array" required="yes">
	<cfargument name="params" type="struct" required="yes">
	<cfargument name="field" type="string" required="yes">
	<cfargument name="value" type="string" required="yes">
	<cfargument name="paramBase" type="string" required="yes">
	<cfargument name="scale" type="numeric" required="no">
	<cfset var setup = setupNumericClause(field=arguments.field,value=arguments.value)>
	<cfset var clause = "">
	<cfif len(setup["value"]) EQ 0>
		<cfset clause = "#setup['pre']# #setup['post']#">
	<cfelseif setup["between"] EQ "true">
		<cfif structKeyExists(arguments,"scale")>
			<cfset clause = "#setup['pre']# BETWEEN #addNamedQueryParam(params=arguments.params,paramBase=arguments.paramBase & '_start',value=setup['value'],cfsqltype='CF_SQL_DECIMAL',scale=arguments.scale)# AND #addNamedQueryParam(params=arguments.params,paramBase=arguments.paramBase & '_end',value=setup['value2'],cfsqltype='CF_SQL_DECIMAL',scale=arguments.scale)#">
		<cfelse>
			<cfset clause = "#setup['pre']# BETWEEN #addNamedQueryParam(params=arguments.params,paramBase=arguments.paramBase & '_start',value=setup['value'],cfsqltype='CF_SQL_DECIMAL')# AND #addNamedQueryParam(params=arguments.params,paramBase=arguments.paramBase & '_end',value=setup['value2'],cfsqltype='CF_SQL_DECIMAL')#">
		</cfif>
	<cfelse>
		<cfif structKeyExists(arguments,"scale")>
			<cfset clause = "#setup['pre']# #addNamedQueryParam(params=arguments.params,paramBase=arguments.paramBase,value=setup['value'],cfsqltype='CF_SQL_DECIMAL',list=(setup['list'] EQ 'yes'),scale=arguments.scale)# #setup['post']#">
		<cfelse>
			<cfset clause = "#setup['pre']# #addNamedQueryParam(params=arguments.params,paramBase=arguments.paramBase,value=setup['value'],cfsqltype='CF_SQL_DECIMAL',list=(setup['list'] EQ 'yes'))# #setup['post']#">
		</cfif>
	</cfif>
	<cfset arrayAppend(arguments.whereClauses,trim(clause))>
	<cfreturn arguments.whereClauses>
</cffunction>

<!--- Function getCollectingEvents_queryExecute.
	QueryExecute variant of getCollectingEvents, with drop-in signature and return format.
	LEGACY_SPEC_LOCALITY_FG remains unused.

@param any_geography, higher_geog, geog_auth_rec_id, continent_ocean, ocean_region, ocean_subregion, sea, island, island_group, feature, water_feature, country, state_prov, county, highergeographyid, highergeographyid_guid_type, source_authority, return_wkt locality and geography filters.
@param locality_id, spec_locality, locality_remarks, orig_elev_units, minElevOper, minimum_elevation, minimum_elevation_m, maxElevOper, maximum_elevation, maximum_elevation_m, depth_units, minDepthOper, min_depth, min_depth_m, maxDepthOper, max_depth, max_depth_m elevation/depth filters.
@param accentInsenstive, collection_id, collnOper, collnEvOper, include_counts, township, range, township_direction, range_direction, section, section_part grid and collection filters.
@param dec_lat, dec_long, datum, max_error_distance, georef_updated_date, georef_by, geolocate_precision, geolocate_score, geolocate_score2, gs_comparator, coordinateDeterminer, georeference_verified_by_id, georeference_verified_by georeference filters.
@param verbatim_locality, verbatimdepth, verbatimelevation, verbatim_date, collecting_source, collecting_method, habitat_desc, coll_event_remarks, began_date, ended_date, verbatimCoordinates, verbatimsrs, verbatimcoordinatesystem, verbatimlatitude, verbatimlongitude, startdayofyear, enddayofyear, collectingtime, fish_field_number, verbatim_collectors, verbatim_field_numbers, verbatim_habitat collecting event filters.
@param date_determined_by_agent_id, date_determined_by_agent, valid_distribution_fg, show_unused additional search filters.
@return json containing data about collecting events matching specified search criteria.
--->
<cffunction name="getCollectingEvents_queryExecute" access="remote" returntype="any" returnformat="json">
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
	<cfargument name="sovereign_nation" type="string" required="no">
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
	<cfargument name="collnEvOper" type="string" required="no">
	<cfargument name="include_counts" type="string" required="no"><!--- locality counts by collection --->
	<cfargument name="township" type="string" required="no">
	<cfargument name="range" type="string" required="no">
	<cfargument name="township_direction" type="string" required="no">
	<cfargument name="range_direction" type="string" required="no">
	<cfargument name="section" type="string" required="no">
	<cfargument name="section_part" type="string" required="no">
	<cfargument name="geology_attribute" type="string" required="no">
	<cfargument name="geo_att_value" type="string" required="no">
	<cfargument name="geology_attribute_hier" type="string" required="no">
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
	<cfargument name="findNoGeoRef" type="string" required="no">
	<cfargument name="findHasGeoRef" type="string" required="no">
	<cfargument name="findNoAccGeoRef" type="string" required="no">
	<cfargument name="NoGeorefBecause" type="string" required="no">
	<cfargument name="isIncomplete" type="string" required="no">
	<cfargument name="nullNoGeorefBecause" type="string" required="no">
	<cfargument name="VerificationStatus" type="string" required="no">
	<cfargument name="onlyShared" type="string" required="no">
	<cfargument name="GeorefMethod" type="string" required="no">
	<cfargument name="collecting_event_id" type="string" required="no">
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
	<cfargument name="verbatimsrs" type="string" required="no">
	<cfargument name="verbatimcoordinatesystem" type="string" required="no">
	<cfargument name="verbatimlatitude" type="string" required="no">
	<cfargument name="verbatimlongitude" type="string" required="no">
	<cfargument name="startdayofyear" type="string" required="no">
	<cfargument name="enddayofyear" type="string" required="no">
	<cfargument name="collectingtime" type="string" required="no">
	<cfargument name="fish_field_number" type="string" required="no">
	<cfargument name="verbatim_collectors" type="string" required="no">
	<cfargument name="verbatim_field_numbers" type="string" required="no">
	<cfargument name="verbatim_habitat" type="string" required="no">
	<cfargument name="date_determined_by_agent_id" type="string" required="no">
	<cfargument name="date_determined_by_agent" type="string" required="no">
	<cfargument name="valid_distribution_fg" type="string" required="no">
	<cfargument name="show_unused" type="string" required="no">
	<cfargument name="collector_agent" type="string" required="no">
   <cfargument name="collector_agent_id" type="string" required="no">

	<!---
	"LEGACY_SPEC_LOCALITY_FG" NUMBER,  Unused
	--->

	<cfset linguisticFlag = false>
	<cfif structKeyExists(arguments,"accentInsenstive") AND NOT structKeyExists(arguments,"accentInsensitive")>
		<cfset arguments.accentInsensitive = arguments.accentInsenstive>
	</cfif>
	<cfif structKeyExists(arguments,"accentInsensitive") AND arguments.accentInsensitive EQ 1>
		<cfset linguisticFlag=true>
	</cfif>
	<cfif structKeyExists(arguments,"collectingtime") AND NOT structKeyExists(arguments,"collecting_time")>
		<cfset arguments.collecting_time = arguments.collectingtime>
	</cfif>
	<cfif structKeyExists(arguments,"collection_id") and len(arguments.collection_id) gt 0>
		<cfif not structKeyExists(arguments,"collnOper")><cfset arguments.collnOper= "usedBy"></cfif>
	</cfif>
	<cfif NOT structKeyExists(arguments,"return_wkt")><cfset arguments.return_wkt=""></cfif>
	<cfset includeCounts = false>
	<cfif structKeyExists(arguments,"include_counts") AND arguments.include_counts EQ 1 >
		<cfset includeCounts=true>
	</cfif>
	<cfif not structKeyExists(arguments,"gs_comparator") OR len(arguments.gs_comparator) EQ 0>
		<cfset arguments.gs_comparator = "">
	</cfif>
	<cfif NOT structKeyExists(arguments,"begDateOper")><cfset arguments.begDateOper=""></cfif>
	<cfif NOT structKeyExists(arguments,"endDateOper")><cfset arguments.endDateOper=""></cfif>
	<cfif structKeyExists(arguments,"geog_auth_rec_id") AND len(arguments.geog_auth_rec_id) GT 0>
		<cfset arguments.geog_auth_rec_id = rereplace(arguments.geog_auth_rec_id,"[^0-9,]","","all")>
	</cfif>
	<cfif NOT structKeyExists(arguments,"collnEvOper")><cfset arguments.collnEvOper=""></cfif>
	<cfif structKeyExists(arguments,"maximum_elevation") AND len(arguments.maximum_elevation) gt 0>
		<cfif structKeyExists(arguments,"maxElevOper") and arguments.maxElevOper EQ "!" and left(arguments.maximum_elevation,1) NEQ "!"><cfset arguments.maximum_elevation="!#arguments.maximum_elevation#"></cfif>
		<cfif structKeyExists(arguments,"maxElevOper") and arguments.maxElevOper EQ "<>" and left(arguments.maximum_elevation,2) NEQ "<>"><cfset arguments.maximum_elevation="!#arguments.maximum_elevation#"></cfif>
		<cfif structKeyExists(arguments,"maxElevOper") and arguments.maxElevOper EQ "<" and left(arguments.maximum_elevation,1) NEQ "<"><cfset arguments.maximum_elevation="<#arguments.maximum_elevation#"></cfif>
		<cfif structKeyExists(arguments,"maxElevOper") and arguments.maxElevOper EQ ">" and left(arguments.maximum_elevation,1) NEQ ">"><cfset arguments.maximum_elevation=">#arguments.maximum_elevation#"></cfif>
	</cfif>
	<cfif structKeyExists(arguments,"minimum_elevation") AND len(arguments.minimum_elevation) gt 0>
		<cfif structKeyExists(arguments,"minElevOper") and arguments.minElevOper EQ "!" and left(arguments.minimum_elevation,1) NEQ "!"><cfset arguments.minimum_elevation="!#arguments.minimum_elevation#"></cfif>
		<cfif structKeyExists(arguments,"minElevOper") and arguments.minElevOper EQ "<>" and left(arguments.minimum_elevation,2) NEQ "<>"><cfset arguments.minimum_elevation="!#arguments.minimum_elevation#"></cfif>
		<cfif structKeyExists(arguments,"minElevOper") and arguments.minElevOper EQ "<" and left(arguments.minimum_elevation,1) NEQ "<"><cfset arguments.minimum_elevation="<#arguments.minimum_elevation#"></cfif>
		<cfif structKeyExists(arguments,"minElevOper") and arguments.minElevOper EQ ">" and left(arguments.minimum_elevation,1) NEQ ">"><cfset arguments.minimum_elevation=">#arguments.minimum_elevation#"></cfif>
	</cfif>
	<cfif structKeyExists(arguments,"maximum_elevation_m") AND len(arguments.maximum_elevation_m) gt 0>
		<cfif structKeyExists(arguments,"maxElevOperM") and arguments.maxElevOperM EQ "!" and left(arguments.maximum_elevation_m,1) NEQ "!"><cfset arguments.maximum_elevation_m="!#arguments.maximum_elevation_m#"></cfif>
		<cfif structKeyExists(arguments,"maxElevOperM") and arguments.maxElevOperM EQ "<>" and left(arguments.maximum_elevation_m,2) NEQ "<>"><cfset arguments.maximum_elevation_m="!#arguments.maximum_elevation_m#"></cfif>
		<cfif structKeyExists(arguments,"maxElevOperM") and arguments.maxElevOperM EQ "<" and left(arguments.maximum_elevation_m,1) NEQ "<"><cfset arguments.maximum_elevation_m="<#arguments.maximum_elevation_m#"></cfif>
		<cfif structKeyExists(arguments,"maxElevOperM") and arguments.maxElevOperM EQ ">" and left(arguments.maximum_elevation_m,1) NEQ ">"><cfset arguments.maximum_elevation_m=">#arguments.maximum_elevation_m#"></cfif>
	</cfif>
	<cfif structKeyExists(arguments,"minimum_elevation_m") AND len(arguments.minimum_elevation_m) gt 0>
		<cfif structKeyExists(arguments,"minElevOperM") and arguments.minElevOperM EQ "!" and left(arguments.minimum_elevation_m,1) NEQ "!"><cfset arguments.minimum_elevation_m="!#arguments.minimum_elevation_m#"></cfif>
		<cfif structKeyExists(arguments,"minElevOperM") and arguments.minElevOperM EQ "<>" and left(arguments.minimum_elevation_m,2) NEQ "<>"><cfset arguments.minimum_elevation_m="!#arguments.minimum_elevation_m#"></cfif>
		<cfif structKeyExists(arguments,"minElevOperM") and arguments.minElevOperM EQ "<" and left(arguments.minimum_elevation_m,1) NEQ "<"><cfset arguments.minimum_elevation_m="<#arguments.minimum_elevation_m#"></cfif>
		<cfif structKeyExists(arguments,"minElevOperM") and arguments.minElevOperM EQ ">" and left(arguments.minimum_elevation_m,1) NEQ ">"><cfset arguments.minimum_elevation_m=">#arguments.minimum_elevation_m#"></cfif>
	</cfif>
	<cfif structKeyExists(arguments,"max_depth") AND len(arguments.max_depth) gt 0>
		<cfif structKeyExists(arguments,"maxDepthOper") and arguments.maxDepthOper EQ "!" and left(arguments.max_depth,1) NEQ "!"><cfset arguments.max_depth="!#arguments.max_depth#"></cfif>
		<cfif structKeyExists(arguments,"maxDepthOper") and arguments.maxDepthOper EQ "<>" and left(arguments.max_depth,2) NEQ "<>"><cfset arguments.max_depth="!#arguments.max_depth#"></cfif>
		<cfif structKeyExists(arguments,"maxDepthOper") and arguments.maxDepthOper EQ "<" and left(arguments.max_depth,1) NEQ "<"><cfset arguments.max_depth="<#arguments.max_depth#"></cfif>
		<cfif structKeyExists(arguments,"maxDepthOper") and arguments.maxDepthOper EQ ">" and left(arguments.max_depth,1) NEQ ">"><cfset arguments.max_depth=">#arguments.max_depth#"></cfif>
	</cfif>
	<cfif structKeyExists(arguments,"min_depth") AND len(arguments.min_depth) gt 0>
		<cfif structKeyExists(arguments,"minDepthOper") and arguments.minDepthOper EQ "!" and left(arguments.min_depth,1) NEQ "!"><cfset arguments.min_depth="!#arguments.min_depth#"></cfif>
		<cfif structKeyExists(arguments,"minDepthOper") and arguments.minDepthOper EQ "<>" and left(arguments.min_depth,2) NEQ "<>"><cfset arguments.min_depth="!#arguments.min_depth#"></cfif>
		<cfif structKeyExists(arguments,"minDepthOper") and arguments.minDepthOper EQ "<" and left(arguments.min_depth,1) NEQ "<"><cfset arguments.min_depth="<#arguments.min_depth#"></cfif>
		<cfif structKeyExists(arguments,"minDepthOper") and arguments.minDepthOper EQ ">" and left(arguments.min_depth,1) NEQ ">"><cfset arguments.min_depth=">#arguments.min_depth#"></cfif>
	</cfif>
	<cfif structKeyExists(arguments,"max_depth_m") AND len(arguments.max_depth_m) gt 0>
		<cfif structKeyExists(arguments,"maxDepthOperM") and arguments.maxDepthOperM EQ "!" and left(arguments.max_depth_m,1) NEQ "!"><cfset arguments.max_depth_m="!#arguments.max_depth_m#"></cfif>
		<cfif structKeyExists(arguments,"maxDepthOperM") and arguments.maxDepthOperM EQ "<>" and left(arguments.max_depth_m,2) NEQ "<>"><cfset arguments.max_depth_m="!#arguments.max_depth_m#"></cfif>
		<cfif structKeyExists(arguments,"maxDepthOperM") and arguments.maxDepthOperM EQ "<" and left(arguments.max_depth_m,1) NEQ "<"><cfset arguments.max_depth_m="<#arguments.max_depth_m#"></cfif>
		<cfif structKeyExists(arguments,"maxDepthOperM") and arguments.maxDepthOperM EQ ">" and left(arguments.max_depth_m,1) NEQ ">"><cfset arguments.max_depth_m=">#arguments.max_depth_m#"></cfif>
	</cfif>
	<cfif structKeyExists(arguments,"min_depth_m") AND len(arguments.min_depth_m) gt 0>
		<cfif structKeyExists(arguments,"minDepthOperM") and arguments.minDepthOperM EQ "!" and left(arguments.min_depth_m,1) NEQ "!"><cfset arguments.min_depth_m="!#arguments.min_depth_m#"></cfif>
		<cfif structKeyExists(arguments,"minDepthOperM") and arguments.minDepthOperM EQ "<>" and left(arguments.min_depth_m,2) NEQ "<>"><cfset arguments.min_depth_m="!#arguments.min_depth_m#"></cfif>
		<cfif structKeyExists(arguments,"minDepthOperM") and arguments.minDepthOperM EQ "<" and left(arguments.min_depth_m,1) NEQ "<"><cfset arguments.min_depth_m="<#arguments.min_depth_m#"></cfif>
		<cfif structKeyExists(arguments,"minDepthOperM") and arguments.minDepthOperM EQ ">" and left(arguments.min_depth_m,1) NEQ ">"><cfset arguments.min_depth_m=">#arguments.min_depth_m#"></cfif>
	</cfif>

	<cfset data = ArrayNew(1)>
	<cfset whereClauses = ArrayNew(1)>
	<cfset sqlParams = StructNew()>
	<cfset flatTableName = "filtered_flat">
	<cfif ucase(session.flatTableName) EQ "FLAT"><cfset flatTableName = "flat"></cfif>

	<cftry>
		<cfif linguisticFlag >
			<cfset queryExecute("ALTER SESSION SET NLS_COMP = LINGUISTIC",{},{
				datasource="user_login",
				username=session.dbuser,
				password=decrypt(session.epw,cookie.cfid)
			})>
			<cfset queryExecute("ALTER SESSION SET NLS_SORT = GENERIC_M_AI",{},{
				datasource="user_login",
				username=session.dbuser,
				password=decrypt(session.epw,cookie.cfid)
			})>
		</cfif>

		<cfset arrayAppend(whereClauses,"collecting_event.collecting_event_id is not null")>

		<cfif structKeyExists(arguments,"show_unused") AND arguments.show_unused EQ "unused_only">
			<cfset arrayAppend(whereClauses,"collecting_event.collecting_event_id not in (select collecting_event_id from flat)")>
		</cfif>
		<cfif structKeyExists(arguments,"any_geography") and len(arguments.any_geography) gt 0>
			<cfset arrayAppend(whereClauses,"locality.locality_id in (select locality_id from flat where contains(HIGHER_GEOG,#addNamedQueryParam(sqlParams,'any_geography',arguments.any_geography,'CF_SQL_VARCHAR')#,1) > 0)")>
		</cfif>
		<cfif structKeyExists(arguments,"geog_auth_rec_id") and len(arguments.geog_auth_rec_id) gt 0>
			<cfset arrayAppend(whereClauses,"geog_auth_rec.geog_auth_rec_id IN (#addNamedQueryParam(sqlParams,'geog_auth_rec_id',arguments.geog_auth_rec_id,'CF_SQL_DECIMAL',true)#)")>
		<cfelse>
			<cfif structKeyExists(arguments,"higher_geog") and len(arguments.higher_geog) gt 0>
				<cfif left(arguments.higher_geog,1) is "=">
					<cfset arrayAppend(whereClauses,"upper(geog_auth_rec.higher_geog) = #addNamedQueryParam(sqlParams,'higher_geog_eq',ucase(right(arguments.higher_geog,len(arguments.higher_geog)-1)),'CF_SQL_VARCHAR')#")>
				<cfelse>
					<cfset arrayAppend(whereClauses,"upper(geog_auth_rec.higher_geog) like #addNamedQueryParam(sqlParams,'higher_geog_like','%' & ucase(arguments.higher_geog) & '%','CF_SQL_VARCHAR')#")>
				</cfif>
			</cfif>
		</cfif>
		<cfif ucase(#session.flatTableName#) EQ 'FLAT'><cfset flatTable="flat"><cfelse><cfset flatTable="filtered_flat"></cfif>
		<cfif structKeyExists(arguments,"collector_agent_id") and len(arguments.collector_agent_id) gt 0>
			<cfset arrayAppend(whereClauses,"collecting_event.collecting_event_id IN (SELECT collecting_event_id FROM collector LEFT JOIN #flatTable# flatTableName ON collector.collection_object_id=flatTableName.collection_object_id WHERE collector_role = 'c' AND agent_id = #addNamedQueryParam(sqlParams,'collector_agent_id',arguments.collector_agent_id,'CF_SQL_DECIMAL')#)")>
		<cfelse>
		 	<cfif structKeyExists(arguments,"collector_agent") and len(arguments.collector_agent) gt 0>
				<cfset arrayAppend(whereClauses,"collecting_event.collecting_event_id IN (SELECT collecting_event_id FROM collector LEFT JOIN #flatTable# flatTableName ON collector.collection_object_id=flatTableName.collection_object_id LEFT JOIN agent_name ON collector.agent_id = agent_name.agent_id WHERE collector_role = 'c' AND upper(agent_name.agent_name) like #addNamedQueryParam(sqlParams,'collector_agent','%' & ucase(arguments.collector_agent) & '%','CF_SQL_VARCHAR')#)")>
			</cfif>
		</cfif>
		<cfif structKeyExists(arguments,"locality_id") and len(arguments.locality_id) gt 0>
			<cfif Find(",",arguments.locality_id) GT 0>
				<cfset arrayAppend(whereClauses,"locality.locality_id IN (#addNamedQueryParam(sqlParams,'locality_id',arguments.locality_id,'CF_SQL_DECIMAL',true)#)")>
			<cfelse>
				<cfset arrayAppend(whereClauses,"locality.locality_id = #addNamedQueryParam(sqlParams,'locality_id',arguments.locality_id,'CF_SQL_DECIMAL')#")>
			</cfif>
		</cfif>
		<cfif structKeyExists(arguments,"valid_distribution_fg") and len(arguments.valid_distribution_fg) gt 0>
			<cfif arguments.valid_distribution_fg EQ 'NULL'>
				<cfset arrayAppend(whereClauses,"valid_distribution_fg IS NULL")>
			<cfelseif arguments.valid_distribution_fg EQ 'NOT NULL'>
				<cfset arrayAppend(whereClauses,"valid_distribution_fg IS NOT NULL")>
			<cfelse>
				<cfset arrayAppend(whereClauses,"valid_distribution_fg = #addNamedQueryParam(sqlParams,'valid_distribution_fg',arguments.valid_distribution_fg,'CF_SQL_DECIMAL')#")>
			</cfif>
		</cfif>

		<cfif structKeyExists(arguments,"continent_ocean") AND len(arguments.continent_ocean) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"geog_auth_rec.continent_ocean",arguments.continent_ocean,"continent_ocean")></cfif>
		<cfif structKeyExists(arguments,"country") AND len(arguments.country) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"geog_auth_rec.country",arguments.country,"country")></cfif>
		<cfif structKeyExists(arguments,"state_prov") AND len(arguments.state_prov) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"geog_auth_rec.state_prov",arguments.state_prov,"state_prov")></cfif>
		<cfif structKeyExists(arguments,"county") AND len(arguments.county) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"geog_auth_rec.county",arguments.county,"county")></cfif>
		<cfif structKeyExists(arguments,"sovereign_nation") AND len(arguments.sovereign_nation) gt 0><cfset arrayAppend(whereClauses,"locality.sovereign_nation = #addNamedQueryParam(sqlParams,'sovereign_nation',arguments.sovereign_nation,'CF_SQL_VARCHAR')#")></cfif>
		<cfif structKeyExists(arguments,"feature") AND len(arguments.feature) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"geog_auth_rec.feature",arguments.feature,"feature")></cfif>
		<cfif structKeyExists(arguments,"island") AND len(arguments.island) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"geog_auth_rec.island",arguments.island,"island")></cfif>
		<cfif structKeyExists(arguments,"island_group") AND len(arguments.island_group) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"geog_auth_rec.island_group",arguments.island_group,"island_group")></cfif>
		<cfif structKeyExists(arguments,"ocean_region") AND len(arguments.ocean_region) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"geog_auth_rec.ocean_region",arguments.ocean_region,"ocean_region")></cfif>
		<cfif structKeyExists(arguments,"ocean_subregion") AND len(arguments.ocean_subregion) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"geog_auth_rec.ocean_subregion",arguments.ocean_subregion,"ocean_subregion")></cfif>
		<cfif structKeyExists(arguments,"sea") AND len(arguments.sea) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"geog_auth_rec.sea",arguments.sea,"sea")></cfif>
		<cfif structKeyExists(arguments,"water_feature") AND len(arguments.water_feature) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"geog_auth_rec.water_feature",arguments.water_feature,"water_feature")></cfif>
		<cfif structKeyExists(arguments,"source_authority") AND len(arguments.source_authority) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"geog_auth_rec.source_authority",arguments.source_authority,"source_authority")></cfif>
		<cfif structKeyExists(arguments,"highergeographyid") AND len(arguments.highergeographyid) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"geog_auth_rec.highergeographyid",arguments.highergeographyid,"highergeographyid")></cfif>
		<cfif structKeyExists(arguments,"highergeographyid_guid_type") AND len(arguments.highergeographyid_guid_type) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"geog_auth_rec.highergeographyid_guid_type",arguments.highergeographyid_guid_type,"highergeographyid_guid_type")></cfif>
		<cfif structKeyExists(arguments,"spec_locality") AND len(arguments.spec_locality) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"locality.spec_locality",arguments.spec_locality,"spec_locality")></cfif>
		<cfif structKeyExists(arguments,"locality_remarks") AND len(arguments.locality_remarks) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"locality.locality_remarks",arguments.locality_remarks,"locality_remarks")></cfif>
		<cfif structKeyExists(arguments,"orig_elev_units") AND len(arguments.orig_elev_units) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"locality.orig_elev_units",arguments.orig_elev_units,"orig_elev_units")></cfif>
		<cfif structKeyExists(arguments,"depth_units") AND len(arguments.depth_units) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"locality.depth_units",arguments.depth_units,"depth_units")></cfif>
		<cfif structKeyExists(arguments,"section_part") AND len(arguments.section_part) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"locality.section_part",arguments.section_part,"section_part")></cfif>
		<cfif structKeyExists(arguments,"datum") AND len(arguments.datum) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"accepted_lat_long.datum",arguments.datum,"datum")></cfif>
		<cfif structKeyExists(arguments,"georef_by") AND len(arguments.georef_by) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"locality.georef_by",arguments.georef_by,"georef_by")></cfif>
		<cfif structKeyExists(arguments,"collecting_event_id") AND len(arguments.collecting_event_id) gt 0><cfset whereClauses = appendSetupNumericClauseCondition(whereClauses,sqlParams,"collecting_event.collecting_event_id",arguments.collecting_event_id,"collecting_event_id")></cfif>
		<cfif structKeyExists(arguments,"verbatim_locality") AND len(arguments.verbatim_locality) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"collecting_event.verbatim_locality",arguments.verbatim_locality,"verbatim_locality")></cfif>
		<cfif structKeyExists(arguments,"verbatim_date") AND len(arguments.verbatim_date) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"collecting_event.verbatim_date",arguments.verbatim_date,"verbatim_date")></cfif>
		<cfif structKeyExists(arguments,"verbatimdepth") AND len(arguments.verbatimdepth) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"collecting_event.verbatimdepth",arguments.verbatimdepth,"verbatimdepth")></cfif>
		<cfif structKeyExists(arguments,"verbatimelevation") AND len(arguments.verbatimelevation) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"collecting_event.verbatimelevation",arguments.verbatimelevation,"verbatimelevation")></cfif>
		<cfif structKeyExists(arguments,"verbatimCoordinates") AND len(arguments.verbatimCoordinates) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"collecting_event.verbatimCoordinates",arguments.verbatimCoordinates,"verbatimCoordinates")></cfif>
		<cfif structKeyExists(arguments,"habitat_desc") AND len(arguments.habitat_desc) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"collecting_event.habitat_desc",arguments.habitat_desc,"habitat_desc")></cfif>
		<cfif structKeyExists(arguments,"collecting_source") AND len(arguments.collecting_source) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"collecting_event.collecting_source",arguments.collecting_source,"collecting_source")></cfif>
		<cfif structKeyExists(arguments,"collecting_method") AND len(arguments.collecting_method) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"collecting_event.collecting_method",arguments.collecting_method,"collecting_method")></cfif>
		<cfif structKeyExists(arguments,"coll_event_remarks") AND len(arguments.coll_event_remarks) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"collecting_event.coll_event_remarks",arguments.coll_event_remarks,"coll_event_remarks")></cfif>
		<cfif structKeyExists(arguments,"fish_field_number") AND len(arguments.fish_field_number) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"collecting_event.fish_field_number",arguments.fish_field_number,"fish_field_number")></cfif>
		<cfif structKeyExists(arguments,"verbatim_collectors") AND len(arguments.verbatim_collectors) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"collecting_event.verbatim_collectors",arguments.verbatim_collectors,"verbatim_collectors")></cfif>
		<cfif structKeyExists(arguments,"collecting_time") AND len(arguments.collecting_time) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"collecting_event.collecting_time",arguments.collecting_time,"collecting_time")></cfif>
		<cfif structKeyExists(arguments,"verbatimsrs") AND len(arguments.verbatimsrs) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"collecting_event.verbatimsrs",arguments.verbatimsrs,"verbatimsrs")></cfif>
		<cfif structKeyExists(arguments,"verbatimcoordinatesystem") AND len(arguments.verbatimcoordinatesystem) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"collecting_event.verbatimcoordinatesystem",arguments.verbatimcoordinatesystem,"verbatimcoordinatesystem")></cfif>
		<cfif structKeyExists(arguments,"verbatimlatitude") AND len(arguments.verbatimlatitude) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"collecting_event.verbatimlatitude",arguments.verbatimlatitude,"verbatimlatitude")></cfif>
		<cfif structKeyExists(arguments,"verbatimlongitude") AND len(arguments.verbatimlongitude) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"collecting_event.verbatimlongitude",arguments.verbatimlongitude,"verbatimlongitude")></cfif>
		<cfif structKeyExists(arguments,"verbatim_field_numbers") AND len(arguments.verbatim_field_numbers) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"collecting_event.verbatim_field_numbers",arguments.verbatim_field_numbers,"verbatim_field_numbers")></cfif>
		<cfif structKeyExists(arguments,"verbatim_habitat") AND len(arguments.verbatim_habitat) gt 0><cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"collecting_event.verbatim_habitat",arguments.verbatim_habitat,"verbatim_habitat")></cfif>

		<cfif structKeyExists(arguments,"minimum_elevation") AND len(arguments.minimum_elevation) gt 0><cfset whereClauses = appendSetupNumericClauseCondition(whereClauses,sqlParams,"locality.minimum_elevation",arguments.minimum_elevation,"minimum_elevation")></cfif>
		<cfif structKeyExists(arguments,"minimum_elevation_m") AND len(arguments.minimum_elevation_m) gt 0><cfset whereClauses = appendSetupNumericClauseCondition(whereClauses,sqlParams,"TO_METERS(locality.minimum_elevation,locality.orig_elev_units)",arguments.minimum_elevation_m,"minimum_elevation_m")></cfif>
		<cfif structKeyExists(arguments,"maximum_elevation") AND len(arguments.maximum_elevation) gt 0><cfset whereClauses = appendSetupNumericClauseCondition(whereClauses,sqlParams,"locality.maximum_elevation",arguments.maximum_elevation,"maximum_elevation")></cfif>
		<cfif structKeyExists(arguments,"maximum_elevation_m") AND len(arguments.maximum_elevation_m) gt 0><cfset whereClauses = appendSetupNumericClauseCondition(whereClauses,sqlParams,"TO_METERS(locality.maximum_elevation,locality.orig_elev_units)",arguments.maximum_elevation_m,"maximum_elevation_m")></cfif>
		<cfif structKeyExists(arguments,"min_depth") AND len(arguments.min_depth) gt 0><cfset whereClauses = appendSetupNumericClauseCondition(whereClauses,sqlParams,"locality.min_depth",arguments.min_depth,"min_depth")></cfif>
		<cfif structKeyExists(arguments,"min_depth_m") AND len(arguments.min_depth_m) gt 0><cfset whereClauses = appendSetupNumericClauseCondition(whereClauses,sqlParams,"TO_METERS(locality.min_depth,locality.depth_units)",arguments.min_depth_m,"min_depth_m")></cfif>
		<cfif structKeyExists(arguments,"max_depth") AND len(arguments.max_depth) gt 0><cfset whereClauses = appendSetupNumericClauseCondition(whereClauses,sqlParams,"locality.max_depth",arguments.max_depth,"max_depth")></cfif>
		<cfif structKeyExists(arguments,"max_depth_m") AND len(arguments.max_depth_m) gt 0><cfset whereClauses = appendSetupNumericClauseCondition(whereClauses,sqlParams,"TO_METERS(locality.max_depth,locality.depth_units)",arguments.max_depth_m,"max_depth_m")></cfif>
		<cfif structKeyExists(arguments,"section") AND len(arguments.section) gt 0><cfset whereClauses = appendSetupNumericClauseCondition(whereClauses,sqlParams,"locality.section",arguments.section,"section")></cfif>
		<cfif structKeyExists(arguments,"township") AND len(arguments.township) gt 0><cfset whereClauses = appendSetupNumericClauseCondition(whereClauses,sqlParams,"locality.township",arguments.township,"township")></cfif>
		<cfif structKeyExists(arguments,"range") AND len(arguments.range) gt 0><cfset whereClauses = appendSetupNumericClauseCondition(whereClauses,sqlParams,"locality.range",arguments.range,"range")></cfif>
		<cfif structKeyExists(arguments,"max_error_distance") AND len(arguments.max_error_distance) gt 0><cfset whereClauses = appendSetupNumericClauseCondition(whereClauses,sqlParams,"accepted_lat_long.max_error_distance",arguments.max_error_distance,"max_error_distance")></cfif>
		<cfif structKeyExists(arguments,"startdayofyear") AND len(arguments.startdayofyear) gt 0><cfset whereClauses = appendSetupNumericClauseCondition(whereClauses,sqlParams,"collecting_event.startdayofyear",arguments.startdayofyear,"startdayofyear")></cfif>
		<cfif structKeyExists(arguments,"enddayofyear") AND len(arguments.enddayofyear) gt 0><cfset whereClauses = appendSetupNumericClauseCondition(whereClauses,sqlParams,"collecting_event.enddayofyear",arguments.enddayofyear,"enddayofyear")></cfif>
		<cfif structKeyExists(arguments,"township_direction") AND len(arguments.township_direction) gt 0>
			<cfif ucase(arguments.township_direction) EQ "NULL">
				<cfset arrayAppend(whereClauses,"locality.township_direction IS NULL")>
			<cfelseif ucase(arguments.township_direction) EQ "NOT NULL">
				<cfset arrayAppend(whereClauses,"locality.township_direction IS NOT NULL")>
			<cfelse>
				<cfset arrayAppend(whereClauses,"upper(locality.township_direction) = #addNamedQueryParam(sqlParams,'township_direction',arguments.township_direction,'CF_SQL_VARCHAR')#")>
			</cfif>
		</cfif>
		<cfif structKeyExists(arguments,"range_direction") AND len(arguments.range_direction) gt 0>
			<cfif ucase(arguments.range_direction) EQ "NULL">
				<cfset arrayAppend(whereClauses,"locality.range_direction IS NULL")>
			<cfelseif ucase(arguments.range_direction) EQ "NOT NULL">
				<cfset arrayAppend(whereClauses,"locality.range_direction IS NOT NULL")>
			<cfelse>
				<cfset arrayAppend(whereClauses,"upper(locality.range_direction) = #addNamedQueryParam(sqlParams,'range_direction',arguments.range_direction,'CF_SQL_VARCHAR')#")>
			</cfif>
		</cfif>
		<cfif structKeyExists(arguments,"collection_id") and len(arguments.collection_id) gt 0>
			<cfif arguments.collnOper is "usedOnlyBy">
				<cfset arrayAppend(whereClauses,"locality.locality_id in (select locality_id from vpd_collection_locality where collection_id = #addNamedQueryParam(sqlParams,'collection_id_locality_usedonly',arguments.collection_id,'CF_SQL_DECIMAL')# )")>
				<cfset arrayAppend(whereClauses,"locality.locality_id not in (select locality_id from vpd_collection_locality where collection_id <> #addNamedQueryParam(sqlParams,'collection_id_locality_notused',arguments.collection_id,'CF_SQL_DECIMAL')# and collection_id <> 0 )")>
			<cfelseif arguments.collnOper is "usedBy">
				<cfset arrayAppend(whereClauses,"locality.locality_id in (select locality_id from vpd_collection_locality where collection_id = #addNamedQueryParam(sqlParams,'collection_id_locality_used',arguments.collection_id,'CF_SQL_DECIMAL')# )")>
			<cfelseif arguments.collnOper is "notUsedBy">
				<cfset arrayAppend(whereClauses,"locality.locality_id not in (select locality_id from vpd_collection_locality where collection_id = #addNamedQueryParam(sqlParams,'collection_id_locality_notusedby',arguments.collection_id,'CF_SQL_DECIMAL')# )")>
			<cfelseif arguments.collnOper is "eventUsedOnlyBy">
				<cfset arrayAppend(whereClauses,"collecting_event.collecting_event_id in (select collecting_event_id from cataloged_item where collection_id = #addNamedQueryParam(sqlParams,'collection_id_event_usedonly',arguments.collection_id,'CF_SQL_DECIMAL')# )")>
				<cfset arrayAppend(whereClauses,"collecting_event.collecting_event_id not in (select collecting_event_id from cataloged_item where collection_id <> #addNamedQueryParam(sqlParams,'collection_id_event_notused',arguments.collection_id,'CF_SQL_DECIMAL')# and collection_id <> 0 )")>
			<cfelseif arguments.collnOper is "eventUsedBy">
				<cfset arrayAppend(whereClauses,"collecting_event.collecting_event_id in (select collecting_event_id from cataloged_item where collection_id = #addNamedQueryParam(sqlParams,'collection_id_event_used',arguments.collection_id,'CF_SQL_DECIMAL')# )")>
			<cfelseif arguments.collnOper is "eventSharedOnlyBy">
				<cfset arrayAppend(whereClauses,"collecting_event.collecting_event_id in (select collecting_event_id from cataloged_item where collection_id = #addNamedQueryParam(sqlParams,'collection_id_event_shared',arguments.collection_id,'CF_SQL_DECIMAL')# )")>
				<cfset arrayAppend(whereClauses,"collecting_event.collecting_event_id in (select collecting_event_id from cataloged_item where collection_id <> #addNamedQueryParam(sqlParams,'collection_id_event_shared_other',arguments.collection_id,'CF_SQL_DECIMAL')# and collection_id <> 0 )")>
			</cfif>
			<cfif arguments.collnEvOper IS "eventUsedOnlyBy">
				<cfset arrayAppend(whereClauses,"collecting_event.collecting_event_id in (select collecting_event_id from cataloged_item where collection_id = #addNamedQueryParam(sqlParams,'collection_id_evoper_usedonly',arguments.collection_id,'CF_SQL_DECIMAL')# )")>
				<cfset arrayAppend(whereClauses,"collecting_event.collecting_event_id not in (select collecting_event_id from cataloged_item where collection_id <> #addNamedQueryParam(sqlParams,'collection_id_evoper_notused',arguments.collection_id,'CF_SQL_DECIMAL')# and collection_id <> 0 )")>
			<cfelseif arguments.collnEvOper IS "eventUsedBy">
				<cfset arrayAppend(whereClauses,"collecting_event.collecting_event_id in (select collecting_event_id from cataloged_item where collection_id = #addNamedQueryParam(sqlParams,'collection_id_evoper_used',arguments.collection_id,'CF_SQL_DECIMAL')# )")>
			<cfelseif arguments.collnEvOper IS "eventSharedOnlyBy">
				<cfset arrayAppend(whereClauses,"collecting_event.collecting_event_id in (select collecting_event_id from cataloged_item where collection_id = #addNamedQueryParam(sqlParams,'collection_id_evoper_shared',arguments.collection_id,'CF_SQL_DECIMAL')# )")>
				<cfset arrayAppend(whereClauses,"collecting_event.collecting_event_id in (select collecting_event_id from cataloged_item where collection_id <> #addNamedQueryParam(sqlParams,'collection_id_evoper_shared_other',arguments.collection_id,'CF_SQL_DECIMAL')# and collection_id <> 0 )")>
			</cfif>
		</cfif>
		<cfif structKeyExists(arguments,"geology_attribute") and len(arguments.geology_attribute) gt 0>
			<cfset arrayAppend(whereClauses,"geology_attributes.geology_attribute = #addNamedQueryParam(sqlParams,'geology_attribute',arguments.geology_attribute,'CF_SQL_VARCHAR')#")>
		</cfif>
		<cfif structKeyExists(arguments,"geo_att_value") and len(arguments.geo_att_value) gt 0>
			<cfif structKeyExists(arguments,"geology_attribute_hier") and arguments.geology_attribute_hier is 1>
				<cfset arrayAppend(whereClauses,"geology_attributes.geo_att_value IN ( SELECT attribute_value FROM geology_attribute_hierarchy START WITH upper(attribute_value) like #addNamedQueryParam(sqlParams,'geo_att_value_hier_like','%' & ucase(arguments.geo_att_value) & '%','CF_SQL_VARCHAR')# CONNECT BY PRIOR geology_attribute_hierarchy_id = parent_id )")>
			<cfelse>
				<cfset arrayAppend(whereClauses,"upper(geology_attributes.geo_att_value) like #addNamedQueryParam(sqlParams,'geo_att_value_like','%' & ucase(arguments.geo_att_value) & '%','CF_SQL_VARCHAR')#")>
			</cfif>
		</cfif>

		<cfif structKeyExists(arguments,"dec_lat") AND len(arguments.dec_lat) gt 0>
			<cfif left(arguments.dec_lat,1) is "=">
				<cfset arrayAppend(whereClauses,"to_char(accepted_lat_long.dec_lat,'TM') = #addNamedQueryParam(sqlParams,'dec_lat_eq',right(arguments.dec_lat,len(arguments.dec_lat)-1),'CF_SQL_VARCHAR')#")>
			<cfelse>
				<cfset whereClauses = appendSetupNumericClauseCondition(whereClauses,sqlParams,"accepted_lat_long.dec_lat",arguments.dec_lat,"dec_lat",10)>
			</cfif>
		</cfif>
		<cfif structKeyExists(arguments,"dec_long") AND len(arguments.dec_long) gt 0>
			<cfif left(arguments.dec_long,1) is "=">
				<cfset arrayAppend(whereClauses,"to_char(accepted_lat_long.dec_long,'TM') = #addNamedQueryParam(sqlParams,'dec_long_eq',right(arguments.dec_long,len(arguments.dec_long)-1),'CF_SQL_VARCHAR')#")>
			<cfelse>
				<cfset whereClauses = appendSetupNumericClauseCondition(whereClauses,sqlParams,"accepted_lat_long.dec_long",arguments.dec_long,"dec_long",10)>
			</cfif>
		</cfif>

		<cfif structKeyExists(arguments,"georeference_verified_by_id") and len(arguments.georeference_verified_by_id) gt 0>
			<cfset arrayAppend(whereClauses,"georef_verified_agent.agent_id = #addNamedQueryParam(sqlParams,'georeference_verified_by_id',arguments.georeference_verified_by_id,'CF_SQL_DECIMAL')#")>
		<cfelseif structKeyExists(arguments,"georeference_verified_by") and len(arguments.georeference_verified_by) gt 0>
			<cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"georef_verified_agent.agent_name",arguments.georeference_verified_by,"georeference_verified_by")>
		</cfif>
		<cfif structKeyExists(arguments,"coordinateDeterminer") and len(arguments.coordinateDeterminer) gt 0>
			<cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"georef_determined_agent.agent_name",arguments.coordinateDeterminer,"coordinateDeterminer")>
		</cfif>
		<cfif structKeyExists(arguments,"NoGeorefBecause") AND len(arguments.NoGeorefBecause) gt 0>
			<cfset arrayAppend(whereClauses,"upper(locality.NoGeorefBecause) like #addNamedQueryParam(sqlParams,'NoGeorefBecause_like','%' & ucase(arguments.NoGeorefBecause) & '%','CF_SQL_VARCHAR')#")>
		</cfif>
		<cfif structKeyExists(arguments,"VerificationStatus") AND len(arguments.VerificationStatus) gt 0>
			<cfset arrayAppend(whereClauses,"accepted_lat_long.verificationstatus = #addNamedQueryParam(sqlParams,'VerificationStatus',arguments.VerificationStatus,'CF_SQL_VARCHAR')#")>
		</cfif>
		<cfif structKeyExists(arguments,"GeorefMethod") AND len(arguments.GeorefMethod) gt 0>
			<cfset arrayAppend(whereClauses,"accepted_lat_long.georefmethod = #addNamedQueryParam(sqlParams,'GeorefMethod',arguments.GeorefMethod,'CF_SQL_VARCHAR')#")>
		</cfif>
		<cfif structKeyExists(arguments,"nullNoGeorefBecause") and len(arguments.nullNoGeorefBecause) gt 0>
			<cfset arrayAppend(whereClauses,"locality.NoGeorefBecause IS NULL")>
		</cfif>
		<cfif structKeyExists(arguments,"isIncomplete") AND len(arguments.isIncomplete) gt 0>
			<cfset arrayAppend(whereClauses,
				"( (accepted_lat_long.GPSACCURACY IS NULL AND accepted_lat_long.EXTENT IS NULL) " &
				"OR accepted_lat_long.MAX_ERROR_DISTANCE = 0 " &
				"OR accepted_lat_long.MAX_ERROR_DISTANCE IS NULL " &
				"OR accepted_lat_long.datum IS NULL " &
				"OR accepted_lat_long.coordinate_precision IS NULL )"
			)>
		</cfif>
		<cfif structKeyExists(arguments,"findNoAccGeoRef") and len(arguments.findNoAccGeoRef) gt 0>
			<cfset arrayAppend(whereClauses,"locality.locality_id IN (select locality_id from lat_long)")>
			<cfset arrayAppend(whereClauses,"locality.locality_id NOT IN (select locality_id from lat_long where accepted_lat_long_fg=1)")>
		</cfif>
		<cfif structKeyExists(arguments,"findNoGeoRef") and len(arguments.findNoGeoRef) gt 0>
			<cfset arrayAppend(whereClauses,"locality.locality_id NOT IN (select locality_id from lat_long)")>
		</cfif>
		<cfif structKeyExists(arguments,"findHasGeoRef") and len(arguments.findHasGeoRef) gt 0>
			<cfset arrayAppend(whereClauses,"locality.locality_id IN (select locality_id from lat_long)")>
		</cfif>
		<cfif structKeyExists(arguments,"onlyShared") and len(arguments.onlyShared) gt 0>
			<cfset arrayAppend(whereClauses,"locality.locality_id in (select locality_id from FLAT group by locality_id having count(distinct collection_cde) > 1)")>
		</cfif>
		<cfif structKeyExists(arguments,"date_determined_by_agent_id") and len(arguments.date_determined_by_agent_id) gt 0>
			<cfset arrayAppend(whereClauses,"georef_verified_agent.agent_id = #addNamedQueryParam(sqlParams,'date_determined_by_agent_id',arguments.date_determined_by_agent_id,'CF_SQL_DECIMAL')#")>
		<cfelseif structKeyExists(arguments,"date_determined_by_agent") and len(arguments.date_determined_by_agent) gt 0>
			<cfset whereClauses = appendSetupClauseCondition(whereClauses,sqlParams,"date_determined_agent.agent_name",arguments.date_determined_by_agent,"date_determined_by_agent")>
		</cfif>
		<cfif structKeyExists(arguments,"geolocate_precision") and len(arguments.geolocate_precision) gt 0>
			<cfset arrayAppend(whereClauses,"lower(accepted_lat_long.geolocate_precision) = #addNamedQueryParam(sqlParams,'geolocate_precision',arguments.geolocate_precision,'CF_SQL_VARCHAR')#")>
		</cfif>
		<cfif structKeyExists(arguments,"geolocate_score") and len(arguments.geolocate_score) gt 0>
			<cfif ArrayLen(REMatch("^[0-9]+\-[0-9]+$",arguments.geolocate_score)) GT 0>
				<cfset bits = ListToArray(arguments.geolocate_score,"-")>
				<cfset arrayAppend(whereClauses,"accepted_lat_long.geolocate_score BETWEEN #addNamedQueryParam(sqlParams,'geolocate_score_start',bits[1],'CF_SQL_DECIMAL')# AND #addNamedQueryParam(sqlParams,'geolocate_score_end',bits[2],'CF_SQL_DECIMAL')#")>
			<cfelseif arguments.geolocate_score EQ 'NULL'>
				<cfset arrayAppend(whereClauses,"accepted_lat_long.geolocate_score IS NULL")>
			<cfelseif arguments.geolocate_score EQ 'NOT NULL'>
				<cfset arrayAppend(whereClauses,"accepted_lat_long.geolocate_score IS NOT NULL")>
			<cfelse>
				<cfswitch expression="#arguments.gs_comparator#">
					<cfcase value = "between">
						<cfset arrayAppend(whereClauses,"accepted_lat_long.geolocate_score BETWEEN #addNamedQueryParam(sqlParams,'geolocate_score_between_start',arguments.geolocate_score,'CF_SQL_DECIMAL')# AND #addNamedQueryParam(sqlParams,'geolocate_score_between_end',arguments.geolocate_score2,'CF_SQL_DECIMAL')#")>
					</cfcase>
					<cfcase value = ">"><cfset arrayAppend(whereClauses,"accepted_lat_long.geolocate_score > #addNamedQueryParam(sqlParams,'geolocate_score_gt',arguments.geolocate_score,'CF_SQL_DECIMAL')#")></cfcase>
					<cfcase value = "<"><cfset arrayAppend(whereClauses,"accepted_lat_long.geolocate_score < #addNamedQueryParam(sqlParams,'geolocate_score_lt',arguments.geolocate_score,'CF_SQL_DECIMAL')#")></cfcase>
					<cfcase value = "<>"><cfset arrayAppend(whereClauses,"accepted_lat_long.geolocate_score <> #addNamedQueryParam(sqlParams,'geolocate_score_ne',arguments.geolocate_score,'CF_SQL_DECIMAL')#")></cfcase>
					<cfdefaultcase><cfset arrayAppend(whereClauses,"accepted_lat_long.geolocate_score = #addNamedQueryParam(sqlParams,'geolocate_score_eq',arguments.geolocate_score,'CF_SQL_DECIMAL')#")></cfdefaultcase>
				</cfswitch>
			</cfif>
		</cfif>
		<cfif structKeyExists(arguments,"began_date") and len(arguments.began_date) gt 0>
			<cfswitch expression="#arguments.begDateOper#">
				<cfcase value = ">"><cfset arrayAppend(whereClauses,"collecting_event.began_date > #addNamedQueryParam(sqlParams,'began_date_gt',arguments.began_date,'CF_SQL_VARCHAR')#")></cfcase>
				<cfcase value = "<"><cfset arrayAppend(whereClauses,"collecting_event.began_date < #addNamedQueryParam(sqlParams,'began_date_lt',arguments.began_date,'CF_SQL_VARCHAR')#")></cfcase>
				<cfdefaultcase><cfset arrayAppend(whereClauses,"collecting_event.began_date = #addNamedQueryParam(sqlParams,'began_date_eq',arguments.began_date,'CF_SQL_VARCHAR')#")></cfdefaultcase>
			</cfswitch>
		</cfif>
		<cfif structKeyExists(arguments,"ended_date") and len(arguments.ended_date) gt 0>
			<cfswitch expression="#arguments.endDateOper#">
				<cfcase value = ">"><cfset arrayAppend(whereClauses,"collecting_event.ended_date > #addNamedQueryParam(sqlParams,'ended_date_gt',arguments.ended_date,'CF_SQL_VARCHAR')#")></cfcase>
				<cfcase value = "<"><cfset arrayAppend(whereClauses,"collecting_event.ended_date < #addNamedQueryParam(sqlParams,'ended_date_lt',arguments.ended_date,'CF_SQL_VARCHAR')#")></cfcase>
				<cfdefaultcase><cfset arrayAppend(whereClauses,"collecting_event.ended_date = #addNamedQueryParam(sqlParams,'ended_date_eq',arguments.ended_date,'CF_SQL_VARCHAR')#")></cfdefaultcase>
			</cfswitch>
		</cfif>

		<cfsavecontent variable="sqlText">
SELECT distinct
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
	<cfif arguments.return_wkt EQ "true">
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
	listagg(geology_attributes.geology_attribute || nvl2(geology_attributes.geology_attribute, ':', '') || geo_att_value,'; ') within group (order by geo_att_value) over (partition by collecting_event.collecting_event_id) geolAtts,
	<cfif includeCounts >
		MCZBASE.get_collcodes_for_locality(locality.locality_id) as collcountlocality,
	<cfelse>
		null as collcountlocality,
	</cfif>
	accepted_lat_long.LAT_LONG_ID,
	to_char(accepted_lat_long.dec_lat, '99' || rpad('.',nvl(accepted_lat_long.coordinate_precision,5) + 1, '0')) dec_lat,
	to_char(accepted_lat_long.dec_long, '999' || rpad('.',nvl(accepted_lat_long.coordinate_precision,5) + 1, '0')) dec_long,
	accepted_lat_long.datum,
	accepted_lat_long.max_error_distance,
	accepted_lat_long.max_error_units,
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
	collecting_event.fish_field_number,
	collecting_event.verbatim_collectors,
	collecting_event.verbatim_field_numbers,
	collecting_event.verbatim_habitat,
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
	<cfoutput>left join #flatTableName# flatTableName on collecting_event.collecting_event_id=flatTableName.collecting_event_id</cfoutput>
	left join accepted_lat_long on locality.locality_id = accepted_lat_long.locality_id
	left join preferred_agent_name georef_verified_agent on accepted_lat_long.verified_by_agent_id = georef_verified_agent.agent_id
	left join preferred_agent_name georef_determined_agent on accepted_lat_long.determined_by_agent_id = georef_determined_agent.agent_id
	left join preferred_agent_name date_determined_agent on collecting_event.date_determined_by_agent_id = date_determined_agent.agent_id
	left join geology_attributes on locality.locality_id = geology_attributes.locality_id
	left join ctgeology_attributes on geology_attributes.geology_attribute = ctgeology_attributes.geology_attribute
<cfoutput>WHERE #arrayToList(whereClauses,chr(10) & '	AND ')#</cfoutput>
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
	<cfif arguments.return_wkt EQ "true">
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
	to_char(accepted_lat_long.dec_lat, '99' || rpad('.',nvl(accepted_lat_long.coordinate_precision,5) + 1, '0')),
	to_char(accepted_lat_long.dec_long, '999' || rpad('.',nvl(accepted_lat_long.coordinate_precision,5) + 1, '0')),
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
	collecting_event.fish_field_number,
	collecting_event.verbatim_collectors,
	collecting_event.verbatim_field_numbers,
	collecting_event.verbatim_habitat,
	collecting_event.verbatimcoordinates,
	collecting_event.verbatimlatitude,
	collecting_event.verbatimlongitude,
	collecting_event.verbatimcoordinatesystem,
	collecting_event.verbatimsrs,
	collecting_event.coll_event_remarks,
	geo_att_value, geology_attributes.geology_attribute
ORDER BY
	geog_auth_rec.higher_geog,
	locality.spec_locality,
	locality.locality_id,
	collecting_event.began_date,
	collecting_event.ended_date
		</cfsavecontent>

		<cfset search = queryExecute(sqlText,sqlParams,{
			datasource="user_login",
			username=session.dbuser,
			password=decrypt(session.epw,cookie.cfid)
		})>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset columnNames = ListToArray(search.columnList)>
			<cfloop array="#columnNames#" index="columnName">
				<cfset row["#columnName#"] = "#search[columnName][currentrow]#">
			</cfloop>
			<cfset data[i] = row>
			<cfset i = i + 1>
		</cfloop>
		<cfif linguisticFlag >
			<cfset queryExecute("ALTER SESSION SET NLS_COMP = BINARY",{},{
				datasource="user_login",
				username=session.dbuser,
				password=decrypt(session.epw,cookie.cfid)
			})>
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


<!---
Function getCEFieldAutocomplete.  Search for distinct values of a particular field in the collecting event table
  by name with a substring match on name, returning json suitable for jquery-ui autocomplete.

@param term value of the field to search for.
@param field the field to search
@return a json structure containing id and value, and meta, with matching value in value and id, 
  and count metadata in meta.
--->
<cffunction name="getCEFieldAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfargument name="field" type="string" required="yes">
	<!--- perform wildcard search anywhere in field --->
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result">
			SELECT count(*) as ct,
				<cfswitch expression="#ucase(field)#">
					<cfcase value="VERBATIM_DATE">VERBATIM_DATE as name</cfcase>
					<cfcase value="VERBATIM_LOCALITY">VERBATIM_LOCALITY as name</cfcase>
					<cfcase value="COLL_EVENT_REMARKS">COLL_EVENT_REMARKS as name</cfcase>
					<cfcase value="COLLECTING_SOURCE">COLLECTING_SOURCE as name</cfcase>
					<cfcase value="COLLECTING_METHOD">COLLECTING_METHOD as name</cfcase>
					<cfcase value="HABITAT_DESC">HABITAT_DESC as name</cfcase>
					<cfcase value="FISH_FIELD_NUMBER">FISH_FIELD_NUMBER as name</cfcase>
					<cfcase value="BEGAN_DATE">BEGAN_DATE as name</cfcase>
					<cfcase value="ENDED_DATE">ENDED_DATE as name</cfcase>
					<cfcase value="COLLECTING_TIME">COLLECTING_TIME as name</cfcase>
					<cfcase value="VERBATIMCOORDINATES">VERBATIMCOORDINATES as name</cfcase>
					<cfcase value="VERBATIMLATITUDE">VERBATIMLATITUDE as name</cfcase>
					<cfcase value="VERBATIMLONGITUDE">VERBATIMLONGITUDE as name</cfcase>
					<cfcase value="VERBATIMCOORDINATESYSTEM">VERBATIMCOORDINATESYSTEM as name</cfcase>
					<cfcase value="VERBATIMSRS">VERBATIMSRS as name</cfcase>
					<cfcase value="STARTDAYOFYEAR">STARTDAYOFYEAR as name</cfcase>
					<cfcase value="ENDDAYOFYEAR">ENDDAYOFYEAR as name</cfcase>
					<cfcase value="VERBATIMELEVATION">VERBATIMELEVATION as name</cfcase>
					<cfcase value="VERBATIMDEPTH">VERBATIMDEPTH as name</cfcase>
				</cfswitch>
			FROM 
				collecting_event
			WHERE
				<cfswitch expression="#ucase(field)#">
					<cfcase value="VERBATIM_DATE">upper(VERBATIM_DATE)</cfcase>
					<cfcase value="VERBATIM_LOCALITY">upper(VERBATIM_LOCALITY)</cfcase>
					<cfcase value="COLL_EVENT_REMARKS">upper(COLL_EVENT_REMARKS)</cfcase>
					<cfcase value="COLLECTING_SOURCE">upper(COLLECTING_SOURCE)</cfcase>
					<cfcase value="COLLECTING_METHOD">upper(COLLECTING_METHOD)</cfcase>
					<cfcase value="HABITAT_DESC">upper(HABITAT_DESC)</cfcase>
					<cfcase value="FISH_FIELD_NUMBER">upper(FISH_FIELD_NUMBER)</cfcase>
					<cfcase value="BEGAN_DATE">upper(BEGAN_DATE)</cfcase>
					<cfcase value="ENDED_DATE">upper(ENDED_DATE)</cfcase>
					<cfcase value="COLLECTING_TIME">upper(COLLECTING_TIME)</cfcase>
					<cfcase value="VERBATIMCOORDINATES">upper(VERBATIMCOORDINATES)</cfcase>
					<cfcase value="VERBATIMLATITUDE">upper(VERBATIMLATITUDE)</cfcase>
					<cfcase value="VERBATIMLONGITUDE">upper(VERBATIMLONGITUDE)</cfcase>
					<cfcase value="VERBATIMCOORDINATESYSTEM">upper(VERBATIMCOORDINATESYSTEM)</cfcase>
					<cfcase value="VERBATIMSRS">upper(VERBATIMSRS)</cfcase>
					<cfcase value="STARTDAYOFYEAR">upper(STARTDAYOFYEAR)</cfcase>
					<cfcase value="ENDDAYOFYEAR">upper(ENDDAYOFYEAR)</cfcase>
					<cfcase value="VERBATIMELEVATION">upper(VERBATIMELEVATION)</cfcase>
					<cfcase value="VERBATIMDEPTH">upper(VERBATIMDEPTH)</cfcase>
				</cfswitch>
				like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
			GROUP BY 
				<cfswitch expression="#ucase(field)#">
					<cfcase value="VERBATIM_DATE">VERBATIM_DATE</cfcase>
					<cfcase value="VERBATIM_LOCALITY">VERBATIM_LOCALITY</cfcase>
					<cfcase value="COLL_EVENT_REMARKS">COLL_EVENT_REMARKS</cfcase>
					<cfcase value="COLLECTING_SOURCE">COLLECTING_SOURCE</cfcase>
					<cfcase value="COLLECTING_METHOD">COLLECTING_METHOD</cfcase>
					<cfcase value="HABITAT_DESC">HABITAT_DESC</cfcase>
					<cfcase value="FISH_FIELD_NUMBER">FISH_FIELD_NUMBER</cfcase>
					<cfcase value="BEGAN_DATE">BEGAN_DATE</cfcase>
					<cfcase value="ENDED_DATE">ENDED_DATE</cfcase>
					<cfcase value="COLLECTING_TIME">COLLECTING_TIME</cfcase>
					<cfcase value="VERBATIMCOORDINATES">VERBATIMCOORDINATES</cfcase>
					<cfcase value="VERBATIMLATITUDE">VERBATIMLATITUDE</cfcase>
					<cfcase value="VERBATIMLONGITUDE">VERBATIMLONGITUDE</cfcase>
					<cfcase value="VERBATIMCOORDINATESYSTEM">VERBATIMCOORDINATESYSTEM</cfcase>
					<cfcase value="VERBATIMSRS">VERBATIMSRS</cfcase>
					<cfcase value="STARTDAYOFYEAR">STARTDAYOFYEAR</cfcase>
					<cfcase value="ENDDAYOFYEAR">ENDDAYOFYEAR</cfcase>
					<cfcase value="VERBATIMELEVATION">VERBATIMELEVATION</cfcase>
					<cfcase value="VERBATIMDEPTH">VERBATIMDEPTH</cfcase>
				</cfswitch>
			ORDER BY 
				<cfswitch expression="#ucase(field)#">
					<cfcase value="VERBATIM_DATE">VERBATIM_DATE</cfcase>
					<cfcase value="VERBATIM_LOCALITY">VERBATIM_LOCALITY</cfcase>
					<cfcase value="COLL_EVENT_REMARKS">COLL_EVENT_REMARKS</cfcase>
					<cfcase value="COLLECTING_SOURCE">COLLECTING_SOURCE</cfcase>
					<cfcase value="COLLECTING_METHOD">COLLECTING_METHOD</cfcase>
					<cfcase value="HABITAT_DESC">HABITAT_DESC</cfcase>
					<cfcase value="FISH_FIELD_NUMBER">FISH_FIELD_NUMBER</cfcase>
					<cfcase value="BEGAN_DATE">BEGAN_DATE</cfcase>
					<cfcase value="ENDED_DATE">ENDED_DATE</cfcase>
					<cfcase value="COLLECTING_TIME">COLLECTING_TIME</cfcase>
					<cfcase value="VERBATIMCOORDINATES">VERBATIMCOORDINATES</cfcase>
					<cfcase value="VERBATIMLATITUDE">VERBATIMLATITUDE</cfcase>
					<cfcase value="VERBATIMLONGITUDE">VERBATIMLONGITUDE</cfcase>
					<cfcase value="VERBATIMCOORDINATESYSTEM">VERBATIMCOORDINATESYSTEM</cfcase>
					<cfcase value="VERBATIMSRS">VERBATIMSRS</cfcase>
					<cfcase value="STARTDAYOFYEAR">STARTDAYOFYEAR</cfcase>
					<cfcase value="ENDDAYOFYEAR">ENDDAYOFYEAR</cfcase>
					<cfcase value="VERBATIMELEVATION">VERBATIMELEVATION</cfcase>
					<cfcase value="VERBATIMDEPTH">VERBATIMDEPTH</cfcase>
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
Function suggestSovereignNation.  Search for sovereign_nation appropriate for a higher geography.

@param geog_auth_rec_id the higher geography for which to obtain the country.
@return a json structure containing id and value, with matching with matched sovereign_nation in value and id.
--->
<cffunction name="suggestSovereignNation" access="remote" returntype="any" returnformat="json">
	<cfargument name="geog_auth_rec_id" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result">
			SELECT 
				suggest_sov_nation_from_str(country) sovereign_nation
			FROM 
				geog_auth_rec
			WHERE
				geog_auth_rec_id =  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.sovereign_nation#">
			<cfset row["value"] = "#search.sovereign_nation#" >
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

<cffunction name="getLocalitySummary" returntype="string" access="remote" returnformat="plain">
	<cfargument name="locality_id" type="string" required="yes">
	
	<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_locality")>
		<cfset encumber = "">
	<cfelse> 
		<cfquery name="checkForEncumbrances" datasource="uam_god">
			SELECT encumbrance_action 
			FROM 
				collecting_event 
	 			join cataloged_item on collecting_event.collecting_event_id = cataloged_item.collecting_event_id 
	 			join coll_object_encumbrance on cataloged_item.collection_object_id = coll_object_encumbrance.collection_object_id
				join encumbrance on coll_object_encumbrance.encumbrance_id = encumbrance.encumbrance_id
			WHERE
				collecting_event.locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
		</cfquery>
		<cfset encumber = ValueList(checkForEncumbrances.encumbrance_action)>
		<!--- potentially relevant actions: mask collector, mask locality, mask original field number. --->
	</cfif>

	<cfset retval = "">
	<cfquery name="lookupLocality" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="lookupLocality_result">
		SELECT distinct
			locality.locality_id,
			spec_locality,
			curated_fg,
			sovereign_nation,
			minimum_elevation,
			maximum_elevation, 
			orig_elev_units,
			min_depth,
			max_Depth,
			depth_units,
			<cfif ListContains(encumber,'mask locality') GT 0 >
				'[Masked]' as plss,
			<cfelse>
				trim(upper(section_part) || ' ' || nvl2(section,'S','') || section ||  nvl2(township,' T',' ') || township || upper(township_direction) || nvl2(range,' R',' ') || range || upper(range_direction)) as plss,
			</cfif>
			listagg(geology_attributes.geology_attribute || nvl2(geology_attributes.geology_attribute, ':', '') || geo_att_value,'; ') within group (order by geo_att_value) over (partition by locality.locality_id) geolAtts,
			nogeorefbecause,
			locality_remarks,
			<cfif ListContains(encumber,'mask locality') GT 0 >
				'' as lat_long_id,
				'[Masked]' as dec_lat,
				'[Masked]' as dec_long,
			<cfelse>
	  			accepted_lat_long.LAT_LONG_ID,
				to_char(accepted_lat_long.dec_lat, '99' || rpad('.',nvl(accepted_lat_long.coordinate_precision,5) + 1, '0')) dec_lat,
				to_char(accepted_lat_long.dec_long, '999' || rpad('.',nvl(accepted_lat_long.coordinate_precision,5) + 1, '0')) dec_long,
			</cfif>
			accepted_lat_long.datum,
			accepted_lat_long.max_error_distance,
			accepted_lat_long.max_error_units,
			to_meters(accepted_lat_long.max_error_distance, accepted_lat_long.max_error_units) coordinateUncertaintyInMeters,
			accepted_lat_long.extent,
			accepted_lat_long.verificationstatus,
			accepted_lat_long.georefmethod
		FROM
			locality
			left join accepted_lat_long on locality.locality_id = accepted_lat_long.locality_id
			left join geology_attributes on locality.locality_id = geology_attributes.locality_id 
			left join ctgeology_attributes on geology_attributes.geology_attribute = ctgeology_attributes.geology_attribute
		WHERE
			locality.locality_id in (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#" list="Yes" >)
	</cfquery>
	<cfloop query="lookupLocality">
		<cfset id = lookupLocality.locality_id>
		<cfif len(locality_remarks) GT 0>
			<cfset remarks = ". Remarks: #locality_remarks# ">
		<cfelse>
			<cfset remarks = "">
		</cfif>
		<cfif curated_fg EQ "1"><cfset curated = "*"><cfelse><cfset curated = ""></cfif>
		<cfif len(minimum_elevation) GT 0> 
			<cfset elevation = " Elev: #minimum_elevation#">
			<cfif len(maximum_elevation) GT 0 AND maximum_elevation NEQ minimum_elevation>
				<cfset elevation = "#elevation#-#maximum_elevation# #orig_elev_units#. ">
			<cfelse>
				<cfset elevation = trim("#elevation# #orig_elev_units#. ")>
			</cfif>
		<cfelse>
			<cfset elevation = "">
		</cfif>
		<cfset depthval = "">
		<cfif len(min_depth) GT 0> 
			<cfset depthval = " Depth: #min_depth#">
			<cfif len(max_depth) GT 0 AND max_depth NEQ min_depth>
				<cfset depthval = "#depthval#-#max_depth# #depth_units#.">
			<cfelse>
				<cfset depthval = "#depthval# #depth_units#. ">
			</cfif>
		</cfif>
		<cfif len(dec_lat) GT 0>
			<cfset coordinates = " Georeference: #dec_lat#&##176;, #dec_long#&##176; <span class='sr-only'>Datum </span>#datum# <span class='sr-only'>Point-Radius Uncertainty </span>±#max_error_distance# #max_error_units# #verificationstatus#"><!--- " --->
			<cfif right(verificationstatus,1) NEQ "."><cfset coordinates="#coordinates#. "><cfelse><cfset coordinates="#coordinates# "></cfif>
		<cfelse> 
			<cfset coordinates = " Not Georeferenced: #nogeorefbecause#">
			<cfif right(nogeorefbecause,1) NEQ "."><cfset coordinates="#coordinates#. "><cfelse><cfset coordinates="#coordinates# "></cfif>
		</cfif>
		<cfif len(sovereign_nation) GT 0>
			<cfset sovereignNation = " Sovereign Nation: #sovereign_nation#. ">
		</cfif>
		<cfif len(geolatts) GT 0><cfset geology = " [#geolatts#] "><cfelse><cfset geology = ""></cfif>
		<cfif len(trim(plss)) GT 0><cfset plss = " #plss# "></cfif>
		<cfif right(spec_locality,1) EQ "."><cfset spec_locality_display = " #spec_locality# "><cfelse><cfset spec_locality_display="#spec_locality#."></cfif>
		<cfset retval = trim("#retval# #spec_locality_display##geology##elevation##depthval##sovereignNation##plss##coordinates##remarks# (#id#) #curated#")>
		<cfset retval = replace(retval,"  "," ","All")>
	</cfloop>
	<cfreturn retval>
</cffunction>

<!--- getHigherTermsForCounty given a county name, if that county name is unique to a combination of 
  continent_ocean, country, and state_prov, return that unique combination.
 @param county the county to search for.
 @return a json array containing an object with properties continent_ocean, country, and state_prov if there is a match, otherwise
  an empty json array, or an http 500 on an error.
--->
<cffunction name="getHigherTermsForCounty" access="remote" returntype="any" returnformat="json">
	<cfargument name="county" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result">
			SELECT 
				distinct 
				continent_ocean, country, state_prov
			FROM 
				geog_auth_rec
			WHERE
				county = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#county#">
				and
				continent_ocean NOT like '% Ocean%'
		</cfquery>
		<cfif search.recordcount EQ 1>
			<cfset i = 1>
			<cfloop query="search">
				<cfset row = StructNew()>
				<cfset row["continent_ocean"] = "#search.continent_ocean#">
				<cfset row["country"] = "#search.country#">
				<cfset row["state_prov"] = "#search.state_prov#" >
				<cfset data[i]  = row>
				<cfset i = i + 1>
			</cfloop>
		</cfif>
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

<!--- getHigherTermsForStateProv given a state_prov name, if that state_prov name is unique to a combination of 
  continent_ocean, and country return that unique combination.
 @param state_prov the state_prov to search for.
 @return a json array containing an object with properties continent_ocean and country if there is a match, otherwise
  an empty json array, or an http 500 on an error.
--->
<cffunction name="getHigherTermsForStateProv" access="remote" returntype="any" returnformat="json">
	<cfargument name="state_prov" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result">
			SELECT 
				distinct 
				continent_ocean, country
			FROM 
				geog_auth_rec
			WHERE
				state_prov = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#state_prov#">
				and
				continent_ocean NOT like '% Ocean%'
		</cfquery>
		<cfif search.recordcount EQ 1>
			<cfset i = 1>
			<cfloop query="search">
				<cfset row = StructNew()>
				<cfset row["continent_ocean"] = "#search.continent_ocean#">
				<cfset row["country"] = "#search.country#">
				<cfset data[i]  = row>
				<cfset i = i + 1>
			</cfloop>
		</cfif>
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

<!--- getHigherTermsForOceanSubregion given a ocean_subregion name, if that ocean_subregion name is unique to a combination of 
  continent_ocean, and ocean_region, return that unique combination.
 @param ocean_subregion the ocean_subregion to search for.
 @return a json array containing an object with properties continent_ocean, country, and state_prov if there is a match, otherwise
  an empty json array, or an http 500 on an error.
--->
<cffunction name="getHigherTermsForOceanSubregion" access="remote" returntype="any" returnformat="json">
	<cfargument name="ocean_subregion" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result">
			SELECT 
				distinct 
				continent_ocean, ocean_region
			FROM 
				geog_auth_rec
			WHERE
				ocean_subregion = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ocean_subregion#">
		</cfquery>
		<cfif search.recordcount EQ 1>
			<cfset i = 1>
			<cfloop query="search">
				<cfset row = StructNew()>
				<cfset row["continent_ocean"] = "#search.continent_ocean#">
				<cfset row["country"] = "#search.ocean_region#">
				<cfset data[i]  = row>
				<cfset i = i + 1>
			</cfloop>
		</cfif>
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

</cfcomponent>
