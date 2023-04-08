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
		count(flatTableName.collection_object_id) ct,
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
		geog_auth_rec.highergeographyid_guid_type,
		geog_auth_rec.highergeographyid
	FROM 
		geog_auth_rec
		left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
			on geog_auth_rec.geog_auth_rec_id = flatTableName.geog_auth_rec_id
	WHERE
		geog_auth_rec.geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geog_auth_rec_id#">
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
		geog_auth_rec.highergeographyid_guid_type,
		geog_auth_rec.highergeographyid
</cfquery>
<cfquery name="getSpatial" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT 
		geog_auth_rec.wkt_polygon
	FROM 
		geog_auth_rec
	WHERE
		geog_auth_rec.geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geog_auth_rec_id#">
</cfquery>
<cfquery name="getChildren" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getChildren_result">
	SELECT
		count(flatTableName.collection_object_id) ct,
		geog_auth_rec.higher_geog, 
		geog_auth_rec.geog_auth_rec_id
	FROM
		geog_auth_rec
		left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
			on geog_auth_rec.geog_auth_rec_id = flatTableName.geog_auth_rec_id
	WHERE 
		geog_auth_rec.higher_geog like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getGeography.higher_geog#%">
	GROUP BY 
		geog_auth_rec.higher_geog, 
		geog_auth_rec.geog_auth_rec_id
	ORDER BY
		geog_auth_rec.higher_geog
</cfquery>
<cfquery name="points" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="points_result" cachedwithin="#CreateTimespan(1,0,0,0)#">
	SELECT distinct flat.locality_id,flat.dec_lat as Latitude,flat.DEC_LONG as Longitude 
	FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat
	WHERE 
		flat.geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
</cfquery>
<cfoutput>
	<main class="container-xl px-0" id="content">
		<div class="row mx-0">
			<cfloop query="getGeography">
				<h1 class="h2">#higher_geog#</h1>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_geography")>
						<a href="/Locality.cfm?action=editGeog&geog_auth_rec_id=#geog_auth_rec_id#" class="btn btn-primary btn-xs float-right">Edit</a>
				</cfif>
				<div class="col-12">
					<ul>
						<li>Continent/Ocean: #continent_ocean#</li>
						<li>Cataloged Items: #ct#</li>
					</ul>		
				</div>
			</cfloop>
			<h2 class="h3">#higher_geog#</h2>
			<div class="col-12">
				<cfloop query="getChildren">
					<ul>
							<li><a href="/localities/viewHigherGeography.cfm?geog_auth_rec_id=#getChildren.geog_auth_rec_id#">#getChildren.higher_geog#</a> (#getChildren.ct# cataloged items)</li>
					</ul>
				</cfloop>
			</div>
		</div>
	</main>
</cfoutput>
