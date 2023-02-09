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

<!---
Function getSpecLocalityAutocomplete.  Search for spec_locality by name with a substring match on name, returning json suitable for jquery-ui autocomplete.

@param term spec_locality name to search for.
@return a json structure containing id and value, with matching with matched name in value and id.
--->
<cffunction name="getSpecLocalityAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<!--- perform wildcard search anywhere in taxonomy.phylum --->
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
	<!--- perform wildcard search anywhere in taxonomy.phylum --->
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

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				geog_auth_rec_id,
				continent_ocean,
				country,
				state_prov,
				county,
				quad,
				feature,
				island,
				island_group,
				sea,
				valid_catalog_term_fg,
				source_authority,
				higher_geog,
				ocean_region,
				ocean_subregion,
				water_feature,
				wkt_polygon,
				highergeographyid_guid_type,
				highergeographyid 
			FROM 
				geog_auth_rec
			WHERE
				geog_auth_rec_id is not null
				<cfif isDefined("higher_geog") and len(higher_geog) gt 0>
					and higher_geog like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#higher_geog#%">
				</cfif>
			ORDER BY
				higher_geography
		</cfquery>
<!---
	?higher_geog=&geog_auth_rec_id=&continent_ocean=&ocean_region=&ocean_subregion=&sea=&island=&island_group=&feature=&water_feature=&country=&state_prov=&county==Middlesex&quad=
--->
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

</cfcomponent>
