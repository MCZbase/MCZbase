<!---
localities/component/georefUtilties.cfc

Copyright 2020-2023 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Utility methods to support display of spatial information on maps.

--->
<cfcomponent>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">
<cf_rolecheck>

<!--- getGeogWKT given a locality_id return the error polygon if there is one, or if not the 
  polygon for the containing higher geography, can obtain the wkt from either
  geog_auth_rec.wkt_polygon/lat_long.error_polygon directly, or if these contain
  a value in the form "MEDIA:{media_id}" from a media record and the corresponding media_uri
  is a file containing WKT. 
  @param locality_id the primary key value for the locality for which to look up the error polygon.
  @return wkt representing a region around the georeferenced point
--->
<cffunction name="getGeogWKT" returnType="string" access="remote">
	<cfargument name="locality_id" type="numeric" required="yes">
	<cfquery name="chkLatLong" datasource="uam_god">
		SELECT * 
		FROM lat_long
		WHERE locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
			and accepted_lat_long_fg=1 
			and error_polygon is not null
	</cfquery>
	<cfif chkLatLong.RecordCount EQ 1>
		<cfquery name="d" datasource="uam_god">
			select
				/*'POLYGON ((' || regexp_replace(regexp_replace(error_polygon,'([^,]*),([^,]*)[,]{0,1}','\2 \1,'), ',$', '') || '))' WKT_POLYGON*/
				error_polygon WKT_POLYGON
			from
				lat_long
			where
				locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
				and accepted_lat_long_fg = 1
		</cfquery>
	<cfelse>
		<cfquery name="d" datasource="uam_god">
			select
				geog_auth_rec.WKT_POLYGON
			from
				locality 
				join geog_auth_rec on geog_auth_rec.geog_auth_rec_id=locality.geog_auth_rec_id
			where
				geog_auth_rec.wkt_polygon is not null 
				and locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
		</cfquery>
	</cfif>
	<cfif left(d.WKT_POLYGON,5) is 'MEDIA'>
		<cfset mid=listlast(d.WKT_POLYGON,':')>
		<cfquery name="m" datasource="uam_god">
			select media_uri 
			from media 
			where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#mid#">
		</cfquery>
		<cfhttp method="get" url="#m.media_uri#"></cfhttp>
		<cfreturn cfhttp.filecontent>
	<cfelse>
		<cfreturn d.WKT_POLYGON>
	</cfif>
</cffunction>

<!--- getGeoreferencErrorWKT given a locality_id return the error polygon for the accepted georeference if there is one.
  @param locality_id the primary key value for the locality for which to look up the error polygon.
  @return wkt representing a region around the georeferenced point
--->
<cffunction name="getGeoreferenceErrorWKT" returnType="string" access="remote">
	<cfargument name="locality_id" type="numeric" required="yes">
	<cfquery name="lookupPolygon" datasource="uam_god">
		SELECT
			error_polygon 
		FROM
			lat_long
		WHERE
			locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
			and accepted_lat_long_fg = 1
			and error_polygon is not null
	</cfquery>
	<cfif lookupPolygon.recordcount GT 0>
		<cfif left(lookupPolygon.error_polygon,5) is 'MEDIA'>
			<cfset media_id = listlast(lookupPolygon.ERROR_POLYGON,':')>
			<cfquery name="getMedia" datasource="uam_god">
				select media_uri 
				from media 
				where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
			</cfquery>
			<cfhttp method="get" url="#getMedia.media_uri#"></cfhttp>
			<cfreturn cfhttp.filecontent>
		<cfelse>
			<cfreturn lookupPolygon.error_polygon>
		</cfif>
	<cfelse>
		<cfreturn "">
	</cfif>
</cffunction>

<!--- getContainingGeographyWKT given a locality_id return the polygon for the containing higher geography, 
  can obtain the wkt from either geog_auth_rec.wkt_polygon directly or if it contains
  a value in the form "MEDIA:{media_id}" from a media record and the corresponding media_uri
  is a file containing WKT. 
  @param locality_id the primary key value for the locality for which to look up the containing 
    geography
  @return wkt representing a geographic region around the georeferenced point
--->
<cffunction name="getContainingGeographyWKT" returnType="string" access="remote">
	<cfargument name="locality_id" type="numeric" required="yes">
	<cfquery name="lookupPolygon" datasource="uam_god">
		select
			geog_auth_rec.WKT_POLYGON
		from
			locality 
			join geog_auth_rec on geog_auth_rec.geog_auth_rec_id=locality.geog_auth_rec_id
		where
			geog_auth_rec.wkt_polygon is not null 
			and locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
	</cfquery>
	<cfif lookupPolygon.recordcount GT 0>
		<cfif left(lookupPolygon.WKT_POLYGON,5) is 'MEDIA'>
			<cfset media_id=listlast(lookupPolygon.WKT_POLYGON,':')>
			<cfquery name="getMedia" datasource="uam_god">
				select media_uri 
				from media 
				where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
			</cfquery>
			<cfhttp method="get" url="#getMedia.media_uri#"></cfhttp>
			<cfreturn cfhttp.filecontent>
		<cfelse>
			<cfreturn lookupPolygon.WKT_POLYGON>
		</cfif>
	<cfelse>
		<cfreturn "">
	</cfif>
</cffunction>

<!--- getGeogographyWKT given a geog_auth_rec_id return the polygon for the higher geography, 
  can obtain the wkt from either geog_auth_rec.wkt_polygon directly or if it contains
  a value in the form "MEDIA:{media_id}" from a media record and the corresponding media_uri
  is a file containing WKT. 
  @param geog_auth_rec_id the primary key value for geography.
  @return wkt representing a geographic region around the georeferenced point
--->
<cffunction name="getGeographyWKT" returnType="string" access="remote">
	<cfargument name="geog_auth_rec_id" type="numeric" required="yes">
	<cfquery name="lookupPolygon" datasource="uam_god">
		select
			geog_auth_rec.WKT_POLYGON
		from
			geog_auth_rec 
		where
			geog_auth_rec.wkt_polygon is not null 
			and geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
	</cfquery>
	<cfif lookupPolygon.recordcount GT 0>
		<cfif left(lookupPolygon.WKT_POLYGON,5) is 'MEDIA'>
			<cfset media_id=listlast(lookupPolygon.WKT_POLYGON,':')>
			<cfquery name="getMedia" datasource="uam_god">
				select media_uri 
				from media 
				where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
			</cfquery>
			<cfhttp method="get" url="#getMedia.media_uri#"></cfhttp>
			<cfreturn cfhttp.filecontent>
		<cfelse>
			<cfreturn lookupPolygon.WKT_POLYGON>
		</cfif>
	<cfelse>
		<cfreturn "">
	</cfif>
</cffunction>

<!--- getGeorefesGeoJSON given a locality_id return the georeferencs, accepted and otherwise
  for the locality as geoJSON.
  @param locality_id the primary key value for the locality.
  @return geoJSON for the set georeferences or an http 500 on error
--->
<cffunction name="getGeorefsGeoJSON" returntype="any" returnformat="json" access="remote">
	<cfargument name="locality_id" type="numeric" required="yes">
	<cfargument name="debug" type="numeric" required="no">

	<cfset retval = '{ "type": "FeatureCollection", "features": ['>
	<cftry>
		<cfquery name="lookupGeorefs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT
				dec_lat, dec_long, datum,
				decode(accepted_lat_long_fg,0,'No',1,'Yes','No') accepted,
				to_meters(max_error_distance, max_error_units) coordinateuncertaintyinmeters,
				det_by.agent_name determiner,
				lat_long_id
			FROM
				lat_long
				left join preferred_agent_name det_by on determined_by_agent_id = det_by.agent_id
			WHERE
				locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
			ORDER BY
				accepted_lat_long_fg asc, determined_date, lat_long_id
		</cfquery>
		<cfset separator = " ">
		<cfloop query="lookupGeorefs">
			<cfset det = replace(determiner,'"','','All')><!--- remove quotes to embed in json --->
    		<cfset retval = '#retval##separator#{ "type": "Feature", "geometry": { "type": "Point", "coordinates": [#dec_long#, #dec_lat#] },'>
			<cfset retval = '#retval# "properties": { "id": "#lat_long_id#", "accepted": "#accepted#", "datum": "#datum#", "coordinateuncertaintyinmeters": "#coordinateuncertaintyinmeters#", "determiner": "#det#" }'>
			<cfset retval = "#retval# }">		
			<cfset separator = ",">
		</cfloop>
		<cfset retval = '#retval# ] }'>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfif isJSON(retval)>
		<cfreturn "#retval#">
	<cfelse>
		<cfif isDefined("debug") and debug EQ "true">
			<cfreturn "#retval#">
		<cfelse>
			<cfreturn "">
		</cfif>
	</cfif>
</cffunction>

<!--- getLocalityGeorefsGeoJSON given a geog_auth_rec_id return the accepted georeferences for
  localities with that higher geography.
  @param geog_auth_rec_id the primary key value for the higher geography.
  @return geoJSON for the set georeferences or an http 500 on error
--->
<cffunction name="getLocalityGeorefsGeoJSON" returntype="any" returnformat="json" access="remote">
	<cfargument name="geog_auth_rec_id" type="numeric" required="yes">
	<cfargument name="debug" type="numeric" required="no">

	<cfset retval = '{ "type": "FeatureCollection", "features": ['>
	<cftry>
		<cfquery name="lookupGeorefs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT
				spec_locality,
				dec_lat, dec_long, datum,
				decode(accepted_lat_long_fg,0,'No',1,'Yes','No') accepted,
				to_meters(max_error_distance, max_error_units) coordinateuncertaintyinmeters,
				det_by.agent_name determiner,
				lat_long_id
			FROM
				locality 
				join lat_long on locality.locality_id = lat_long.locality_id
				left join preferred_agent_name det_by on determined_by_agent_id = det_by.agent_id
			WHERE
				accepted_lat_long_fg = 1
				and
				geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
		</cfquery>
		<cfset separator = " ">
		<cfloop query="lookupGeorefs">
			<cfset det = replace(determiner,'"','','All')><!--- remove quotes to embed in json --->
			<cfset loc = replace(spec_locality,'"','','All')><!--- remove quotes to embed in json --->
    		<cfset retval = '#retval##separator#{ "type": "Feature", "geometry": { "type": "Point", "coordinates": [#dec_long#, #dec_lat#] },'>
			<cfset retval = '#retval# "properties": { "id": "#lat_long_id#", "accepted": "#accepted#", "datum": "#datum#", "coordinateuncertaintyinmeters": "#coordinateuncertaintyinmeters#", "determiner": "#det#", spec_locality: "#loc#" }'>
			<cfset retval = "#retval# }">		
			<cfset separator = ",">
		</cfloop>
		<cfset retval = '#retval# ] }'>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfif isJSON(retval)>
		<cfreturn "#retval#">
	<cfelse>
		<cfif isDefined("debug") and debug EQ "true">
			<cfreturn "#retval#">
		<cfelse>
			<cfreturn "">
		</cfif>
	</cfif>
</cffunction>

</cfcomponent>
