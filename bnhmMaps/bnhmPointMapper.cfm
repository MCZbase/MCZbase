<!---
bnhmPointMapper.cfm

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2026 President and Fellows of Harvard College

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
<cfparam name="url.locality_id" default="">

<cfset variables.locality_id = url.locality_id>

Retrieving map data - please wait....
<cfflush>

	<!---- map a lat_long_id ---->
	<cfif len(variables.locality_id) IS 0>
		You can't map a point without a locality_id.
		<cfabort>
	</cfif>
	<cfoutput>
	<cfquery name="getMapData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT
			locality.locality_id locality_id,
			lat_long_id,
			decode(accepted_lat_long_fg,
				1,'yes',
				0,'no') isAcceptedLatLong,
			spec_locality,
			dec_lat,
			dec_long,
			to_meters(max_error_distance,max_error_units) max_error_meters,
			datum
		FROM lat_long,locality
		WHERE
			locality.locality_id = lat_long.locality_id AND
			locality.locality_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" list="true" value="#variables.locality_id#">)
	</cfquery>
	</cfoutput>

<cfset dlPath = "#Application.webDirectory#/bnhmMaps/tabfiles/">
<cfset dlFile = "tabfile#cookie.cfid##cookie.cftoken#.txt">
<cffile action="write" file="#dlPath##dlFile#" addnewline="no" output="" nameconflict="overwrite">
<cfoutput query="getMapData">
	<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_geography")>
		<cfset relInfo='<a href="#Application.ServerRootUrl#/localities/Locality.cfm?locality_id=#locality_id#" target="_blank">#spec_locality#</a>'><!--- ' --->
	<cfelse>
		<cfset relInfo='<a href="#Application.ServerRootUrl#/localities/viewLocality.cfm?locality_id=#locality_id#" target="_blank">#spec_locality#</a>'>
	</cfif>
	<cfset oneLine="#relInfo##chr(9)##locality_id##chr(9)##lat_long_id##chr(9)##spec_locality##chr(9)##dec_lat##chr(9)##dec_long##chr(9)##max_error_meters##chr(9)##datum##chr(9)##isAcceptedLatLong#">


	<cfset oneLine=trim(oneLine)>
	<cffile action="append" file="#dlPath##dlFile#" addnewline="yes" output="#oneLine#">
</cfoutput>
<cfoutput>


	<cfset bnhmUrl="http://berkeleymapper.berkeley.edu/?ViewResults=tab&tabfile=#Application.ServerRootUrl#/bnhmMaps/tabfiles/#dlFile#&configfile=#Application.ServerRootUrl#/bnhmMaps/PointMap.xml&sourcename=Locality">


	<script type="text/javascript" language="javascript">
		document.location='#bnhmUrl#';
	</script>
</cfoutput>
