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
<cfquery name="points" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="points_result" cachedwithin="#CreateTimespan(1,0,0,0)#">
	SELECT distinct flat.locality_id,flat.dec_lat as Latitude,flat.DEC_LONG as Longitude 
	FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat
	WHERE 
		flat.geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
</cfquery>
<cfoutput>
	<main class="container-xl px-0" id="content">
		<div class="row mx-0">
			<div class="col-12 col-md-8 row">
				<cfloop query="getGeography">
					<h1 class="h2">#getGeography.higher_geog#</h1>
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_geography")>
							<a href="/Locality.cfm?action=editGeog&geog_auth_rec_id=#geog_auth_rec_id#" class="btn btn-primary btn-xs float-right">Edit</a>
					</cfif>
					<div class="col-12">
						<ul>
							<li>Continent/Ocean: #continent_ocean#</li>
							<li>Cataloged Items: <a href="/Specimens.cfm?execute=true&action=fixedSearch&current_id_only=any&higher_geog=%3D#encodeForUrl(higher_geog)#">#specimenCount#</a></li>
						</ul>		
					</div>
				</cfloop>
				<h2 class="h3">Localities (<a href="https://mczbase-test.rc.fas.harvard.edu/localities/Localities.cfm?action=search&execute=true&method=getLocalities&geog_auth_rec_id=#geog_auth_rec_id#">#getLocalities.recordcount#</a>)</h2>
				<div class="col-12">
					<ul>
						<cfif getLocalities.recordcount LT 11>
							<cfloop query="getLocalities">
								<li>
									<cfset summary = getLocalitySummary(locality_id="#getLocalities.locality_id#")>
									<a href="/localities/Locality.cfm?locality_id=#getLocalities.locality_id#">#getLocalities.spec_locality#</a> #summary# 
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
				</div>
				<h2 class="h3">Contained Geographies (#getChildren.recordcount#)</h2>
				<div class="col-12">
					<cfloop query="getChildren">
						<ul>
							<li>
								<a href="/localities/viewHigherGeography.cfm?geog_auth_rec_id=#getChildren.geog_auth_rec_id#">#getChildren.higher_geog#</a> 
								<cfif getChildren.ct GT 0>
									(<a href="/Specimens.cfm?execute=true&action=fixedSearch&current_id_only=any&higher_geog=%3D#encodeForUrl(getChildren.higher_geog)#">#getChildren.ct#</a> cataloged items)
								</cfif>
							</li>
						</ul>
					</cfloop>
				</div>
			</div>
			<div class="col-12 col-md-4 pt-5">
				<!--- map --->
				<script src="#Application.protocol#://maps.googleapis.com/maps/api/js?key=#application.gmap_api_key#&libraries=geometry" type="text/javascript">
				</script>
				<script>
					function findBounds(latLongs) { 
						var bounds = new google.maps.LatLngBounds();
						latLongs.getArray().forEach(function(path){ 
							path.getArray().forEach(function(latlong){ 
								bounds.extend(latlong)
							});
						}); 
						return bounds;
					} 
					var map;
					var enclosingpoly;
					var georefs;
					function setupMap(geog_auth_rec_id){
						var coords="0.0,0.0";
						var bounds = new google.maps.LatLngBounds();
						var polygonArray = [];
						var ptsArray=[];
						var lat=coords.split(',')[0];
						var lng=coords.split(',')[1];

						// start with world map
						var mapOptions = {
							zoom: 1,
							center: new google.maps.LatLng(0, 0),
							mapTypeId: google.maps.MapTypeId.ROADMAP,
							panControl: false,
							scaleControl: true,
							fullscreenControl: true,
							zoomControl: true
						};
						map = new google.maps.Map(document.getElementById("mapdiv_" + geog_auth_rec_id), mapOptions);

						// obtain georeferences 
						$.getJSON("/localities/component/georefUtilities.cfc",
	      				{
								method : "getLocalityGeorefsGeoJSON",
								geog_auth_rec_id: #geog_auth_rec_id#,
								returnformat : "json"
							},
							function (result) {
								console.log(result);
								if (result) {
									map.data.addGeoJson(result, { idPropertyName: "id" } );
									map.data.setStyle(function(feature) {
										var accepted = feature.getProperty('accepted');
										var determiner = feature.getProperty('determiner');
										var loc = feature.getProperty('spec_locality');
										var opacity = 1.0;
										var title = '';
										if (accepted=='Yes') { 
											label = '';
											zindex = 15;
											opacity = 1.0;
											title='Accepted.'
										} else {
											label = { text: 'n' };
											icon = '/shared/images/map_pin_grey.png';
											opacity = 0.6;
											zindex = 3;
											title='Not Accepted.'
										}
										title = title + ' ' + loc + ' ' +  ' Determiner: ' + determiner;
										if (accepted=='Yes') { 
											return {
												zIndex: zindex,
												opacity: opacity,
												label: label,
												title: title
											};
										} else {
											return {
												zIndex: zindex,
												opacity: opacity,
												label: label,
												icon: icon,
												title: title
											};
										} 
									});
								}
							}
						).fail(function(jqXHR,textStatus,error){
							handleFail(jqXHR,textStatus,error,"looking up georeferences for localities in higher geography");
						});

						// Polygon for higher geography
						$.get( "/localities/component/georefUtilities.cfc?returnformat=plain&method=getGeographyWKT&geog_auth_rec_id=" + #geog_auth_rec_id#, function( wkt ) {
							if (wkt.length>0){
								var regex = /\(([^()]+)\)/g;
								var Rings = [];
								var results;
								while( results = regex.exec(wkt) ) {
									Rings.push( results[1] );
								}
								for(var i=0;i<Rings.length;i++){
									// for every polygon in the WKT, create an array
									var lary=[];
									var da=Rings[i].split(",");
									for(var j=0;j<da.length;j++){
										// push the coordinate pairs to the array as LatLngs
										var xy = da[j].trim().split(" ");
										var pt=new google.maps.LatLng(xy[1],xy[0]);
										lary.push(pt);
										// console.log(lary);
										bounds.extend(pt);
									}
									// now push the single-polygon array to the array of arrays (of polygons)
									ptsArray.push(lary);
								}
								enclosingpoly = new google.maps.Polygon({
									paths: ptsArray,
									strokeColor: '##1E90FF',
									strokeOpacity: 0.8,
									strokeWeight: 2,
									fillColor: '##1E90FF',
									fillOpacity: 0.25
								});
								enclosingpoly.setMap(map);
								polygonArray.push(enclosingpoly);
							} else {
								$("##mapdiv_" + geog_auth_rec_id).addClass('noWKT');
							}
							if (bounds.getNorthEast().equals(bounds.getSouthWest())) {
								var extendPoint1 = new google.maps.LatLng(bounds.getNorthEast().lat() + 0.05, bounds.getNorthEast().lng() + 0.05);
								var extendPoint2 = new google.maps.LatLng(bounds.getNorthEast().lat() - 0.05, bounds.getNorthEast().lng() - 0.05);
								bounds.extend(extendPoint1);
								bounds.extend(extendPoint2);
							}
							map.fitBounds(bounds);
							for(var a=0; a<polygonArray.length; a++){
								if (! google.maps.geometry.poly.containsLocation(center, polygonArray[a]) ) {
									$("##mapdiv_" + geog_auth_rec_id).addClass('uglyGeoSPatData');
								} else {
									$("##mapdiv_" + geog_auth_rec_id).addClass('niceGeoSPatData');
								}
							}
						});
						map.fitBounds(bounds);
					};
					$(document).ready(function() {
						setupMap(#geog_auth_rec_id#);
					});
				</script>
			   <div class="mb-2" style="height: 350px;width: 350px;">
					<div id="mapdiv_#geog_auth_rec_id#" style="width:100%; height:100%;"></div>
				</div>
				<ul>
					<cfquery name="hasHigherPolygon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
						SELECT count(*) ct 
						FROM 
							geog_auth_rec 
						WHERE
							wkt_polygon is not null
							AND geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
					</cfquery>
					<li>
						<cfif hasHigherPolygon.ct GT 0>
							<span class="h3">Higher Geography mappable</span> <a onclick=" enclosingpoly.setVisible(!enclosingpoly.getVisible()); ">hide/show</a> <a onclick=" map.fitBounds(findBounds(enclosingpoly.latLngs));">zoom to</a>
						<cfelse>
							<span class="h3">Higher geography not mappable</span>
						</cfif>
					</li>
				</ul>
			</div>
		</div>
	</main>
</cfoutput>
