<!---
localities/component/public.cfc

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

--->
<cfcomponent>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">
<cfinclude template="/media/component/public.cfc" runOnce="true"><!--- for getMediaBlockHtmlUnthreaded --->
<cfinclude template = "/localities/component/search.cfc" runOnce="true"><!--- for getLocalitySummary() --->
<cf_rolecheck>

<cffunction name="getHigherGeographyMapHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="geog_auth_rec_id" type="string" required="yes">
	<cfargument name="reload" type="string" required="no">
	
	<!--- TODO: Check for encumbrances --->

	<cfset variables.geog_auth_rec_id = arguments.geog_auth_rec_id>
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="geogMapThread#tn#">
		<cfoutput>
			<cftry>
				<cfset editLocalityLinkTarget = "/localities/Locality.cfm?locality_id=">
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
					var enclosingpoly; // a polygon for the higher geography
					var georefsArray = [];  // list of georeferenced localities to check against polygonArray when both are loaded.
					var georefsBounds = new google.maps.LatLngBounds();
					var higherLoaded = false;
					var georefsLoaded = false;
					var polygonArray = [];  // the set of polygons for the higher geography
					function setupMap(geog_auth_rec_id){
						var coords="0.0,0.0";
						var bounds = new google.maps.LatLngBounds();
						var ptsArray=[];
						var lat=coords.split(',')[0];
						var lng=coords.split(',')[1];
						var center = new google.maps.LatLng(0, 0);

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
										title = title + ' ' + loc + ' ' + ' Determiner: ' + determiner;
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
									// fit the map bounds to the loaded features
									// and add the loaded feature to the list of georeferences
									var gbounds = new google.maps.LatLngBounds(); 
									map.data.forEach(function(feature){
										feature.getGeometry().forEachLatLng(function(latlng){
											gbounds.extend(latlng);
											georefsArray.push(latlng);
										});
									});
									map.fitBounds(gbounds.union(bounds));
									georefsBounds = gbounds;
									center = map.getCenter();
									map.data.addListener('click',
										function(event) { 
											var f = event.feature;
											var id = f.getProperty("id");
											var locality_id = f.getProperty("locality_id");
											var spec_locality = f.getProperty("spec_locality");
											if (!spec_locality) { spec_locality = "[no specific locality text]"; } 
											var contentText = "<a href='#editLocalityLinkTarget#"+locality_id+"' target='_blank'>" + spec_locality + "</a> (" + locality_id + ")."
											$("##selectedMarkerDiv").html("Click on a marker for details: " + contentText + "");
											var infoWindow = new google.maps.InfoWindow({
												content: contentText,
												ariaLabel: spec_locality
											});
											map.data.getFeatureById(id).getGeometry().forEachLatLng(function(ll){ infoWindow.setPosition(ll);});
											infoWindow.open({ map: map, shouldFocus: true },);
										}
									); 
									georefsLoaded = true;
									postLoadCheck(geog_auth_rec_id);
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
							map.fitBounds(bounds.union(georefsBounds));
							higherLoaded = true;
							postLoadCheck(geog_auth_rec_id);
						});
						map.fitBounds(bounds.union(georefsBounds));
					};
					function postLoadCheck(geog_auth_rec_id) { 
						if (georefsLoaded && higherLoaded && georefsArray.length>0) { 
							var hasProblem = false;
							for(var a=0; a<polygonArray.length; a++){
								for (var b=0; b<georefsArray.length; b++) { 
									if (! google.maps.geometry.poly.containsLocation(georefsArray[b], polygonArray[a]) ) {
										hasProblem = true;
									}
								}
							}
							if (hasProblem) { 
								$("##mapdiv_" + geog_auth_rec_id).addClass('uglyGeoSPatData');
								$("##mapMetadataUL").append("<li class='list-style-circle'>Georeferences for localities in this higher geography fall outside of it. </li>");
							} else { 
								$("##mapdiv_" + geog_auth_rec_id).addClass('niceGeoSPatData');
							} 
						}
					}; 
					$(document).ready(function() {
						setupMap("#variables.geog_auth_rec_id#");
					});
				</script>
				<div class="mb-2 w-100" style="height: 600px;">
					<div id="mapdiv_#geog_auth_rec_id#" style="height:100%;"></div>
				</div>
				<ul id="mapMetadataUL" class="px-2 px-md-4 px-xl-5">
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
							<div class="h4 my-2">Higher Geography mappable
								<button type="button" class="btn btn-xs btn-powder-blue font-weight-bold mx-1" onclick=" enclosingpoly.setVisible(!enclosingpoly.getVisible()); ">hide/show</button> 
								<button type="button" class="btn btn-xs btn-powder-blue font-weight-bold mx-1" onclick=" map.fitBounds(findBounds(enclosingpoly.latLngs));">zoom to</button>
							</div>
						<cfelse>
							<div class="h4 my-2">Higher geography not mappable</div>
						</cfif>
					</li>
					<cfquery name="hasGeorefs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
						SELECT count(*) ct 
						FROM 
							lat_long
							join locality on lat_long.locality_id = locality.locality_id
						WHERE
							dec_lat is not null and dec_long is not null
							AND accepted_lat_long_fg = 1
							AND geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
					</cfquery>
					<cfif hasGeorefs.ct GT 0>
						<li>
							<div class="h4 my-2">#hasGeorefs.ct# georeferenced localities.
								<button type="button" class="btn btn-xs btn-powder-blue mx-1 font-weight-bold" onclick="map.fitBounds(georefsBounds); ">zoom to</button>
							</div>
							
						</li>
						<li>
							<div id="selectedMarkerDiv" class="h4 my-2">Click on a marker for locality details.</div>
						</li>
					</cfif>
				</ul>
			<cfcatch>
				<h2>Error: #cfcatch.type# #cfcatch.message#</h2> 
				<div>#cfcatch.detail#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="geogMapThread#tn#" />

	<cfreturn cfthread["geogMapThread#tn#"].output>
</cffunction>


<!--- function getLocalityMapHtml return a block of html with a map for a locality. 

   @param locality_id the primary key value for the locality for which to return a map.
   @param reload if true, is a reload of the map, don't include google maps api library again.
   @return block of html.
--->
<cffunction name="getLocalityMapHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="locality_id" type="string" required="yes">
	<cfargument name="reload" type="string" required="no">
	<cfargument name="extraText" type="string" required="no" default="">
	
	<!--- TODO: Check for encumbrances --->

	<cfset variables.locality_id = arguments.locality_id>
	<cfif isDefined("arguments.extraText")>
		<cfset variables.extraText = arguments.extraText>
	</cfif>
	
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="localityMapThread#tn#">
		<cfoutput>
			<cftry>
				<cfif isDefined("reload") AND reload EQ "true">
					<!--- map section is being reloaded, api is already loaded on page --->
				<cfelse>
					<script src="#Application.protocol#://maps.googleapis.com/maps/api/js?key=#application.gmap_api_key#&libraries=geometry" type="text/javascript">
				</cfif>
				</script>
				<script>
					// utility function to support fitting bounds of map to data
					function findBounds(latLongs) { 
						var bounds = new google.maps.LatLngBounds();
						latLongs.getArray().forEach(function(path){ 
							path.getArray().forEach(function(latlong){ 
								if (latlong.lat() < 89.5 & latlong.lat() > -89.5) { 
									bounds.extend(latlong)
								}
							});
						}); 
						return bounds;
					} 

					// global scope varaiables available for referencing map objects.
					<cfif isDefined("reload") AND reload EQ "true">
						<!--- map section is being reloaded globals and functions are already defined --->
					<cfelse>
					var map;
					var enclosingpoly;
					var georefs;
					var georefsBounds;
					var uncertaintypoly;
					var errorcircle;
					var georefsLoaded = false;
					var polygonLoaded = false;
					var higherLoaded = false;
					var uncertaintyPolygonArray = [];
					var enclosingPolygonArray = [];

					function setupMap(locality_id){
						var bounds = new google.maps.LatLngBounds();
						var uncertaintyPointsArray=[];
						var enclosingPointsArray=[];

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
						map = new google.maps.Map(document.getElementById("mapdiv_" + locality_id), mapOptions);

						// obtain georeferences 
						$.getJSON("/localities/component/georefUtilities.cfc",
	      				{
								method : "getGeorefsGeoJSON",
								locality_id: locality_id,
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
									// fit the map bounds to the loaded features
									var bounds = new google.maps.LatLngBounds(); 
									map.data.forEach(function(feature){
										feature.getGeometry().forEachLatLng(function(latlng){
											bounds.extend(latlng);
										});
										var accepted = feature.getProperty('accepted');
										if (accepted=='Yes') { 
											feature.getGeometry().forEachLatLng(function(latlng){
												georefs = latlng
											});
										}
									});
									map.fitBounds(bounds);
									georefsBounds = bounds;
									center = map.getCenter();
									georefsLoaded = true;
									postLoadCheck(locality_id);
								}
							}
						).fail(function(jqXHR,textStatus,error){
							handleFail(jqXHR,textStatus,error,"looking up georeferences for localities in higher geography");
						});

						// circle for coordinate uncertanty in meters, if specified
					   $.getJSON("/localities/component/georefUtilities.cfc",
					      {
					         method : "getPointRadiusJSON",
					         locality_id : locality_id,
					         returnformat : "json"
					      },
					      function (result) {
								console.log(result);
								if (result) { 
									var dec_lat = result.dec_lat;
									var dec_long = result.dec_long;
									var radius = result.coordinateuncertaintyinmeters;
									if (radius) { 
										var center=new google.maps.LatLng(dec_lat,dec_long);
										bounds.extend(center);
										if (parseInt(radius)>0){
											var circleoptn = {
												strokeColor: '##FF0000',
												strokeOpacity: 0.8,
												strokeWeight: 2,
												fillColor: '##FF0000',
												fillOpacity: 0.15,
												map: map,
												center: center,
												radius: parseInt(radius),
												zIndex:-99
											};
											errorcircle = new google.maps.Circle(circleoptn);
											bounds.union(errorcircle.getBounds());
											map.fitBounds(bounds);
										}
									}
								}
					      }
					   ).fail(function(jqXHR,textStatus,error){
					      handleFail(jqXHR,textStatus,error,"looking up coordinate uncertainty of georeference for locality");
					   });

						// Polygon for error region, if specified, ajax load.
						$.get( "/localities/component/georefUtilities.cfc?returnformat=plain&method=getGeoreferenceErrorWKT&locality_id=" + locality_id, function( wkt ) {
							if (wkt.length>0){
								var regex = /\(([^()]+)\)/g;
								var RingsErr = [];
								var results;
								while( results = regex.exec(wkt) ) {
									RingsErr.push( results[1] );
								}
								for(var i=0;i<RingsErr.length;i++){
									// for every polygon in the WKT, create an array
									var lary=[];
									var da=RingsErr[i].split(",");
									for(var j=0;j<da.length;j++){
										// push the coordinate pairs to the array as LatLngs
										var xy = da[j].trim().split(" ");
										var pt=new google.maps.LatLng(xy[1],xy[0]);
										lary.push(pt);
										// console.log(lary);
										bounds.extend(pt);
									}
									// now push the single-polygon array to the array of arrays (of polygons)
									uncertaintyPointsArray.push(lary);
								}
								uncertaintypoly = new google.maps.Polygon({
									paths: uncertaintyPointsArray,
									strokeColor: '##7412A4',
									strokeOpacity: 0.9,
									strokeWeight: 2,
									fillColor: '##CF6FFF', 
									fillOpacity: 0.35
								});
								uncertaintypoly.setMap(map);
								uncertaintyPolygonArray.push(uncertaintypoly);
								// END build WKT
								// expand bounds if needed
								if (bounds.getNorthEast().equals(bounds.getSouthWest())) {
									var extendPoint1 = new google.maps.LatLng(bounds.getNorthEast().lat() + 0.05, bounds.getNorthEast().lng() + 0.05);
									var extendPoint2 = new google.maps.LatLng(bounds.getNorthEast().lat() - 0.05, bounds.getNorthEast().lng() - 0.05);
									bounds.extend(extendPoint1);
									bounds.extend(extendPoint2);
								}
								if (bounds.getNorthEast().lat() > 89 || bounds.getSouthWest().lat() < -89) { 
									bounds = google.maps.LatLngBounds.MAX_BOUNDS;
								} 
								map.fitBounds(bounds);
							} else {
								$("##mapdiv_" + locality_id).addClass('noErrorWKT');
							}
							polygonLoaded = true;
							postLoadCheck(locality_id);
						});
						// Polygon for surrounding higher geography if any, ajax load
						$.get( "/localities/component/georefUtilities.cfc?returnformat=plain&method=getContainingGeographyWKT&locality_id=" + locality_id, function( wkt ) {
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
									enclosingPointsArray.push(lary);
								}
								enclosingpoly = new google.maps.Polygon({
									paths: enclosingPointsArray,
									strokeColor: '##1E90FF',
									strokeOpacity: 0.8,
									strokeWeight: 2,
									fillColor: '##1E90FF',
									fillOpacity: 0.25
								});
								enclosingpoly.setMap(map);
								enclosingPolygonArray.push(enclosingpoly);
								// END build WKT
							} else {
								$("##mapdiv_" + locality_id).addClass('noWKT');
							}
							if (bounds.getNorthEast().equals(bounds.getSouthWest())) {
								var extendPoint1 = new google.maps.LatLng(bounds.getNorthEast().lat() + 0.05, bounds.getNorthEast().lng() + 0.05);
								var extendPoint2 = new google.maps.LatLng(bounds.getNorthEast().lat() - 0.05, bounds.getNorthEast().lng() - 0.05);
								bounds.extend(extendPoint1);
								bounds.extend(extendPoint2);
							}		
							map.fitBounds(bounds);
							if (bounds.getNorthEast().lat() > 89 || bounds.getSouthWest().lat() < -89) { 
								bounds = google.maps.LatLngBounds.MAX_BOUNDS;
							} 
							map.fitBounds(bounds);
							higherLoaded = true;
							postLoadCheck(locality_id);
						});
					}
					function postLoadCheck(locality_id) { 
						if (georefsLoaded && polygonLoaded && higherLoaded && georefs) { 
							var hasProblem = false;
							for(var a=0; a<enclosingPolygonArray.length; a++){
								if (! google.maps.geometry.poly.containsLocation(georefs, enclosingPolygonArray[a]) ) {
									hasProblem = true;
									// accessible information
									$("##mapMetadataUL").append("<li class='list-style-circle'>Georeference for locality is outside of enclosing higher geography.</li>");
								}
							}
							for(var a=0; a<uncertaintyPolygonArray.length; a++){
								if (! google.maps.geometry.poly.containsLocation(georefs, uncertaintyPolygonArray[a]) ) {
									hasProblem = true;
									// accessible information
									$("##mapMetadataUL").append("<li class='list-style-circle'>Georeference for locality is outside of Footprint Polygon.</li>");
								}
							}
							if (hasProblem) {
								$("##mapdiv_" + locality_id).addClass('uglyGeoSPatData');
							} else {
								$("##mapdiv_" + locality_id).addClass('niceGeoSPatData');
							}
						}
					};
					</cfif>
					$(document).ready(function() {
						setupMap("#variables.locality_id#");
					});
				</script>
				<cfquery name="getGeoreferences" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
					SELECT
						LAT_LONG_ID,LOCALITY_ID,LAT_DEG,DEC_LAT_MIN,LAT_MIN,trim(LAT_SEC) LAT_SEC,LAT_DIR,
						LONG_DEG,DEC_LONG_MIN,LONG_MIN,trim(LONG_SEC) LONG_SEC,LONG_DIR,trim(DEC_LAT) DEC_LAT,trim(DEC_LONG) DEC_LONG,
						DATUM,to_meters(max_error_distance, max_error_units) COORDINATEUNCERTAINTYINMETERS,
						UTM_ZONE,UTM_EW,UTM_NS,
						ORIG_LAT_LONG_UNITS,DETERMINED_BY_AGENT_ID,DETERMINED_DATE,
						LAT_LONG_REF_SOURCE,LAT_LONG_REMARKS,
						MAX_ERROR_DISTANCE,MAX_ERROR_UNITS,NEAREST_NAMED_PLACE,LAT_LONG_FOR_NNP_FG,
						FIELD_VERIFIED_FG,ACCEPTED_LAT_LONG_FG,
						EXTENT,GPSACCURACY,GEOREFMETHOD, VERIFICATIONSTATUS,SPATIALFIT,
						GEOLOCATE_UNCERTAINTYPOLYGON,GEOLOCATE_SCORE,GEOLOCATE_PRECISION,GEOLOCATE_NUMRESULTS,GEOLOCATE_PARSEPATTERN,
						VERIFIED_BY_AGENT_ID,ERROR_POLYGON,db.agent_name as determiner,
						vb.agent_name as verifiedby
					FROM
						lat_long
						left join preferred_agent_name db on determined_by_agent_id = db.agent_id
						left join preferred_agent_name vb on verified_by_agent_id = vb.agent_id
					WHERE 
						locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
					ORDER BY 
						ACCEPTED_LAT_LONG_FG DESC, lat_long_id
				</cfquery>
				<cfquery name="getAcceptedGeoref" dbtype="query">
					SELECT * 
					FROM getGeoreferences
					WHERE accepted_lat_long_fg=1
				</cfquery>
				<cfif len(getAcceptedGeoref.dec_lat) gt 0 and len(getAcceptedGeoref.dec_long) gt 0 and (getAcceptedGeoref.dec_lat is not 0 and getAcceptedGeoref.dec_long is not 0)>
					<div class="h3 px-2 pt-2">
						Map of Georeferences
						<cfif isDefined("variables.extraText")>#variables.extraText#</cfif>
					</div>
				<cfelse>
					<div class="h3 pt-2 text-danger px-2">No accepted georeferences</div>
				</cfif>
				<div class="mb-2 col-12 px-0" style="height: 360px;">
					<div id="mapdiv_#REReplace(locality_id,'[^0-9]','','All')#" style="height:100%;"></div>
				</div>
				<div class="mb-2 col-12 px-1 px-md-3 ">
					<ul id="mapMetadataUL" class="px-4">
						<cfquery name="hasHigherPolygon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
							SELECT count(*) ct 
							FROM 
								geog_auth_rec 
							WHERE
								wkt_polygon is not null
								AND geog_auth_rec_id in (
									SELECT geog_auth_rec_id 
									FROM locality
									WHERE
										locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
								)
						</cfquery>
						<li class="my-1 list-style-circle">
							<cfif hasHigherPolygon.ct GT 0>
								<span class="h5">Higher Geography mappable</span> 
								<button type="button" class="btn btn-xs btn-powder-blue mx-1 font-weight-bold"  onclick=" enclosingpoly.setVisible(!enclosingpoly.getVisible()); ">hide/show</button>
								<button type="button" class="btn btn-xs btn-powder-blue mx-1 font-weight-bold" onclick=" map.fitBounds(findBounds(enclosingpoly.latLngs));">zoom to</button>
							<cfelse>
								<span class="h5">Higher geography not mappable</span>
							</cfif>
						</li>
						<cfquery name="hasUncertantyPolygon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
							SELECT count(*) ct
							FROM lat_long
							WHERE
								accepted_lat_long_fg = 1
								AND
								error_polygon is not null
								AND
								locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
						</cfquery>
						<li class="my-1 list-style-circle">
							<cfif hasUncertantyPolygon.ct GT 0>
								<span class="h5">Georeference has uncertanty polygon</span>
								<button type="button" class="btn btn-xs btn-powder-blue mx-1 font-weight-bold" onclick=" uncertaintypoly.setVisible(!uncertaintypoly.getVisible()); ">hide/show</button> 
								<button type="button" class="btn btn-xs btn-powder-blue font-weight-bold" onclick=" map.fitBounds(findBounds(uncertaintypoly.latLngs));">zoom to</button>
							<cfelse>
								<span class="h5">No polygon with georeference</span>
							</cfif>
						</li>
						<li class="my-1 list-style-circle">
							<cfif getAcceptedGeoref.recordcount GT 0 AND getAcceptedGeoref.COORDINATEUNCERTAINTYINMETERS GT 0>
								<span class="h5">Coordinate uncertanty in meters = #getAcceptedGeoref.coordinateuncertaintyinmeters#</span> 
								<button type="button" class="btn btn-xs btn-powder-blue font-weight-bold" onclick=" errorcircle.setVisible(!errorcircle.getVisible()); ">hide/show</button> 
								<button type="button" class="btn btn-xs btn-powder-blue font-weight-bold" onclick=" map.fitBounds(errorcircle.getBounds());">zoom to</a>
							<cfelse>
								<span class="h5">No error radius.</span>
							</cfif>
						</li>
						<cfif getAcceptedGeoref.recordcount GT 0 AND getAcceptedGeoref.COORDINATEUNCERTAINTYINMETERS EQ "301">
							<li class="my-1 list-style-circle">
								<span class="h5 text-danger">Coordinate uncertanty of 301 is suspect, geolocate assigns this value when unable to calculate an error radius.<span>
							</li>
						</cfif>
						<cfif getGeoreferences.recordcount GT 1>
							<li class="my-1 list-style-circle">
								<span class="h5">#getGeoreferences.recordcount# georeferences, including unaccepted.</span> 
								<button type="button" class="btn btn-xs btn-powder-blue font-weight-bold" onclick=" map.fitBounds(georefsBounds); ">zoom to</button>
							</li>
						</cfif>
					</ul>
				</div>

			<cfcatch>
				<h2>Error: #cfcatch.type# #cfcatch.message#</h2> 
				<div>#cfcatch.detail#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="localityMapThread#tn#" />

	<cfreturn cfthread["localityMapThread#tn#"].output>
</cffunction>



<!--- getLocalityHtml returns html showing locality details

@param locality_id the primary key value for the locality o display.
--->
<cffunction name="getLocalityHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="locality_id" type="string" required="yes">
	
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="localityDetailsThread#tn#">
		<cfoutput>
			<cftry>
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
					<!--- potentially relevant actions: mask collector, mask coordinates, mask original field number. --->
				</cfif>
				<cfquery name="lookupLocality" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT 
						geog_auth_rec_id, spec_locality, sovereign_nation,
						minimum_elevation, maximum_elevation, orig_elev_units,
						to_meters(maximum_elevation, orig_elev_units) max_elev_in_m,
						to_meters(minimum_elevation, orig_elev_units) min_elev_in_m,
						min_depth, max_depth, depth_units,
						to_meters(max_depth, depth_units) max_depth_in_m,
						to_meters(min_depth, depth_units) min_depth_in_m,
						<cfif ListContains(encumber,"mask coordinates")>
							'[Masked]' as section_part, 
							'' as section, '' as township, '' as township_direction, '' as range, '' as range_direction,
							'[Masked]' as plss,
						<cfelse>
							section_part, section, township, township_direction, range, range_direction,
							trim(upper(section_part) || ' ' || nvl2(section,'S','') || section ||  nvl2(township,' T',' ') || township || upper(township_direction) || nvl2(range,' R',' ') || range || upper(range_direction)) as plss,
						</cfif>
						nogeorefbecause, georef_updated_date, georef_by,
						curated_fg, locality_remarks
					FROM locality
					WHERE 
						locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
				</cfquery>
				<cfif lookupLocality.recordcount NEQ 1>
					<cfthrow message="Found other than one locality with specified locality_id [#encodeForHtml(locality_id)#].  Locality may be used only by a department for which you do not have access.">
				</cfif>
				<ul class="list-group list-unstyled mt-1 py-1">
					<cfloop query="lookupLocality">
						<cfset geog_auth_rec_id = "#lookupLocality.geog_auth_rec_id#">
						<cfquery name="lookupHigherGeog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT higher_geog
							FROM geog_auth_rec
							WHERE 
								geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
						</cfquery>
						<li class="list-group-item py-0">
							<span class="float-left h4 mb-0">Higher Geography</span>
							<span class="float-left small95 pl-1 mb-0"> <a href="/localities/viewHigherGeography.cfm?geog_auth_rec_id=#geog_auth_rec_id#">#lookupHigherGeog.higher_geog#</a></span>
						</li>
						<li class="list-group-item py-0">
							<span class="float-left h4 mb-0">Sovereign Nation</span>
							<span class="float-left small95 pl-1 mb-0"> #lookupLocality.sovereign_nation#</span>
						</li>
						<cfset curated_fg = "#lookupLocality.curated_fg#">
						<li class="list-group-item py-0">
							<span class="float-left h4 mb-0">Vetted</span>
							<cfif curated_fg EQ 1><cfset vetted="Yes"><cfelse><cfset vetted="No"></cfif>
							<span class="float-left small95 pl-1 mb-0"> #vetted#</span>
						</li>
						<li class="list-group-item py-0">
							<span class="float-left h4 mb-0">Specific Locality</span>
							<span class="float-left small95 pl-1 mb-0"> #lookupLocality.spec_locality#</span>
						</li>
						<cfset minimum_elevation = "#lookupLocality.minimum_elevation#">
						<cfif len(minimum_elevation) GT 0>
							<cfset maximum_elevation = "#lookupLocality.maximum_elevation#">
							<cfset orig_elev_units = "#lookupLocality.orig_elev_units#">
							<li class="list-group-item py-0">
								<span class="float-left h4 mb-0">Elevation</span>
								<cfif len(maximum_elevation) GT 0 AND minimum_elevation NEQ maximum_elevation>
									<cfset elev = "#minimum_elevation#-#maximum_elevation# #orig_elev_units#">
								<cfelse>
									<cfset elev = "#minimum_elevation# #orig_elev_units#">
								</cfif>
								<span class="float-left small95 pl-1 mb-0"> #elev#</span>
							</li>
							<cfset max_elev_in_m = "#lookupLocality.max_elev_in_m#">
							<cfset orig_elev_units = "#lookupLocality.orig_elev_units#">
							<li class="list-group-item py-0">
								<span class="float-left h4 mb-0">Elevation in Meters</span>
								<cfif len(max_elev_in_m) GT 0 AND min_elev_in_m NEQ max_elev_in_m>
									<cfset elev = "#min_elev_in_m#-#max_elev_in_m# m">
								<cfelse>
									<cfset elev = "#min_elev_in_m# m">
								</cfif>
								<span class="float-left small95 pl-1 mb-0"> #elev#</span>
							</li>
						</cfif>
						<cfset min_depth = "#lookupLocality.min_depth#">
						<cfif len(min_depth) GT 0>
							<cfset max_depth = "#lookupLocality.max_depth#">
							<cfset depth_units = "#lookupLocality.depth_units#">
							<li class="list-group-item py-0">
								<span class="float-left h4 mb-0">Depth</span>
								<cfif len(max_depth) GT 0 AND min_depth NEQ max_depth>
									<cfset depth = "#min_depth#-#max_depth# #depth_units#">
								<cfelse>
									<cfset depth = "#min_depth# #depth_units#">
								</cfif>
								<span class="float-left small95 pl-1 mb-0"> #depth#</span>
							</li>
							<cfset max_depth_in_m = "#lookupLocality.max_depth_in_m#">
							<cfset depth_units = "#lookupLocality.depth_units#">
							<li class="list-group-item py-0">
								<span class="float-left h4 mb-0">Depth in Meters</span>
								<cfif len(max_depth_in_m) GT 0 AND min_depth_in_m NEQ max_depth_in_m>
									<cfset depth = "#min_depth_in_m#-#max_depth_in_m# m">
								<cfelse>
									<cfset depth = "#min_depth_in_m# m">
								</cfif>
								<span class="float-left small95 pl-1 mb-0"> #depth#</span>
							</li>
						</cfif> 
						<cfif len(lookupLocality.section) GT 0>
							<cfset plss = "#lookupLocality.plss#">
							<li class="list-group-item py-0">
								<span class="float-left h4 mb-0">PLSS</span>
								<span class="float-left small95 pl-1 mb-0"> #plss#</span>
							</li>
						</cfif>
						<cfif len(lookupLocality.nogeorefbecause) GT 0>
							<li class="list-group-item py-0">
								<span class="float-left h4 mb-0">Not Georeferenced Because</span>
								<span class="float-left small95 pl-1 mb-0"> #lookupLocality.nogeorefbecause#</span>
							</li>
						</cfif>
						<cfif len(lookupLocality.georef_by) GT 0>
							<li class="list-group-item py-0">
								<span class="float-left h4 mb-0 ">Georeferenced By</span>
								<span class="float-left small95 pl-1 mb-0"> #lookupLocality.georef_by#</span>
							</li>
						</cfif>
						<cfif len(lookupLocality.georef_updated_date) GT 0>
							<li class="list-group-item py-0">
								<span class="float-left h4 mb-0">Georeference Updated</span>
								<span class="float-left pl-1 mb-0"> #lookupLocality.georef_updated_date#</span>
							</li>
						</cfif>
						<cfif len(lookupLocality.locality_remarks) GT 0>
							<li class="list-group-item py-0">
								<span class="float-left h4 mb-0">Locality Remarks</span>
								<span class="float-left small95 pl-1 mb-0"> #lookupLocality.locality_remarks#</span>
							</li>
						</cfif>
					</cfloop>
				</ul>

			<cfcatch>
				<h2 class="h3 text-danger mt-0">Error: #cfcatch.type# #cfcatch.message#</h2> 
				<div>#cfcatch.detail#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="localityDetailsThread#tn#" />

	<cfreturn cfthread["localityDetailsThread#tn#"].output>
</cffunction>

<!--- given a locality id, return a block of html with a list of geological attributes.
  @param locality_id the locality for which to lookup the geology.
  @return block of html containing a list of geological attribtues, or an error message.
--->
<cffunction name="getLocalityGeologyDetailsHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="locality_id" type="string" required="yes">

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="localityGeologyDetailsThread#tn#">
		<cfoutput>
			<cftry>
				<cfquery name="getGeologicalAttributes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.query_timeout#">
					SELECT
						geology_attribute_id,
						ctgeology_attribute.type,
						geology_attributes.geology_attribute,
						geology_attributes.geo_att_value,
						geology_attributes.geo_att_determiner_id,
						agent_name determined_by,
						to_char(geology_attributes.geo_att_determined_date,'yyyy-mm-dd') determined_date,
						geology_attributes.geo_att_determined_method determined_method,
						geology_attributes.geo_att_remark,
						geology_attributes.previous_values,
						geology_attribute_hierarchy.usable_value_fg,
						geology_attribute_hierarchy.geology_attribute_hierarchy_id
					FROM
						geology_attributes
						join ctgeology_attribute on geology_attributes.geology_attribute = ctgeology_attribute.geology_attribute
						left join preferred_agent_name on geo_att_determiner_id = agent_id
						left join geology_attribute_hierarchy 
							on geology_attributes.geo_att_value = geology_attribute_hierarchy.attribute_value 
								and
								geology_attributes.geology_attribute = geology_attribute_hierarchy.attribute
					WHERE 
						geology_attributes.locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
					ORDER BY
						ctgeology_attribute.ordinal
				</cfquery>
				<cfif getGeologicalAttributes.recordcount EQ 0>
					<h2 class="h4 px-2">Geological Attributes</h2>
						<ul class="mb-2 pl-2 pl-xl-4 ml-xl-1">
							<li>
								Recent (no geological attributes) 
							</li>
						</ul>
				<cfelse>
					<h2 class="h4">Geological Attributes</h2>
						<ul class="mb-2 pl-2 pl-xl-4 ml-xl-1">
							<cfset valList = "">
							<cfset shownParentsList = "">
							<cfset separator = "">
							<cfset separator2 = "">
							<cfloop query="getGeologicalAttributes">
								<cfset valList = "#valList##separator##getGeologicalAttributes.geo_att_value#">
								<cfset separator = "|">
							</cfloop>
							<cfloop query="getGeologicalAttributes">
								<cfquery name="getParentage" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.query_timeout#">
									SELECT distinct
									  connect_by_root geology_attribute_hierarchy.attribute parent_attribute,
									  connect_by_root attribute_value parent_attribute_value,
									  connect_by_root usable_value_fg
									FROM geology_attribute_hierarchy
									  left join geology_attributes on
									     geology_attribute_hierarchy.attribute = geology_attributes.geology_attribute
									     and
							   		  geology_attribute_hierarchy.attribute_value = geology_attributes.geo_att_value
									WHERE geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getGeologicalAttributes.geology_attribute_hierarchy_id#">
									CONNECT BY nocycle PRIOR geology_attribute_hierarchy_id = parent_id
								</cfquery>
								<cfset parentage="">
								<cfloop query="getParentage">
									<cfif ListContains(valList,getParentage.parent_attribute_value,"|") EQ 0 AND  ListContains(shownParentsList,getParentage.parent_attribute_value,"|") EQ 0 >
										<cfset parentage="#parentage#<li><span class='text-secondary'>#getParentage.parent_attribute#:#getParentage.parent_attribute_value#</span></li>" > <!--- " --->
										<cfset shownParentsList = "#shownParentsList##separator2##getParentage.parent_attribute_value#">
										<cfset separator2 = "|">
									</cfif>
								</cfloop>
								#parentage#
								<li>
									<cfif len(getGeologicalAttributes.determined_method) GT 0>
										<cfset method = " Method: #getGeologicalAttributes.determined_method#">
									<cfelse>
										<cfset method = "">
									</cfif>
									<cfif len(getGeologicalAttributes.geo_att_remark) GT 0>
										<cfset remarks = " <span class='smaller-text'>Remarks: #getGeologicalAttributes.geo_att_remark#</span>"><!--- " --->
									<cfelse>
										<cfset remarks="">
									</cfif>
									<cfif usable_value_fg EQ 1>
										<cfset marker = "*">
										<cfset spanClass = "">
									<cfelse>
										<cfset marker = "">
										<cfset spanClass = "text-danger">
									</cfif>
									<span class="#spanClass#">#geo_att_value# #marker#</span> (#geology_attribute#) #determined_by# #determined_date##method##remarks#
								</li>
							</cfloop>
						</ul>
				</cfif>
			<cfcatch>
				<h3 class="h4 text-danger">Error: #cfcatch.type# #cfcatch.message#</h2> 
				<div>#cfcatch.detail#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="localityGeologyDetailsThread#tn#" />

	<cfreturn cfthread["localityGeologyDetailsThread#tn#"].output>
</cffunction>

<!--- given a locality_id list the georeferences for the locality, with a button that crosslinks to a locality map.
  to integrate with map, assumes that map is a global javascript variable holding a google maps object, and that
  features in the map have an id equal to the lat_long_id, so that the test  if (feature.getId() == "#lat_long_id#") 
  can be performed on the features and that the georeferenced points will be features on the map.

  @param locality_id the locality for which to display georeferences.
--->
<cffunction name="getLocalityGeoreferenceDetailsHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="locality_id" type="string" required="yes">

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="localityGeoRefDetailsThread#tn#">
		<cfoutput>
			<cftry>
				<cfquery name="getLocalityMetadata" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT 
						nvl(spec_locality,'[No specific locality value]') spec_locality, 
						locality_id, 
						decode(curated_fg,1,' *','') curated
					FROM locality
					WHERE
						locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
				</cfquery>
				<cfif getLocalityMetadata.recordcount NEQ 1>
					<cfthrow message="Other than one locality found for the specified locality_id [#encodeForHtml(locality_id)#].  Locality may be used only by a department for which you do not have access.">
				</cfif>
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
					<!--- potentially relevant actions: mask collector, mask coordinates, mask original field number. --->
				</cfif>
				<cfif ListContains(encumber,"mask coordinates")>
					<div class="w-100">
						<ul class="small95">
							<li>[Masked]</li>
						</ul>
					</div>
				<cfelse>
					<cfset localityLabel = "#getLocalityMetadata.spec_locality##getLocalityMetadata.curated#">
					<cfset localityLabel = replace(localityLabel,'"',"&quot;","all")>
					<cfset localityLabel = replace(localityLabel,"'","\'","all")>
					<cfquery name="getGeoreferences" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT
							lat_long_id,
							georefmethod,
							to_char(dec_lat, '99' || rpad('.',nvl(coordinate_precision,5) + 1, '0')) dec_lat,
							dec_lat raw_dec_lat,
							to_char(dec_long, '999' || rpad('.',nvl(coordinate_precision,5) + 1, '0')) dec_long,
							dec_long raw_dec_long,
							max_error_distance,
							max_error_units,
							round(to_meters(lat_long.max_error_distance, lat_long.max_error_units)) coordinateUncertaintyInMeters,
							error_polygon,
							datum,
							extent,
							spatialfit,
							determined_by_agent_id,
							det_agent.agent_name determined_by,
							determined_date,
							gpsaccuracy,
							lat_long_ref_source,
							nearest_named_place,
							lat_long_for_nnp_fg,
							verificationstatus,
							field_verified_fg,
							verified_by_agent_id,
							ver_agent.agent_name verified_by,
							orig_lat_long_units,
							lat_deg, dec_lat_min, lat_min, lat_sec, lat_dir,
							long_deg, dec_long_min, long_min, long_sec, long_dir,
							utm_zone, utm_ew, utm_ns,
							CASE orig_lat_long_units
								WHEN 'decimal degrees' THEN dec_lat || '&##176;'
								WHEN 'deg. min. sec.' THEN lat_deg || '&##176; ' || lat_min || '&apos; ' || lat_sec || '&quot; ' || lat_dir
								WHEN 'degrees dec. minutes' THEN lat_deg || '&##176; ' || dec_lat_min || '&apos; ' || lat_dir
							END as LatitudeString,
							CASE orig_lat_long_units
								WHEN 'decimal degrees' THEN dec_long || '&##176;'
								WHEN'degrees dec. minutes' THEN long_deg || '&##176; ' || dec_long_min || '&apos; ' || long_dir
								WHEN 'deg. min. sec.' THEN long_deg || '&##176; ' || long_min || '&apos; ' || long_sec || '&quot ' || long_dir
							END as LongitudeString,
							accepted_lat_long_fg,
							decode(accepted_lat_long_fg,1,'Accepted','') accepted_lat_long,
							geolocate_uncertaintypolygon,
							geolocate_score,
							geolocate_precision,
							geolocate_numresults,
							geolocate_parsepattern,
							lat_long_remarks
						FROM
							lat_long
							left join preferred_agent_name det_agent on lat_long.determined_by_agent_id = det_agent.agent_id
							left join preferred_agent_name ver_agent on lat_long.verified_by_agent_id = ver_agent.agent_id
						WHERE 
							lat_long.locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
						ORDER BY
							accepted_lat_long_fg desc
					</cfquery>
					<h3 class="h4 px-2 w-100">Georeferences (#getGeoreferences.recordcount#)</h3>
					<cfif getGeoreferences.recordcount EQ 0>
						<cfquery name="checkNoGeorefBecause" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT
								nogeorefbecause
							FROM
								locality
							WHERE
								locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
						</cfquery>
						<cfif len(checkNoGeorefBecause.nogeorefbecause) EQ 0 >
							<cfset noGeoRef = "">
						<cfelse> 
							<cfset noGeoRef = " (#checkNoGeorefBecause.nogeorefbecause#)">
						</cfif>
						<div class="w-100">
							<ul class="small95">
								<li>None #noGeoRef#</li>
							</ul>
						</div>
					<cfelse>
						<div class="w-100">
							<cfloop query="getGeoreferences">
								<cfset original="">
								<cfset det = "">
								<cfset ver = "">
								<cfif len(determined_by) GT 0>
									<cfset det = " Determiner: #determined_by#. ">
								</cfif>
								<cfif len(verified_by) GT 0>
									<cfset ver = " Verified by: #verified_by#. ">
								</cfif>
								<cfif len(utm_zone) GT 0>
									<cfset original = "(as: #utm_zone# #utm_ew# #utm_ns#)">
								<cfelse>
									<cfset original = "(as: #LatitudeString#,#LongitudeString#)">
								</cfif>
								<cfset divClass="small90 my-1 w-100">
								<cfif accepted_lat_long EQ "Accepted">
									<cfset divClass="small90 font-weight-lessbold my-1 w-100">
								</cfif>
								<div class="#divClass# px-2">#dec_lat#, #dec_long# &nbsp; #datum# ±#coordinateUncertaintyInMeters#m</div>
								<ul class="mb-2 pl-2 pl-xl-4 ml-xl-1 small95">
									<li>
										#original# <span class="#divClass#">#accepted_lat_long#</span>
									</li>
									<li>
										Method: #georefmethod# #det# Verification: #verificationstatus# #ver#
									</li>
									<cfif len(geolocate_score) GT 0>
										<li>
											GeoLocate: score=#geolocate_score# precision=#geolocate_precision# results=#geolocate_numresults# pattern=#geolocate_parsepattern#
										</li>
									</cfif>
								</ul>
								<script>
									var bouncing#lat_long_id# = false;
									function toggleBounce#lat_long_id#() { 
										if (bouncing#lat_long_id#==true) { 
											bouncing#lat_long_id# = false;
											map.data.forEach(function (feature) { console.log(feature.getId()); if (feature.getId() == "#lat_long_id#") { map.data.overrideStyle(feature, { animation: null });  } }); 
											$('##toggleButton#lat_long_id#').html("Highlight on map");
										} else { 
											bouncing#lat_long_id# = true;
											map.data.forEach(function (feature) { console.log(feature.getId()); if (feature.getId() == "#lat_long_id#") { map.data.overrideStyle(feature, { animation: google.maps.Animation.BOUNCE});  } }); 
											$('##toggleButton#lat_long_id#').html("Stop bouncing");
										}
									};
								</script>
								<button type="button" id="toggleButton#lat_long_id#" class="btn btn-xs btn-info mb-2 mx-2" onClick=" toggleBounce#lat_long_id#(); ">Highlight on map</button>
							</cfloop>
						</div>
						
					</cfif><!--- has georeferences --->
				</cfif><!--- mask check --->
			<cfcatch>
				<h3 class="h4 text-danger">Error: #cfcatch.type# #cfcatch.message#</h3> 
				<div>#cfcatch.detail#</div>
				<cfif isDefined("cfcatch.cause.tagcontext")>
					<div>Line #cfcatch.cause.tagcontext[1].line# of #replace(cfcatch.cause.tagcontext[1].template,Application.webdirectory,'')#</div>
				</cfif>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="localityGeoRefDetailsThread#tn#" />

	<cfreturn cfthread["localityGeoRefDetailsThread#tn#"].output>
</cffunction>

<!--- function getLocalityUsesHtml return a block of html sumarizing the collecting events, 
   collections, and cataloged items associated with a locality.

   @param locality_id the primary key value for the locality for which to return html.
   @return block of html.
--->
<cffunction name="getLocalityUsesHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="locality_id" type="string" required="yes">
	
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="localityUsesThread#tn#">
		<cfoutput>
			<cftry>
				<cfquery name="localityUses" datasource="uam_god">
					SELECT
						count(cataloged_item.cat_num) numOfSpecs,
						count(distinct collecting_event.collecting_event_id) numOfCollEvents,
						collection.collection,
						collection.collection_cde,
						collection.collection_id
					from
						collecting_event
						left join cataloged_item on cataloged_item.collecting_event_id = collecting_event.collecting_event_id 
						left join collection on cataloged_item.collection_id = collection.collection_id
					WHERE
						collecting_event.locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
					GROUP BY
						collection.collection,
						collection.collection_cde,
						collection.collection_id
			  	</cfquery>
				<div>
					<cfif #localityUses.recordcount# is 0>
						<h2 class="h4 px-2 text-primary">This Locality (#locality_id#) contains no specimens. Please delete it if you don&apos;t have plans for it!</h2>
					<cfelseif #localityUses.recordcount# is 1>
						<h2 class="h4 px-2">
							This Locality (#locality_id#) contains 
							<cfif localityUses.numOfSpecs is 0>
								no specimens
							<cfelse>
								<a href="/Specimens.cfm?execute=true&builderMaxRows=1&action=builderSearch&nestdepth1=1&field1=LOCALITY%3ALOCALITY_LOCALITY_ID&searchText1=#locality_id#">
									#localityUses.numOfSpecs# #localityUses.collection_cde# specimens
								</a>
							</cfif>
							from <a href="/localities/CollectingEvents.cfm?execute=true&locality_id=#locality_id#&include_counts=true&include_ce_counts=true">#localityUses.numOfCollEvents# collecting events</a>.
						</h2>
					<cfelse>
						<cfset totalEvents=0>
						<cfset totalSpecimens=0>
						<cfloop query="localityUses">
							<cfset totalEvents=totalEvents+localityUses.numOfCollEvents>
							<cfset totalSpecimens=totalSpecimens+localityUses.numOfSpecs>
						</cfloop>
						<cfquery name="localityCollEventUses" datasource="uam_god">
							SELECT
								count(distinct collecting_event.collecting_event_id) numOfCollEvents
							from
								collecting_event
								left join cataloged_item on cataloged_item.collecting_event_id = collecting_event.collecting_event_id 
								left join collection on cataloged_item.collection_id = collection.collection_id
							WHERE
								collecting_event.locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
					  	</cfquery>
						<cfloop query="localityCollEventUses">
							<cfset totalEvents=localityCollEventUses.numOfCollEvents>
						</cfloop>
						<h2 class="h4 px-2">
							This Locality (#locality_id#)
							contains the following <a href="/Specimens.cfm?execute=true&builderMaxRows=1&action=builderSearch&nestdepth1=1&field1=LOCALITY%3ALOCALITY_LOCALITY_ID&searchText1=#locality_id#">#totalSpecimens# specimens</a>
							from <a href="/localities/CollectingEvents.cfm?execute=true&locality_id=#locality_id#&include_counts=true&include_ce_counts=true">#totalEvents# collecting events</a>:
						</h2>
						<ul class="px-2 pl-xl-4 ml-xl-1 small95">
							<cfloop query="localityUses">
								<li>
									<cfif numOfSpecs GT 0>
										<cfif numOfSpecs EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
										<a href="/Specimens.cfm?execute=true&builderMaxRows=2&action=builderSearch&nestdepth1=1&field1=LOCALITY%3ALOCALITY_LOCALITY_ID&searchText1=#locality_id#&nestdepth2=2&JoinOperator2=and&field2=CATALOGED_ITEM%3ACOLLECTION_CDE&searchText2=%3D#localityUses.collection_cde#">
											#numOfSpecs# #collection_cde# specimen#plural#
										</a>
									<cfelse>
										no specimens 
									</cfif> from 
									<cfset numSole = 0>
									<cfset numShared = 0>
									<cfif len(localityUses.collection_id) GT 0>
										<cfquery name="countSole" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
											SELECT distinct flatTableName.collecting_event_id 
											FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
												left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat1 on
													flatTableName.collecting_event_id = flat1.collecting_event_id
											WHERE flatTableName.locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
													and flat1.collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#localityUses.collection_id#">
											GROUP BY flatTableName.collecting_event_id
											HAVING count(distinct flatTableName.collection_cde) = 1
										</cfquery>
										<cfset numSole = countSole.recordcount>
										<cfquery name="countShared" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
											SELECT distinct flatTableName.collecting_event_id 
											FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
												left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat1 on
													flatTableName.collecting_event_id = flat1.collecting_event_id
											WHERE flatTableName.locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
													and flat1.collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#localityUses.collection_id#">
											GROUP BY flatTableName.collecting_event_id
											HAVING count(distinct flatTableName.collection_cde) > 1
										</cfquery>
										<cfset numShared = countShared.recordcount>
									</cfif>
									<cfif numShared EQ 0 and numSole GT 0>
										<cfif numSole EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
										<a href="/localities/CollectingEvents.cfm?execute=true&locality_id=#locality_id#&collnEvOper=eventUsedOnlyBy&collection_id=#localityUses.collection_id#&include_counts=true&include_ce_counts=true">
											#numSole# #collection_cde# only collecting event#plural#
										</a>
									<cfelseif numShared EQ 0 AND numSole EQ 0>
										<a href="/localities/CollectingEvents.cfm?execute=true&locality_id=#locality_id#&show_unused=unused_only&include_counts=true&include_ce_counts=true">
											
											#localityUses.numOfCollEvents# unused collecting events
										</a>
									<cfelse>
										<cfquery name="sharedWith" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
											SELECT DISTINCT collection_cde 
											FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
												WHERE collecting_event_id in (
													SELECT flatTableName.collecting_event_id 
													FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
														left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat1
															on flatTableName.collecting_event_id = flat1.collecting_event_id
													WHERE flatTableName.locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
														and flat1.collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#localityUses.collection_id#">
													GROUP BY flatTableName.collecting_event_id
													HAVING count(distinct flatTableName.collection_cde) > 1
												)
												and collection_cde <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#localityUses.collection_cde#">
										</cfquery>
										<cfset sharedNames = "">
										<cfset separator= "">
										<cfloop query="sharedWith">
											<cfset sharedNames = "#sharedNames##separator##sharedWith.collection_cde#">
											<cfset separator= ";">
										</cfloop>
										<cfif numSole EQ 0>
											<cfif numShared EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
											<a href="/localities/CollectingEvents.cfm?execute=true&locality_id=#locality_id#&collnEvOper=eventSharedOnlyBy&collection_id=#localityUses.collection_id#&include_counts=true&include_ce_counts=true">
												#numShared# shared collecting event#plural# (#collection_cde# shared with #sharedNames#)
											</a>
										<cfelse>
												<cfif numSole EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
												<a href="/localities/CollectingEvents.cfm?execute=true&locality_id=#locality_id#&collnEvOper=eventUsedOnlyBy&collection_id=#localityUses.collection_id#&include_counts=true&include_ce_counts=true">
													#numSole# #collection_cde# only collecting event#plural#
												</a>
												 and 
												<cfif numShared EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
												<a href="/localities/CollectingEvents.cfm?execute=true&locality_id=#locality_id#&collnEvOper=eventSharedOnlyBy&collection_id=#localityUses.collection_id#&include_counts=true&include_ce_counts=true">
													#numShared# shared collecting event#plural# (#collection_cde# shared with #sharedNames#)
												</a>
												&mdash;All 
												<cfif numShared + numSole EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
												<a href="/localities/CollectingEvents.cfm?execute=true&locality_id=#locality_id#&collnEvOper=eventUsedBy&collection_id=#localityUses.collection_id#&include_counts=true&include_ce_counts=true">
													#numSole+numShared# #collection_cde# collecting event#plural#</a>.
										</cfif>
									</cfif>
								</li>
							</cfloop>
						</ul>
					</cfif>
				</div>
			<cfcatch>
				<h2 class="h3 text-danger">Error: #cfcatch.type# #cfcatch.message#</h2> 
				<div>#cfcatch.detail#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="localityUsesThread#tn#" />

	<cfreturn cfthread["localityUsesThread#tn#"].output>
</cffunction>

<!--- function getLocalityMediaHtml return a block of html with media associated with a locality. 

   @param locality_id the primary key value for the locality for which to return media.
   @return block of html.
--->
<cffunction name="getLocalityMediaHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="locality_id" type="string" required="yes">
	
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="localityMediaThread#tn#">
		<cfoutput>
			<cftry>
				<cfquery name="localityMedia"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						media_id
					FROM
						media_relations
					WHERE
						media_relationship like '% locality'
						and
						related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#"> 
						and 
						MCZBASE.is_media_encumbered(media_id) < 1 
				</cfquery>
				<cfif localityMedia.recordcount gt 0>
					<cfloop query="localityMedia">
						<div class="col-6 px-1 col-sm-3 col-lg-3 col-xl-3 mb-1 px-md-2 pt-1 float-left"> 
							<div id='locMediaBlock#localityMedia.media_id#'>
								<cfset mediaBlock= getMediaBlockHtmlUnthreaded(media_id="#localityMedia.media_id#",size="350",captionAs="textShort")>
							</div>
						</div>
					</cfloop>
				</cfif>
			<cfcatch>
				<h3 class="h4 text-danger">Error: #cfcatch.type# #cfcatch.message#</h3> 
				<div>#cfcatch.detail#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="localityMediaThread#tn#" />

	<cfreturn cfthread["localityMediaThread#tn#"].output>
</cffunction>

<!--- function getLocalityVerbatimHtml return a block of html with verbatim data from
 collecting events associated with a locality. 

   @param locality_id the primary key value for the locality for which to return 
     verbatim data.
   @return block of html.
--->
<cffunction name="getLocalityVerbatimHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="locality_id" type="string" required="yes">
	<cfargument name="context" type="string" required="no" default="view">

	<!---
	NOTE: When using threads, cfarguments are out of scope for the thread, place copies of them
	   into the variables scope.    See: https://gist.github.com/bennadel/9760037 for more examples of
   	scope issues related to cfthread 
	--->
	<cfset variables.context = arguments.context>

	<!--- Check for encumbrances --->
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
		<!--- potentially relevant actions: mask collector, mask coordinates, mask original field number, mask locality. --->
	</cfif>
	
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="localityVerbatimThread#tn#">
		<cfoutput>
			<cftry>
				<cfquery name="getVerbatim" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getVerbatim_result">
					SELECT 
						count(*) ct,
						verbatim_locality
					FROM collecting_event
					WHERE
						locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
						and verbatim_locality is not null
					GROUP BY 
						verbatim_locality
				</cfquery>
				<cfif getVerbatim.recordcount EQ 0>
					<div class="h4">No verbatim locality values</div>
				<cfelse>
					<ul class="px-2 pl-xl-4 ml-xl-1">
						<cfif ListContains(encumber,"mask locality") GT 0>
							[Masked]
						<cfelse>
							<cfloop query="getVerbatim">
								<cfif ct GT 1><cfset counts=" (in #ct# collecting events)"><cfelse><cfset counts=""></cfif>
								<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_locality")>
									<li><a href="/localities/CollectingEvents.cfm?action=search&execute=true&method=getCollectingEvents&locality_id=#locality_id#&MinElevOper=%3D&MaxElevOper=%3D&MinElevOperM=%3D&MaxElevOperM=%3D&minDepthOper=%3D&MaxDepthOper=%3D&minDepthOperM=%3D&MaxDepthOperM=%3D&geology_attribute_hier=0&gs_comparator=%3D&verbatim_locality=%3D#encodeForUrl(verbatim_locality)#&begDateOper=%3D&endDateOper=%3D&accentInsensitive=1&include_counts=0">#verbatim_locality#</a>#counts#</li>
								<cfelse>
									<li>#verbatim_locality##counts# </li>
								</cfif>
							</cfloop>
						</cfif>
					</ul>
				</cfif>
				<cfquery name="getVerbatimGeoref" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getVerbatimGeoref_result">
					SELECT 
						count(*) ct,
						verbatimcoordinates,
						verbatimlatitude, verbatimlongitude,
						verbatimcoordinatesystem, verbatimsrs
					FROM collecting_event
					WHERE
						locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
						and (verbatimcoordinates is not null or verbatimlatitude is not null)
					GROUP BY 
						verbatimcoordinates,
						verbatimlatitude, verbatimlongitude,
						verbatimcoordinatesystem, verbatimsrs
				</cfquery>
				<cfif getVerbatimGeoref.recordcount EQ 0>
					<div class="h4">No verbatim coordinates</div>
				<cfelse>
					<div class="h4">Verbatim coordinate values</div>
					<ul class="px-2 pl-xl-4 ml-xl-1">
						<cfif ListContains(encumber,"mask coordinates") GT 0>
							[Masked]
						<cfelse>
							<cfloop query="getVerbatimGeoref">
								<cfif ct GT 1><cfset counts=" (in #ct# collecting events)"><cfelse><cfset counts=""></cfif>
								<li>
									<a href="/localities/CollectingEvents.cfm?action=search&execute=true&method=getCollectingEvents&locality_id=#locality_id#&MinElevOper=%3D&MaxElevOper=%3D&MinElevOperM=%3D&MaxElevOperM=%3D&minDepthOper=%3D&MaxDepthOper=%3D&minDepthOperM=%3D&MaxDepthOperM=%3D&geology_attribute_hier=0&gs_comparator=%3D&begDateOper=%3D&endDateOper=%3D&verbatimCoordinates=#encodeForUrl(verbatimcoordinates)#&verbatimCoordinateSystem=#encodeForUrl(verbatimcoordinatesystem)#&verbatimSRS=%3D#encodeForUrl(verbatimsrs)#&verbatimlatitude=#encodeForUrl(verbatimlatitude)#&verbatimlongigude=#encodeForUrl(verbatimlongitude)#&accentInsensitive=1&include_counts=0">
										#verbatimcoordinatesystem# #verbatimcoordinates# #verbatimlatitude# #verbatimlongitude# #verbatimsrs#
									</a> 
									 #counts#
								</li>
							</cfloop>
						</cfif>
					</ul>
				</cfif>
				<cfif getVerbatim.recordcount LT 21 >
					<cfquery name="getEventList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getEventList_result">
						SELECT 
							collecting_event_id,
							began_date, ended_date, verbatim_date,
							verbatim_locality, 
							verbatimcoordinates,
							verbatimlatitude, verbatimlongitude,
							verbatimcoordinatesystem, verbatimsrs
						FROM collecting_event
						WHERE
							locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
							and verbatim_locality is not null
					</cfquery>
					<cfif getEventList.recordcount GT 0>
						<div class="h4">Collecting Events <a href="/localities/CollectingEvents.cfm?action=search&execute=true&method=getCollectingEvents&locality_id=#locality_id#&accentInsensitive=1&include_counts=1" target="_blank">(#getEventList.recordcount#)</a></div>
						<ul class="px-2 pl-xl-4 ml-xl-1">
							<cfloop query="getEventList">
								<li>
									<cfif getEventList.began_date EQ getEventList.ended_date>
										<cfset date=getEventList.began_date>
									<cfelseif len(getEventList.began_date) GT 0 AND len(getEventList.began_date) GT 0>
										<cfset date="#getEventList.began_date#/#getEventList.ended_date#">
									<cfelse>
										<cfset date=getEventList.began_date>
									</cfif>
									<cfif len(getEventList.verbatim_date) GT 0>
										<cfset date="#date# [#getEventList.verbatim_date#]">
									</cfif>
									<cfif len(getEventList.verbatimcoordinates) GT 0>
										<cfset verbatim_coordinates=" #verbatimcoordinates# #verbatimsrs#">
									<cfelseif len(getEventList.verbatimlatitude) GT 0>
										<cfset verbatim_coordinates=" #verbatimlatitude#, #verbatimlongitude# #verbatimsrs#">
									<cfelse>
										<cfset verbatim_coordinates="">
									</cfif>
									<cfif isDefined("context") and context EQ "view">
										#date# #verbatim_locality##verbatim_coordinates# [<a href="/localities/viewCollectingEvent.cfm?collecting_event_id=#getEventList.collecting_event_id#">View</a>]
									<cfelseif isDefined("context") and context EQ "edit">
										#date# #verbatim_locality##verbatim_coordinates# [<a href="/localities/CollectingEvent.cfm?collecting_event_id=#getEventList.collecting_event_id#">#getEventList.collecting_event_id#</a>]
									</cfif>
								</li>
							</cfloop>
						</ul>
					</cfif>
				</cfif>
				<cfif isDefined("context") and context EQ "edit" and isdefined("session.roles") and listfindnocase(session.roles,"manage_locality")>
					<form name="createNewCollEventForm" id="createNewCollEventForm" method="post" action="/localities/CollectingEvent.cfm">
						<input type="hidden" name="action" value="new">
						<input type="hidden" name="locality_id" value="#locality_id#">
					</form>
					<input type="button" class="btn btn-secondary btn-xs" onClick=" $('##createNewCollEventForm').submit(); " value="Add a Collecting Event to this Locality">
				</cfif>
			<cfcatch>
				<h3 class="h4 text-danger">Error: #cfcatch.type# #cfcatch.message#</h3> 
				<div>#cfcatch.detail#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="localityVerbatimThread#tn#" />

	<cfreturn cfthread["localityVerbatimThread#tn#"].output>
</cffunction>

<!--- function getCollectingEventMediaHtml return a block of html with media associated with a collecting_event. 

   @param collecting_event_id the primary key value for the collecting_event for which to return media.
   @return block of html.
--->
<cffunction name="getCollectingEventMediaHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collecting_event_id" type="string" required="yes">
	
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="collEventMediaThread#tn#">
		<cfoutput>
			<cftry>
				<cfquery name="collEventMedia"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						media_id, media_relations_id
					FROM
						media_relations
					WHERE
						media_relationship like '% collecting_event'
						and
						related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#"> 
						and 
						MCZBASE.is_media_encumbered(media_id) < 1 
				</cfquery>
				<cfif collEventMedia.recordcount gt 0>
					<cfloop query="collEventMedia">
						<div class="col-6 p-1 col-sm-3 col-lg-3 col-xl-3 mb-1 px-md-2 pt-1 float-left border"> 
							<div id='ceMediaBlock#collEventMedia.media_id#'>
								<cfset mediaBlock= getMediaBlockHtmlUnthreaded(media_id="#collEventMedia.media_id#",size="350",captionAs="textShort")>
							</div>
							<div class="text-center">
								<a class="btn btn-xs btn-warning" onClick=" confirmDialog('Remove Relationship to this Media record?','Remove?', function() { removeMediaRelation('#collEventMedia.media_relations_id#'); }); ">Remove</a>
								<!--- assumes reloadMediaRelationships is in scope in page for reload --->
							</div>
						</div>
					</cfloop>
				</cfif>
			<cfcatch>
				<h3 class="h4 text-danger">Error: #cfcatch.type# #cfcatch.message#</h3> 
				<div>#cfcatch.detail#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="collEventMediaThread#tn#" />

	<cfreturn cfthread["collEventMediaThread#tn#"].output>
</cffunction>



<!--- function getCollectingEventUsesHtml return a block of html sumarizing the collecting events, 
   collections, and cataloged items associated with a collecting_event.

   @param collecting_event_id the primary key value for the collecting_event for which to return html.
   @return block of html.
--->
<cffunction name="getCollectingEventUsesHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collecting_event_id" type="string" required="yes">
	<cfargument name="context" type="string" required="no" default="view">
	
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfset variables.collecting_event_id = arguments.collecting_event_id>
	<cfset variables.context = arguments.context>
	<cfthread name="collectingEventUsesThread#tn#">
		<cfoutput>
			<cftry>
				<cfquery name="collectingEventUses" datasource="uam_god">
					SELECT
						count(cataloged_item.cat_num) numOfSpecs,
						collection.collection,
						collection.collection_cde,
						collection.collection_id,
						locality_id
					from
						collecting_event
						join cataloged_item on cataloged_item.collecting_event_id = collecting_event.collecting_event_id 
						left join collection on cataloged_item.collection_id = collection.collection_id
					WHERE
						collecting_event.collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
					GROUP BY
						collection.collection,
						collection.collection_cde,
						collection.collection_id,
						locality_id
			  	</cfquery>
				<div>
					<cfif #collectingEventUses.recordcount# is 0>
						<h2 class="h4 px-2">
							This CollectingEvent (#collecting_event_id#) contains no specimens. 
							<cfif isDefined("context") and context EQ "edit">
								Please delete it if you don&apos;t have plans for it!
							</cfif>
						</h2>
						<cfif isDefined("context") and context EQ "edit">
							<cfquery name="deleteBlocks" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								SELECT 
									count(*) ct, 'media' as block
								FROM media_relations
								WHERE
									related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
									and media_relationship like '% collecting_event'
									and media_id is not null
								UNION
								SELECT
									count(*) ct, 'number' as block
								FROM
									coll_event_number
								WHERE
									collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
									and coll_event_number_id is not null
							</cfquery>
							<cfset hasBlock = false>
							<cfloop query="deleteBlocks">
								<cfif deleteBlocks.ct GT 0>
									<cfset hasBlock = true>
								</cfif>
							</cfloop>
							<cfif NOT hasBlock>
								<!--- TODO: Post delete success handler --->
								<input type='button' value='Delete this Collecting Event' class='delBtn btn btn-xs btn-danger' onClick=" confirmDialog('Delete this collecting_event (#encodeForHtml(collecting_event_id)#)?', 'Confirm Delete Collecting Event', function() { deleteCollectingEvent(#collecting_event_id#,null); }  ); " >
							<cfelse>
								<div>
									Related media or collecting event numbers will have to be deleted first. (
									<cfset separator="">
									<cfloop query="deleteBlocks">
										#separator##block#:#ct#
										<cfset separator="; ">
									</cfloop>	
									)
								</div>
							</cfif>
						</cfif>
					<cfelseif #collectingEventUses.recordcount# is 1>
						<h2 class="h4 px-2">
							This CollectingEvent (#collecting_event_id#) contains 
							<a href="/Specimens.cfm?execute=true&builderMaxRows=1&action=builderSearch&nestdepth1=1&field1=COLLECTING_EVENT%3ACE_COLLECTING_EVENT_ID&searchText1=#collecting_event_id#">
								#collectingEventUses.numOfSpecs# #collectingEventUses.collection_cde# specimens
							</a>
							see <a href="/localities/CollectingEvents.cfm?execute=true&locality_id=#collectingEventUses.locality_id#&include_counts=true&include_ce_counts=true">other collecting events at this locality</a>.
						</h2>
					<cfelse>
						<cfset totalSpecimens=0>
						<cfloop query="collectingEventUses">
							<cfset totalSpecimens=totalSpecimens+collectingEventUses.numOfSpecs>
						</cfloop>
						<h2 class="h4 px-2">
							This CollectingEvent (#collecting_event_id#)
							contains the following <a href="/Specimens.cfm?execute=true&builderMaxRows=1&action=builderSearch&nestdepth1=1&field1=COLLECTING_EVENT%3ACE_COLLECTING_EVENT_ID&searchText1=#collecting_event_id#">#totalSpecimens# specimens</a>
						</h2>
						<ul class="px-2 pl-xl-4 ml-xl-1 small95">
							<cfloop query="collectingEventUses">
								<li>
									<cfif numOfSpecs EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
									<a href="/Specimens.cfm?execute=true&builderMaxRows=2&action=builderSearch&nestdepth1=1&field1=COLLECTING_EVENT%3ACE_COLLECTING_EVENT_ID&searchText1=#collecting_event_id#&nestdepth2=2&JoinOperator2=and&field2=CATALOGED_ITEM%3ACOLLECTION_CDE&searchText2=%3D#collectingEventUses.collection_cde#">
										#numOfSpecs# #collection_cde# specimen#plural#
									</a>
								</li>
							</cfloop>
						</ul>
					</cfif>
				</div>
			<cfcatch>
				<h2 class="h3 text-danger">Error: #cfcatch.type# #cfcatch.message#</h2> 
				<div>#cfcatch.detail#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="collectingEventUsesThread#tn#" />

	<cfreturn cfthread["collectingEventUsesThread#tn#"].output>
</cffunction>

<cffunction name="getCollectingEventSummary" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collecting_event_id" type="string" required="yes">

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfset  variables.collecting_event_id = arguments.collecting_event_id>
	<cfthread name="collEventSummaryThread#tn#">
		<cfoutput>
			<cftry>
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
				</cfif>
				<!--- potentially relevant actions: mask collector, mask coordinates, mask original field number. --->
				<cfquery name="getCollEventUp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getCollEventUp_result">
					SELECT higher_geog, geog_auth_rec.geog_auth_rec_id,
						began_date, ended_date,
						collecting_time, collecting_method, collecting_source,
						verbatim_date,
						locality.locality_id,
						verbatim_locality
					FROM
						collecting_event
						join locality on collecting_event.locality_id = locality.locality_id
						join geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
					WHERE
						collecting_event.collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
				</cfquery>
				<cfloop query="getCollEventUp">
					<div class="form-row">
					<div class="border-bottom float-left col-12 pb-2 h4">
						<div class="col-12 col-md-2 float-left px-0">Higher Geography:</div> 
						<div class="font-weight-normal col-12 col-md-1 px-0 pt-1 float-right">
							<a href="/localities/viewHigherGeography.cfm?geog_auth_rec_id=#geog_auth_rec_id#" class="btn btn-xs btn-primary text-center" target="_blank" >View</a>
						</div> 
						<div class="font-weight-normal col-12 col-md-11 px-0 float-left">#higher_geog# </div>
					
					</div>
					<cfset locality = getLocalitySummary(locality_id="#getCollEventUp.locality_id#")>
					<div class="border-bottom float-left col-12 pb-2 h4">
						<div class="col-12 col-md-2 float-left px-0">Locality:</div>	
						<div class="font-weight-normal col-12 col-md-1 px-0 pt-1 float-right">
							<a href="/localities/viewLocality.cfm?locality_id=#locality_id#" class="btn btn-xs btn-primary text-center" target="_blank" >View</a>
						</div>
						<div class="font-weight-normal col-12 col-md-11 px-0 float-left">#locality# </div>
					
					</div>
					<cfset datebit = "">
					<cfif len(began_date) GT 0>
						<cfif began_date EQ ended_date>
							<cfset datebit = began_date>
						<cfelse>
							<cfset datebit = "#began_date#/#ended_date#">
						</cfif>
					</cfif>
					<cfif len(collecting_time) GT 0>
						<cfset datebit = "#datebit# #collecting_time#">
					</cfif>
					<cfif len(verbatim_date) GT 0>
						<cfset datebit = "#datebit# [#verbatim_date#]">
					</cfif>
					<div class="float-left pb-0 col-12 h4">
						<div class="col-12 px-0">Event:</div>
						<div class="font-weight-normal col-12 px-0 float-left">#datebit# #collecting_method# #collecting_source# [#verbatim_locality#]</span></div>
					</div>
						</div>
				</cfloop>
			<cfcatch>
				<div class="border-bottom float-left pb-2 h4">Error: #cfcatch.type# #cfcatch.message#</div> 
				<div>#cfcatch.detail#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="collEventSummaryThread#tn#" />

	<cfreturn cfthread["collEventSummaryThread#tn#"].output>
</cffunction>

</cfcomponent>
