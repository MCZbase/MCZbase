Retrieving map data - please wait....
<cfflush>
<cfoutput>
	<cfif not isDefined("result_id") OR len(result_id) EQ 0>
		<cfthrow message= "Invalid call.  The parameter result_id must be specified for SpecimensByLocality.cfm">
	</cfif>
	<cfset dlPath = "#Application.webDirectory#/bnhmMaps/tabfiles/">
	<cfset dlFile = "tabfile#cfid##cftoken#.txt">
	<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT
			flatTable.collection_object_id,
			flatTable.cat_num,
			lat_long.dec_lat,
			lat_long.dec_long,
			decode(lat_long.accepted_lat_long_fg,
				1,'yes',
				0,'no') isAcceptedLatLong,
			to_meters(lat_long.max_error_distance,lat_long.max_error_units) errorInMeters,
			lat_long.datum,
			flatTable.scientific_name,
			flatTable.collection,
			flatTable.spec_locality,
			flatTable.locality_id,
			flatTable.verbatimLatitude,
			flatTable.verbatimLongitude,
			lat_long.lat_long_id
		 FROM
			<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
		 		flat 
			<cfelse>
				filtered_flat
			</cfif> as flatTable
		 	JOIN lat_long ON flatTable.locality_id = lat_long.locality_id
		 WHERE
		 	flatTable.locality_id IN (
		 		SELECT flatTable.locality_id 
				FROM 
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
				 		flat 
					<cfelse>
						filtered_flat
					</cfif> as flatTable
					JOIN user_search_table ON flatTable.collection_object_id = user_search_table.collection_object_id 
		 		WHERE
					user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
			)
	</cfquery>
	<cfquery name="loc" dbtype="query">
		select
			dec_lat,
			dec_long,
			isAcceptedLatLong,
			errorInMeters,
			datum,
			spec_locality,
			locality_id,
			verbatimLatitude,
			verbatimLongitude,
			lat_long_id
		from
			data
		group by
			dec_lat,
			dec_long,
			isAcceptedLatLong,
			errorInMeters,
			datum,
			spec_locality,
			locality_id,
			verbatimLatitude,
			verbatimLongitude,
			lat_long_id
	</cfquery>
	<cffile action="write" file="#dlPath##dlFile#" addnewline="no" output="" nameconflict="overwrite">
	<cfloop query="loc">
		<cfquery name="sdet" dbtype="query">
			select
				collection_object_id,
				cat_num,
				scientific_name,
				collection
			from
				data
			where
				locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
			group by
				collection_object_id,
				cat_num,
				scientific_name,
				collection
		</cfquery>
		<cfset specLink = "">
		<cfloop query="sdet">
			<cfset rColn = replace(collection," ","&nbsp;","all")>
			<cfset rName = replace(scientific_name," ","&nbsp;","all")>
			<cfset oneSpecLink = '<a href="#Application.serverRootUrl#/SpecimenDetail.cfm?collection_object_id=#collection_object_id#" target="_blank">#rColn#&nbsp;#cat_num#&nbsp;#rName#</a>'><!--- ' --->
			<cfif len(#specLink#) is 0>
				<cfset specLink = oneSpecLink>
			<cfelse>
				<cfset specLink = '#specLink#<br>#oneSpecLink#'>
			</cfif>
		</cfloop>
		<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_geography")>
			<cfset relInfo='<a href="#Application.ServerRootUrl#/localities/Locality.cfm?locality_id=#locality_id#" target="_blank">#spec_locality#</a>'><!--- ' --->
		<cfelse>
			<cfset relInfo='<a href="#Application.ServerRootUrl#/localities/viewLocality.cfm?locality_id=#locality_id#" target="_blank">#spec_locality#</a>'>
		</cfif>
		<cfset oneLine="#relInfo##chr(9)##locality_id##chr(9)##lat_long_id##chr(9)##spec_locality##chr(9)##dec_lat##chr(9)##dec_long##chr(9)##errorInMeters##chr(9)##datum##chr(9)##isAcceptedLatLong##chr(9)##specLink##chr(9)##verbatimLatitude#/#verbatimLongitude#">
		<cfset oneLine=trim(oneLine)>
		<cffile action="append" file="#dlPath##dlFile#" addnewline="yes" output="#oneLine#">
	</cfloop>
	<cfset bnhmUrl="http://berkeleymapper.berkeley.edu/?ViewResults=tab&tabfile=#Application.ServerRootUrl#/bnhmMaps/tabfiles/#dlFile#&configfile=#Application.ServerRootUrl#/bnhmMaps/SpecByLoc.xml&sourcename=Locality">
	<script type="text/javascript" language="javascript">
		document.location='#bnhmUrl#';
	</script>
</cfoutput>
