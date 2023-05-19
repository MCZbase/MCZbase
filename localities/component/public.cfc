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
<cf_rolecheck>

<cffunction name="getHigherGeographyMapHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="geog_auth_rec_id" type="string" required="yes">
	<cfargument name="reload" type="string" required="no">
	
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="geogMapThread#tn#">
		<cfoutput>
			<cftry>
				<cfif findNoCase('master',Session.gitBranch) EQ 0>
					<cfset editLocalityLinkTarget = "/localities/Locality.cfm?locality_id=">
				<cfelse>
					<cfset editLocalityLinkTarget = "/editLocality.cfm?locality_id=">
				</cfif>
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
					var georefsBounds = new google.maps.LatLngBounds();
					function setupMap(geog_auth_rec_id){
						var coords="0.0,0.0";
						var bounds = new google.maps.LatLngBounds();
						var polygonArray = [];
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
									var gbounds = new google.maps.LatLngBounds(); 
									map.data.forEach(function(feature){
										feature.getGeometry().forEachLatLng(function(latlng){
											gbounds.extend(latlng);
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
							for(var a=0; a<polygonArray.length; a++){
								if (! google.maps.geometry.poly.containsLocation(center, polygonArray[a]) ) {
									$("##mapdiv_" + geog_auth_rec_id).addClass('uglyGeoSPatData');
								} else {
									$("##mapdiv_" + geog_auth_rec_id).addClass('niceGeoSPatData');
								}
							}
						});
						map.fitBounds(bounds.union(georefsBounds));
					};
					$(document).ready(function() {
						setupMap(#geog_auth_rec_id#);
					});
				</script>
				<div class="mb-2 w-100" style="height: 600px;">
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
							<div class="h4 my-2">Higher Geography mappable
							<a role="button" class="btn btn-xs btn-powder-blue" onclick=" enclosingpoly.setVisible(!enclosingpoly.getVisible()); ">hide/show</a> 
							<a role="button" class="btn btn-xs btn-powder-blue" onclick=" map.fitBounds(findBounds(enclosingpoly.latLngs));">zoom to</a>
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
								<a role="button" class="btn btn-xs btn-powder-blue" onclick="map.fitBounds(georefsBounds); ">zoom to</a>
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

					function setupMap(locality_id){
						var bounds = new google.maps.LatLngBounds();
						var uncertaintyPolygonArray = [];
						var enclosingPolygonArray = [];
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
								for(var a=0; a<uncertaintyPolygonArray.length; a++){
									if (! google.maps.geometry.poly.containsLocation(center, uncertaintyPolygonArray[a]) ) {
										$("##mapdiv_" + locality_id).addClass('uglyGeoSPatData');
									} else {
										$("##mapdiv_" + locality_id).addClass('niceGeoSPatData');
									}
								}
							} else {
								$("##mapdiv_" + locality_id).addClass('noErrorWKT');
							}
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
							for(var a=0; a<enclosingPolygonArray.length; a++){
								if (georefs) { 
									// style map depending on overlap of georeference and enclosing polygon.
									if (! google.maps.geometry.poly.containsLocation(georefs, enclosingPolygonArray[a]) ) {
										$("##mapdiv_" + locality_id).addClass('uglyGeoSPatData');
										// accessible information
										$("##mapMetadataUL").append("<li class='list-style-circle'>Georeference for locality is outside of enclosing higher geography.</li>");
									} else {
										$("##mapdiv_" + locality_id).addClass('niceGeoSPatData');
									}
								}
							}
							if (bounds.getNorthEast().lat() > 89 || bounds.getSouthWest().lat() < -89) { 
								bounds = google.maps.LatLngBounds.MAX_BOUNDS;
							} 
							map.fitBounds(bounds);
						});
					}
					</cfif>
					$(document).ready(function() {
						setupMap(#locality_id#);
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
					<div class="h3 px-2">Map of Georeferences</div>
				<cfelse>
					<div class="h3 text-danger px-2">No accepted georeferences</div>
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
								<a role="button" class="btn btn-xs btn-powder-blue font-weight-lessbold"  onclick=" enclosingpoly.setVisible(!enclosingpoly.getVisible()); ">hide/show</a>
								<a role="button" class="btn btn-xs btn-powder-blue font-weight-lessbold" onclick=" map.fitBounds(findBounds(enclosingpoly.latLngs));">zoom to</a>
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
								<a role="button" class="btn btn-xs btn-powder-blue font-weight-lessbold" onclick=" uncertaintypoly.setVisible(!uncertaintypoly.getVisible()); ">hide/show</a> 
								<a role="button" class="btn btn-xs btn-powder-blue font-weight-lessbold" onclick=" map.fitBounds(findBounds(uncertaintypoly.latLngs));">zoom to</a>
							<cfelse>
								<span class="h5">No polygon with georeference</span>
							</cfif>
						</li>
						<li class="my-1 list-style-circle">
							<cfif getAcceptedGeoref.recordcount GT 0 AND getAcceptedGeoref.COORDINATEUNCERTAINTYINMETERS GT 0>
								<span class="h5">Coordinate uncertanty in meters = #getAcceptedGeoref.coordinateuncertaintyinmeters#</span> 
								<a role="button" class="btn btn-xs btn-powder-blue font-weight-lessbold" onclick=" errorcircle.setVisible(!errorcircle.getVisible()); ">hide/show</a> 
								<a role="button" class="btn btn-xs btn-powder-blue font-weight-lessbold" onclick=" map.fitBounds(errorcircle.getBounds());">zoom to</a>
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
								<a role="button" class="btn btn-xs btn-powder-blue font-weight-lessbold" onclick=" map.fitBounds(georefsBounds); ">zoom to</a>
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



</cfcomponent>
