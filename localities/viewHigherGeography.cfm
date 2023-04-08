<cfset pageTitle = "Higher Geography Details">
<!--
localities/viewHigherGeography.cfm

Form for displaying higher geography details

Copyright 2023 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

-->

<cfif NOT isdefined("geog_auth_rec_id")>
	<cfthrow message="No higher geography specified.">
</cfif>
<cfinclude template = "/shared/_header.cfm">
<cfquery name="getGeography" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
		geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geog_auth_rec_id#">
</cfquery>
<cfquery name="points" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="points_result" cachedwithin="#CreateTimespan(24,0,0,0)#">
	SELECT distinct flat.locality_id,flat.dec_lat as Latitude,flat.DEC_LONG as Longitude 
	FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat
	WHERE 
		flat.geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
</cfquery>

<cfoutput>
	<main class="container-xl px-0" id="content">
		<div class="row mx-0">
			<cfloop query="getGeography">
				<h1 class="h2">#higher_geog#</h2>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_geography")>
					<a href="/Locality.cfm?action=editGeog&geog_auth_rec_id=#geog_auth_rec_id#" class="btn btn-primary btn-xs float-right">Edit</a>
				</cfif>
				<ul>
					<li>Continent/Ocean: #continent_ocean#</li>
				</ul>		
			</cfloop>
		</div>
	</main>
</cfoutput>
