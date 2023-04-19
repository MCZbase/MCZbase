<cfcomponent>

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
			<cfset media_id = listlast(d.WKT_POLYGON,':')>
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
		<cfif left(d.WKT_POLYGON,5) is 'MEDIA'>
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

</cfcomponent>
