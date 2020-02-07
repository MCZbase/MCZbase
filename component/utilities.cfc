<cfcomponent>
<cffunction name="getGeogWKT" returnType="string" access="remote">
	<cfargument name="locality_id" type="numeric" required="yes">
	<cfquery name="chkLatLong" datasource="uam_god">
		select * from lat_long where locality_id=#locality_id# and accepted_lat_long_fg=1 and error_polygon is not null
	</cfquery>
	<cfif chkLatLong.RecordCount EQ 1>
		<cfquery name="d" datasource="uam_god">
			select
				/*'POLYGON ((' || regexp_replace(regexp_replace(error_polygon,'([^,]*),([^,]*)[,]{0,1}','\2 \1,'), ',$', '') || '))' WKT_POLYGON*/
				error_polygon WKT_POLYGON
			from
				lat_long
			where
				accepted_lat_long_fg = 1 and
				locality_id=#locality_id#
		</cfquery>
	<cfelse>
		<cfquery name="d" datasource="uam_god">
			select
				WKT_POLYGON
			from
				geog_auth_rec,
				locality
			where
				geog_auth_rec.geog_auth_rec_id=locality.geog_auth_rec_id and
				locality.locality_id=#locality_id#
		</cfquery>
	</cfif>
	<cfif left(d.WKT_POLYGON,5) is 'MEDIA'>
		<cfset mid=listlast(d.WKT_POLYGON,':')>
		<cfquery name="m" datasource="uam_god">
			select media_uri from media where media_id=#mid#
		</cfquery>
		<cfhttp method="get" url="#m.media_uri#"></cfhttp>
		<cfreturn cfhttp.filecontent>
	<cfelse>
		<cfreturn d.WKT_POLYGON>
	</cfif>
</cffunction>
</cfcomponent>
