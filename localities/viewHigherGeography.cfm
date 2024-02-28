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
<cfinclude template = "/localities/component/search.cfc" runOnce="true"><!--- for getLocalitySummary() --->
<cfinclude template = "/shared/component/functions.cfc" runOnce="true"><!--- for getGuidLink() --->
<cfinclude template = "/localities/component/public.cfc" runOnce="true"><!--- for  getHigherGeographyMapHtml() --->

<cfset editLocalityLinkTarget = "/localities/Locality.cfm?locality_id=">

<cfquery name="getGeography" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
		geog_auth_rec.wkt_polygon,
		geog_auth_rec.highergeographyid_guid_type,
		geog_auth_rec.highergeographyid
	FROM 
		geog_auth_rec
	WHERE
		geog_auth_rec.geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geog_auth_rec_id#">
</cfquery>
<cfquery name="getSpecimenCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT 
		count(distinct collection_object_id) ct
	FROM 
		<cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
	WHERE
		geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geog_auth_rec_id#">
	GROUP BY
		geog_auth_rec_id
</cfquery>
<cfset specimenCount = getSpecimenCount.ct>
<cfquery name="getLocalities" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getLocalities_result">
	SELECT
		locality_id,
		spec_locality,
		sovereign_nation,
		curated_fg,
		decode(curated_fg,0,'',1,'*','') curated
	FROM
		locality
	WHERE
		geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geog_auth_rec_id#">
	ORDER BY
		spec_locality
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
		AND
		geog_auth_rec.geog_auth_rec_id <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geog_auth_rec_id#">
	GROUP BY 
		geog_auth_rec.higher_geog, 
		geog_auth_rec.geog_auth_rec_id
	ORDER BY
		geog_auth_rec.higher_geog
</cfquery>
<cfset parentage = getGeography.higher_geog>
<cfset parent = "">
<cfif ListLen(parentage,':') GT 1>
  <cfset parent = ListDeleteAt(parentage,ListLen(parentage,':'),':')>
</cfif>
<cfif len(parent) GT 0>
	<cfquery name="getParent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getParent_result">
		SELECT
			geog_auth_rec_id,
			higher_geog
		FROM
			geog_auth_rec
		WHERE
			higher_geog = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#parent#">
	</cfquery>
</cfif>
<cfquery name="points" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="points_result" cachedwithin="#CreateTimespan(1,0,0,0)#">
	SELECT distinct flat.locality_id,flat.dec_lat as Latitude,flat.DEC_LONG as Longitude 
	FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat
	WHERE 
		flat.geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
</cfquery>
<cfoutput>
	<main class="container-xl " id="content">
		<div class="row mx-0">
			<cfloop query="getGeography">
				<div class="col-12 pt-2 mt-4 pb-2 border-bottom border-dark">
					<h1 class="h2 mr-2 mb-0 col-10 px-0 float-left">#getGeography.higher_geog#</h1>
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_geography")>
						<a role="button" href="/localities/HigherGeography.cfm?geog_auth_rec_id=#getGeography.geog_auth_rec_id#" class="btn btn-primary btn-xs mr-1 float-right">Edit Higher Geography</a>
					</cfif>
				</div>
			</cfloop>
			<div class="col-12 col-md-6 pr-md-0 py-2">
				<cfloop query="getGeography">
					<div class="col-12 px-0 pb-1">
						<ul class="list-unstyled sd small95 row mx-0 px-0 py-1 mb-0">
							<cfif len(valid_catalog_term_fg) EQ 1><cfset valid="*"><cfelse><cfset valid=""></cfif>
							<cfif len(getGeography.continent_ocean) gt 0>
								<cfif find('Ocean',getGeography.continent_ocean) GT 0><cfset colabel="Ocean"><cfelse><cfset colabel="Continent"></cfif>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">#colabel#:</li>
								<li class="list-group-item col-7 col-xl-8 px-0">#getGeography.continent_ocean#</li>
							</cfif>
							<cfif len(getGeography.ocean_region) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Ocean Region:</li>
								<li class="list-group-item col-7 col-xl-8 px-0">#getGeography.ocean_region#</li>
							</cfif>
							<cfif len(getGeography.ocean_subregion) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Ocean Subregion:</li>
								<li class="list-group-item col-7 col-xl-8 px-0">#getGeography.ocean_subregion#</li>
							</cfif>
							<cfif len(getGeography.sea) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Sea:</li>
								<li class="list-group-item col-7 col-xl-8 px-0">#getGeography.sea#</li>
							</cfif>
							<cfif len(getGeography.water_feature) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Water Feature:</li>
								<li class="list-group-item col-7 col-xl-8 px-0">#getGeography.water_feature#</li>
							</cfif>
							<cfif len(getGeography.country) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Country:</li>
								<li class="list-group-item col-7 col-xl-8 px-0">#getGeography.country#</li>
							</cfif>
							<cfif len(getGeography.state_prov) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">State/Province:</li>
								<li class="list-group-item col-7 col-xl-8 px-0">#getGeography.state_prov#</li>
							</cfif>
							<cfif len(getGeography.feature) gt 0>
								<li class="list-group-item col-5 col-xl-4 col-xl-4 px-0 font-weight-lessbold">Feature:</li>
								<li class="list-group-item col-7 col-xl-8 px-0">#getGeography.feature#</li>
							</cfif>
							<cfif len(getGeography.county) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">County:</li>
								<li class="list-group-item col-7 col-xl-8 px-0">#getGeography.county#</li>
							</cfif>
							<cfif len(getGeography.island_group) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Island Group:</li>
								<li class="list-group-item col-7 col-xl-8 px-0">#getGeography.island_group#</li>
							</cfif>
							<cfif len(getGeography.island) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Island:</li>
								<li class="list-group-item col-7 col-xl-8 px-0">#getGeography.island#</li>
							</cfif>
							<cfif len(getGeography.quad) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Quad:</li>
								<li class="list-group-item col-7 col-xl-8 px-0">#getGeography.quad#</li>
							</cfif>
							<cfif len(wkt_polygon) GT 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Has Spatial Representation:</li>
								<li class="list-group-item col-7 col-xl-8 px-0"><a onclick=" map.fitBounds(findBounds(enclosingpoly.latLngs));">Zoom to on map</a></li>
							</cfif>
							<cfif len(source_authority) GT 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Source Authority:</li>
								<li class="list-group-item col-7 col-xl-8 px-0">#source_authority#</li>
							</cfif>
							<cfif len(getGeography.highergeographyid) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">dwc:highergeographyID:</li>
								<cfset geogLink = getGuidLink(guid=#getGeography.highergeographyid#,guid_type=#getGeography.highergeographyid_guid_type#)>
								<li class="list-group-item col-7 col-xl-8 px-0">
									#getGeography.highergeographyid# #geogLink#
								</li>
							</cfif>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Cataloged Items:</li>
							<li class="list-group-item col-7 col-xl-8 px-0">
								<cfif specimenCount GT 0>
									<a href="/Specimens.cfm?execute=true&action=fixedSearch&current_id_only=any&higher_geog=%3D#encodeForUrl(higher_geog)#">#specimenCount#</a>
								<cfelse>
									None.
								</cfif>
							</li>
						</ul>		
					</div>
				</cfloop>
				<h2 class="h3 mt-2">Localities (<a href="/localities/Localities.cfm?action=search&execute=true&method=getLocalities&geog_auth_rec_id=#geog_auth_rec_id#">#getLocalities.recordcount#</a>)</h2>
				<div class="col-12">
					<ul class="px-4 small95">
						<cfif getLocalities.recordcount LT 11>
							<cfloop query="getLocalities">
								<li>
									<cfset summary = getLocalitySummary(locality_id="#getLocalities.locality_id#")>
									<a href="#editLocalityLinkTarget##getLocalities.locality_id#">#getLocalities.spec_locality#</a> #summary# 
								</li>
							</cfloop>
						<cfelse>
							<cfquery name="getLocSummary" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getLocSummary_result">
								SELECT
									count(locality.locality_id) ct,
									count(accepted_lat_long.locality_id) georef_ct,
									curated_fg
								FROM
									locality
									left join accepted_lat_long on locality.locality_id = accepted_lat_long.locality_id
								WHERE
									geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geog_auth_rec_id#">
								GROUP BY
									curated_fg
							</cfquery>
							<cfloop query="getLocSummary">
								<cfif curated_fg EQ "1"><cfset curated="Vetted (*)"><cfelse><cfset curated="Not Vetted"></cfif>
								<li>#curated# #getLocSummary.ct# localities, #getLocSummary.georef_ct# with georeferences.</li> 
							</cfloop>
						</cfif>
					</ul>
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_locality")>
						<a class="btn btn-xs btn-secondary" href="/localities/Locality.cfm?action=new&geog_auth_rec_id=#encodeForUrl(geog_auth_rec_id)#">Add</a>
					</cfif>
				</div>
				<cfif len(parent) GT 0>
					<h2 class="h3">Contained in Geography</h2>
					<div class="col-12">
						<ul class="px-4 small95">
							<cfloop query="getParent">
								<li>
									<a href="/localities/viewHigherGeography.cfm?geog_auth_rec_id=#getParent.geog_auth_rec_id#">#getParent.higher_geog#</a> 
								</li>
							</cfloop>
						</ul>
					</div>
				</cfif>
				<h2 class="h3">Contained Geographies (#getChildren.recordcount#)</h2>
				<div class="col-12">
					<ul class="px-4 small95">
						<cfif getChildren.recordcount EQ 0>
							<li>None</li>
						</cfif>
						<cfloop query="getChildren">
							<li>
								<a href="/localities/viewHigherGeography.cfm?geog_auth_rec_id=#getChildren.geog_auth_rec_id#">#getChildren.higher_geog#</a> 
								<cfif getChildren.ct GT 0>
									(<a href="/Specimens.cfm?execute=true&action=fixedSearch&current_id_only=any&higher_geog=%3D#encodeForUrl(getChildren.higher_geog)#">#getChildren.ct#</a> cataloged items)
								</cfif>
							</li>
						</cfloop>
					</ul>
				</div>
			</div>
			<div class="col-12 col-md-6 pt-2">
				<cfset map = getHigherGeographyMapHtml(geog_auth_rec_id="#geog_auth_rec_id#")>
				<div id="mapDiv">#map#</div>
			</div>
		</div>
	</main>
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
