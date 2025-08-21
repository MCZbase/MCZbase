<!---
localities/component/combined.cfc

Backing method for handling combined editing of locality and collecting event data, along with associated helper functions.

Copyright 2025 President and Fellows of Harvard College

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
<cfinclude template="/shared/component/functions.cfc" runOnce="true"><!--- For getCommentForField, reportError --->
<cfinclude template="/dataquality/component/functions.cfc" runOnce="true"><!--- For interpretDate --->
<cfinclude template="/localities/component/functions.cfc" runOnce="true"><!--- For updateGeoreference --->
<cf_rolecheck>

<cffunction name="handleCombinedEditForm" access="remote" returntype="any" returnformat="json">
	<cfargument name="action" type="string" required="yes">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="collecting_event_id" type="string" required="no">
	<cfargument name="locality_id" type="string" required="yes">
	<cfargument name="geog_auth_rec_id" type="string" required="yes">
	<cfargument name="spec_locality" type="string" required="yes">
	<cfargument name="sovereign_nation" type="string" required="no">
	<cfargument name="curated_fg" type="string" required="no">
	<cfargument name="MINIMUM_ELEVATION" type="string" required="no">
	<cfargument name="MAXIMUM_ELEVATION" type="string" required="no">
	<cfargument name="ORIG_ELEV_UNITS" type="string" required="no">
	<cfargument name="MIN_DEPTH" type="string" required="no">
	<cfargument name="MAX_DEPTH" type="string" required="no">
	<cfargument name="DEPTH_UNITS" type="string" required="no">
	<cfargument name="township" type="string" required="no">
	<cfargument name="township_direction" type="string" required="no">
	<cfargument name="range" type="string" required="no">
	<cfargument name="range_direction" type="string" required="no">
	<cfargument name="section" type="string" required="no">
	<cfargument name="section_part" type="string" required="no">
	<cfargument name="locality_remarks" type="string" required="no">
	<cfargument name="nogeorefbecause" type="string" required="no" default="">
	<cfargument name="geology_data" type="string" required="no" default="">
	<cfargument name="geology_attributes_to_delete" type="string" required="no" default="">
	<cfargument name="geology_row_count" type="string" required="no" default="">
	<cfargument name="coll_event_numbers_data" type="string" required="no" default="">
	<cfargument name="coll_event_numbers_to_delete" type="string" required="no" default="">
	<cfargument name="coll_event_number_row_count" type="string" required="no" default="">
	<cfargument name="began_date" type="string" required="yes">
	<cfargument name="ended_date" type="string" required="yes">
	<cfargument name="verbatim_date" type="string" required="yes">
	<cfargument name="collecting_source" type="string" required="yes">
	<cfargument name="verbatim_habitat" type="string" required="no">
	<cfargument name="verbatim_locality" type="string" required="no">
	<cfargument name="verbatimDepth" type="string" required="no">
	<cfargument name="verbatimelevation" type="string" required="no">
	<cfargument name="coll_event_remarks" type="string" required="no">
	<cfargument name="collecting_method" type="string" required="no">
	<cfargument name="habitat_desc" type="string" required="no">
	<cfargument name="collecting_time" type="string" required="no">
	<cfargument name="fish_field_number" type="string" required="no">
	<cfargument name="verbatimcoordinates" type="string" required="no">
	<cfargument name="verbatimlatitude" type="string" required="no">
	<cfargument name="verbatimlongitude" type="string" required="no">
	<cfargument name="verbatimcoordinatesystem" type="string" required="no">
	<cfargument name="verbatimsrs" type="string" required="no">
	<cfargument name="startdayofyear" type="string" required="no">
	<cfargument name="enddayofyear" type="string" required="no">
	<cfargument name="date_determined_by_agent_id" type="string" required="no">
	<cfargument name="valid_distribution_fg" type="string" required="no">
	<cfargument name="verbatim_collectors" type="string" required="no">
	<cfargument name="verbatim_field_numbers" type="string" required="no">
	<cfargument name="lat_long_id" type="string" required="no">
	<cfargument name="field_mapping" type="string" required="no">
	<cfargument name="accepted_lat_long_fg" type="string" required="no">
	<cfargument name="orig_lat_long_units" type="string" required="no">
	<cfargument name="datum" type="string" required="no">
	<cfargument name="lat_long_ref_source" type="string" required="no">
	<cfargument name="determined_by_agent_id" type="string" required="no">
	<cfargument name="verified_by_agent_id" type="string" required="no">
	<cfargument name="determined_date" type="string" required="no">
	<cfargument name="georefmethod" type="string" required="no">
	<cfargument name="verificationstatus" type="string" required="no">
	<cfargument name="extent" type="string" required="no">
	<cfargument name="extent_units" type="string" required="no">
	<cfargument name="spatialfit" type="string" required="no">
	<cfargument name="gpsaccuracy" type="string" required="no">
	<cfargument name="max_error_distance" type="string" required="no">
	<cfargument name="max_error_units" type="string" required="no">
	<cfargument name="lat_long_remarks" type="string" required="no">
	<cfargument name="lat_deg" type="string" required="no">
	<cfargument name="long_deg" type="string" required="no">
	<cfargument name="dec_lat_min" type="string" required="no">
	<cfargument name="dec_long_min" type="string" required="no">
	<cfargument name="lat_min" type="string" required="no">
	<cfargument name="lat_sec" type="string" required="no">
	<cfargument name="lat_dir" type="string" required="no">
	<cfargument name="long_min" type="string" required="no">
	<cfargument name="long_sec" type="string" required="no">
	<cfargument name="long_dir" type="string" required="no">
	<cfargument name="nearest_named_place" type="string" required="no">
	<cfargument name="lat_long_for_nnp_fg" type="string" required="no">
	<cfargument name="footprint_spatialfit" type="string" required="no">

	<cfset data = ArrayNew(1)>
	<cftry>
		<!--- Check user permissions first --->
		<cfset checkUserPermissions()>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>

	<cftransaction>
		<cftry>
			<!--- Get record counts to evaluate action --->
			<cfset recordCounts = getRecordCounts(arguments.collecting_event_id, arguments.locality_id)>
			<cfset cecount = recordCounts.cecount>
			<cfset loccount = recordCounts.loccount>

			<cfif cecount.ct EQ 1 AND loccount.ct EQ 1 AND arguments.action EQ "splitAndSave">
				<cfthrow message="Collecting Event and Locality are unique to this cataloged item, no need to split, split and save should not be enabled.">
			</cfif>

			<cfif arguments.action EQ "splitAndSave">
				<cfset handleSplitAndSave(
				    action=arguments.action,
				    collection_object_id=arguments.collection_object_id,
				    collecting_event_id=arguments.collecting_event_id,
				    locality_id=arguments.locality_id,
				    geog_auth_rec_id=arguments.geog_auth_rec_id,
				    spec_locality=arguments.spec_locality,
				    sovereign_nation=arguments.sovereign_nation,
				    curated_fg=arguments.curated_fg,
				    MINIMUM_ELEVATION=arguments.MINIMUM_ELEVATION,
				    MAXIMUM_ELEVATION=arguments.MAXIMUM_ELEVATION,
				    ORIG_ELEV_UNITS=arguments.ORIG_ELEV_UNITS,
				    MIN_DEPTH=arguments.MIN_DEPTH,
				    MAX_DEPTH=arguments.MAX_DEPTH,
				    DEPTH_UNITS=arguments.DEPTH_UNITS,
				    township=arguments.township,
				    township_direction=arguments.township_direction,
				    range=arguments.range,
				    range_direction=arguments.range_direction,
				    section=arguments.section,
				    section_part=arguments.section_part,
				    locality_remarks=arguments.locality_remarks,
				    nogeorefbecause=arguments.nogeorefbecause,
				    geology_data=arguments.geology_data,
				    geology_attributes_to_delete=arguments.geology_attributes_to_delete,
				    geology_row_count=arguments.geology_row_count,
				    coll_event_numbers_data=arguments.coll_event_numbers_data,
				    coll_event_numbers_to_delete=arguments.coll_event_numbers_to_delete,
				    coll_event_number_row_count=arguments.coll_event_number_row_count,
				    began_date=arguments.began_date,
				    ended_date=arguments.ended_date,
				    verbatim_date=arguments.verbatim_date,
				    collecting_source=arguments.collecting_source,
				    verbatim_habitat=arguments.verbatim_habitat,
				    verbatim_locality=arguments.verbatim_locality,
				    verbatimDepth=arguments.verbatimDepth,
				    verbatimelevation=arguments.verbatimelevation,
				    coll_event_remarks=arguments.coll_event_remarks,
				    collecting_method=arguments.collecting_method,
				    habitat_desc=arguments.habitat_desc,
				    collecting_time=arguments.collecting_time,
				    fish_field_number=arguments.fish_field_number,
				    verbatimcoordinates=arguments.verbatimcoordinates,
				    verbatimlatitude=arguments.verbatimlatitude,
				    verbatimlongitude=arguments.verbatimlongitude,
				    verbatimcoordinatesystem=arguments.verbatimcoordinatesystem,
				    verbatimsrs=arguments.verbatimsrs,
				    startdayofyear=arguments.startdayofyear,
				    enddayofyear=arguments.enddayofyear,
				    date_determined_by_agent_id=arguments.date_determined_by_agent_id,
				    valid_distribution_fg=arguments.valid_distribution_fg,
				    verbatim_collectors=arguments.verbatim_collectors,
				    verbatim_field_numbers=arguments.verbatim_field_numbers,
				    cecount=cecount,
				    loccount=loccount,
					 lat_long_id=arguments.lat_long_id,
					 field_mapping=arguments.field_mapping,
					 accepted_lat_long_fg=arguments.accepted_lat_long_fg,
					 orig_lat_long_units=arguments.orig_lat_long_units,
					 datum=arguments.datum,
					 lat_long_ref_source = arguments.lat_long_ref_source,
					 determined_by_agent_id = arguments.determined_by_agent_id,
					 verified_by_agent_id = arguments.verified_by_agent_id,
					 determined_date = arguments.determined_date,
					 georefmethod = arguments.georefmethod,
					 verificationstatus = arguments.verificationstatus,
					 extent = arguments.extent,
					 extent_units = arguments.extent_units,
					 spatialfit = arguments.spatialfit,
					 gpsaccuracy = arguments.gpsaccuracy,
					 max_error_distance = arguments.max_error_distance,
					 max_error_units = arguments.max_error_units,
					 lat_long_remarks = arguments.lat_long_remarks,
					 lat_deg = arguments.lat_deg,
					 long_deg = arguments.long_deg,
					 dec_lat_min = arguments.dec_lat_min,
					 dec_long_min = arguments.dec_long_min,
					 lat_min = arguments.lat_min,
					 lat_sec = arguments.lat_sec,
					 lat_dir = arguments.lat_dir,
					 long_min = arguments.long_min,
					 long_sec = arguments.long_sec,
					 long_dir = arguments.long_dir,
					 geolocate_uncertaintypolygon = arguments.geolocate_uncertaintypolygon,
					 geolocate_score = arguments.geolocate_score,
					 geolocate_precision = arguments.geolocate_precision,
					 geolocate_num_results = arguments.geolocate_num_results,
					 geolocate_parsepattern = arguments.geolocate_parsepattern,
					 nearest_named_place = arguments.nearest_named_place,
					 lat_long_for_nnp_fg = arguments.lat_long_for_nnp_fg,
					 footprint_spatialfit = arguments.footprint_spatialfit
				)>
			<cfelseif arguments.action EQ "saveCurrent">
				<cfset handleSaveCurrent(
				    action=arguments.action,
				    collection_object_id=arguments.collection_object_id,
				    collecting_event_id=arguments.collecting_event_id,
				    locality_id=arguments.locality_id,
				    geog_auth_rec_id=arguments.geog_auth_rec_id,
				    spec_locality=arguments.spec_locality,
				    sovereign_nation=arguments.sovereign_nation,
				    curated_fg=arguments.curated_fg,
				    MINIMUM_ELEVATION=arguments.MINIMUM_ELEVATION,
				    MAXIMUM_ELEVATION=arguments.MAXIMUM_ELEVATION,
				    ORIG_ELEV_UNITS=arguments.ORIG_ELEV_UNITS,
				    MIN_DEPTH=arguments.MIN_DEPTH,
				    MAX_DEPTH=arguments.MAX_DEPTH,
				    DEPTH_UNITS=arguments.DEPTH_UNITS,
				    township=arguments.township,
				    township_direction=arguments.township_direction,
				    range=arguments.range,
				    range_direction=arguments.range_direction,
				    section=arguments.section,
				    section_part=arguments.section_part,
				    locality_remarks=arguments.locality_remarks,
				    nogeorefbecause=arguments.nogeorefbecause,
				    geology_data=arguments.geology_data,
				    geology_attributes_to_delete=arguments.geology_attributes_to_delete,
				    geology_row_count=arguments.geology_row_count,
				    coll_event_numbers_data=arguments.coll_event_numbers_data,
				    coll_event_numbers_to_delete=arguments.coll_event_numbers_to_delete,
				    coll_event_number_row_count=arguments.coll_event_number_row_count,
				    began_date=arguments.began_date,
				    ended_date=arguments.ended_date,
				    verbatim_date=arguments.verbatim_date,
				    collecting_source=arguments.collecting_source,
				    verbatim_habitat=arguments.verbatim_habitat,
				    verbatim_locality=arguments.verbatim_locality,
				    verbatimDepth=arguments.verbatimDepth,
				    verbatimelevation=arguments.verbatimelevation,
				    coll_event_remarks=arguments.coll_event_remarks,
				    collecting_method=arguments.collecting_method,
				    habitat_desc=arguments.habitat_desc,
				    collecting_time=arguments.collecting_time,
				    fish_field_number=arguments.fish_field_number,
				    verbatimcoordinates=arguments.verbatimcoordinates,
				    verbatimlatitude=arguments.verbatimlatitude,
				    verbatimlongitude=arguments.verbatimlongitude,
				    verbatimcoordinatesystem=arguments.verbatimcoordinatesystem,
				    verbatimsrs=arguments.verbatimsrs,
				    startdayofyear=arguments.startdayofyear,
				    enddayofyear=arguments.enddayofyear,
				    date_determined_by_agent_id=arguments.date_determined_by_agent_id,
				    valid_distribution_fg=arguments.valid_distribution_fg,
				    verbatim_collectors=arguments.verbatim_collectors,
				    verbatim_field_numbers=arguments.verbatim_field_numbers,
				    cecount=cecount,
				    loccount=loccount,
					 lat_long_id=arguments.lat_long_id,
					 field_mapping=arguments.field_mapping,
					 accepted_lat_long_fg=arguments.accepted_lat_long_fg,
					 orig_lat_long_units=arguments.orig_lat_long_units,
					 datum=arguments.datum,
					 lat_long_ref_source = arguments.lat_long_ref_source,
					 determined_by_agent_id = arguments.determined_by_agent_id,
					 verified_by_agent_id = arguments.verified_by_agent_id,
					 determined_date = arguments.determined_date,
					 georefmethod = arguments.georefmethod,
					 verificationstatus = arguments.verificationstatus,
					 extent = arguments.extent,
					 extent_units = arguments.extent_units,
					 spatialfit = arguments.spatialfit,
					 gpsaccuracy = arguments.gpsaccuracy,
					 max_error_distance = arguments.max_error_distance,
					 max_error_units = arguments.max_error_units,
					 lat_long_remarks = arguments.lat_long_remarks,
					 lat_deg = arguments.lat_deg,
					 long_deg = arguments.long_deg,
					 dec_lat_min = arguments.dec_lat_min,
					 dec_long_min = arguments.dec_long_min,
					 lat_min = arguments.lat_min,
					 lat_sec = arguments.lat_sec,
					 lat_dir = arguments.lat_dir,
					 long_min = arguments.long_min,
					 long_sec = arguments.long_sec,
					 long_dir = arguments.long_dir,
					 geolocate_uncertaintypolygon = arguments.geolocate_uncertaintypolygon,
					 geolocate_score = arguments.geolocate_score,
					 geolocate_precision = arguments.geolocate_precision,
					 geolocate_num_results = arguments.geolocate_num_results,
					 geolocate_parsepattern = arguments.geolocate_parsepattern,
					 nearest_named_place = arguments.nearest_named_place,
					 lat_long_for_nnp_fg = arguments.lat_long_for_nnp_fg,
					 footprint_spatialfit = arguments.footprint_spatialfit
				)>
			<cfelse>
				<cfthrow message="Unknown action #encodeForHtml(arguments.action)#">
			</cfif>

			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["id"] = "#arguments.collection_object_id#">
			<cfset data[1] = row>
			<cftransaction action="commit"/>
		<cfcatch>
			<cftransaction action="rollback"/>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		<cffinally>
			<cfset ensureTriggerEnabled()>
		</cffinally>	
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- Helper function to check user permissions --->
<cffunction name="checkUserPermissions" access="private" returntype="void">
	<cfquery name="checkLocalityPriv" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="checkLocalityPriv_result">
		SELECT COUNT(*) ct
		FROM (
			SELECT 'DIRECT' AS source
			FROM USER_TAB_PRIVS
			WHERE TABLE_NAME = 'LOCALITY'
				AND PRIVILEGE = 'INSERT'
				AND OWNER = 'MCZBASE'
		UNION
			SELECT 'ROLE' AS source
			FROM ROLE_TAB_PRIVS rtp
			JOIN USER_ROLE_PRIVS urp ON rtp.ROLE = urp.GRANTED_ROLE
			WHERE rtp.TABLE_NAME = 'LOCALITY'
				AND rtp.PRIVILEGE = 'INSERT'
				AND rtp.OWNER = 'MCZBASE'
		)
	</cfquery>
	<cfif checkLocalityPriv.ct EQ 0>
		<cfthrow message="You do not have permission to edit locality records.">
	</cfif>
	<cfquery name="getCollectingPriv" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getCollectingPriv_result">
		SELECT COUNT(*) ct
		FROM (
			SELECT 'DIRECT' AS source
			FROM USER_TAB_PRIVS
			WHERE TABLE_NAME = 'COLLECTING_EVENT'
				AND PRIVILEGE = 'INSERT'
				AND OWNER = 'MCZBASE'
		UNION
			SELECT 'ROLE' AS source
			FROM ROLE_TAB_PRIVS rtp
			JOIN USER_ROLE_PRIVS urp ON rtp.ROLE = urp.GRANTED_ROLE
			WHERE rtp.TABLE_NAME = 'COLLECTING_EVENT'
				AND rtp.PRIVILEGE = 'INSERT'
				AND rtp.OWNER = 'MCZBASE'
		)
	</cfquery>
	<cfif getCollectingPriv.ct EQ 0>
		<cfthrow message="You do not have permission to edit collecting event records.">
	</cfif>
</cffunction>

<!--- Helper function to get record counts --->
<cffunction name="getRecordCounts" access="private" returntype="struct">
	<cfargument name="collecting_event_id" type="string" required="yes">
	<cfargument name="locality_id" type="string" required="yes">
	
	<cfquery name="cecount" datasource="uam_god">
		SELECT count(collection_object_id) ct 
		FROM cataloged_item
		WHERE collecting_event_id = <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value = "#arguments.collecting_event_id#">
	</cfquery>
	<cfquery name="loccount" datasource="uam_god">
		SELECT count(ci.collection_object_id) ct 
		FROM cataloged_item ci
			left join collecting_event on ci.collecting_event_id = collecting_event.collecting_event_id
		WHERE collecting_event.locality_id = <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value = "#arguments.locality_id#">
	</cfquery>
	
	<cfset result = StructNew()>
	<cfset result.cecount = cecount>
	<cfset result.loccount = loccount>
	<cfreturn result>
</cffunction>

<!--- Helper function to handle splitAndSave action --->
<cffunction name="handleSplitAndSave" access="private" returntype="void">
	<cfargument name="action" type="string" required="yes">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="collecting_event_id" type="string" required="yes">
	<cfargument name="locality_id" type="string" required="yes">
	<cfargument name="geog_auth_rec_id" type="string" required="yes">
	<cfargument name="spec_locality" type="string" required="yes">
	<cfargument name="sovereign_nation" type="string" required="no">
	<cfargument name="curated_fg" type="string" required="no">
	<cfargument name="MINIMUM_ELEVATION" type="string" required="no">
	<cfargument name="MAXIMUM_ELEVATION" type="string" required="no">
	<cfargument name="ORIG_ELEV_UNITS" type="string" required="no">
	<cfargument name="MIN_DEPTH" type="string" required="no">
	<cfargument name="MAX_DEPTH" type="string" required="no">
	<cfargument name="DEPTH_UNITS" type="string" required="no">
	<cfargument name="township" type="string" required="no">
	<cfargument name="township_direction" type="string" required="no">
	<cfargument name="range" type="string" required="no">
	<cfargument name="range_direction" type="string" required="no">
	<cfargument name="section" type="string" required="no">
	<cfargument name="section_part" type="string" required="no">
	<cfargument name="locality_remarks" type="string" required="no">
	<cfargument name="nogeorefbecause" type="string" required="no">
	<cfargument name="geology_data" type="string" required="no">
	<cfargument name="geology_attributes_to_delete" type="string" required="no">
	<cfargument name="geology_row_count" type="string" required="no">
	<cfargument name="coll_event_numbers_data" type="string" required="no">
	<cfargument name="coll_event_numbers_to_delete" type="string" required="no">
	<cfargument name="coll_event_number_row_count" type="string" required="no">
	<cfargument name="began_date" type="string" required="yes">
	<cfargument name="ended_date" type="string" required="yes">
	<cfargument name="verbatim_date" type="string" required="yes">
	<cfargument name="collecting_source" type="string" required="yes">
	<cfargument name="verbatim_habitat" type="string" required="no">
	<cfargument name="verbatim_locality" type="string" required="no">
	<cfargument name="verbatimDepth" type="string" required="no">
	<cfargument name="verbatimelevation" type="string" required="no">
	<cfargument name="coll_event_remarks" type="string" required="no">
	<cfargument name="collecting_method" type="string" required="no">
	<cfargument name="habitat_desc" type="string" required="no">
	<cfargument name="collecting_time" type="string" required="no">
	<cfargument name="fish_field_number" type="string" required="no">
	<cfargument name="verbatimcoordinates" type="string" required="no">
	<cfargument name="verbatimlatitude" type="string" required="no">
	<cfargument name="verbatimlongitude" type="string" required="no">
	<cfargument name="verbatimcoordinatesystem" type="string" required="no">
	<cfargument name="verbatimsrs" type="string" required="no">
	<cfargument name="startdayofyear" type="string" required="no">
	<cfargument name="enddayofyear" type="string" required="no">
	<cfargument name="date_determined_by_agent_id" type="string" required="no">
	<cfargument name="valid_distribution_fg" type="string" required="no">
	<cfargument name="verbatim_collectors" type="string" required="no">
	<cfargument name="verbatim_field_numbers" type="string" required="no">
	<cfargument name="cecount" type="query" required="yes">
	<cfargument name="loccount" type="query" required="yes">
	<cfargument name="lat_long_id" type="string" required="yes">
	<cfargument name="field_mapping" type="string" required="yes">
	<cfargument name="accepted_lat_long_fg" type="string" required="yes">
	<cfargument name="orig_lat_long_units" type="string" required="yes">
	<cfargument name="datum" type="string" required="yes">
	<cfargument name="lat_long_ref_source" type="string" required="no">
	<cfargument name="determined_by_agent_id" type="string" required="yes">
	<cfargument name="verified_by_agent_id" type="string" required="no">
	<cfargument name="determined_date" type="string" required="no">
	<cfargument name="georefmethod" type="string" required="no">
	<cfargument name="verificationstatus" type="string" required="yes">
	<cfargument name="extent" type="string" required="no">
	<cfargument name="extent_units" type="string" required="no">
	<cfargument name="spatialfit" type="string" required="no">
	<cfargument name="gpsaccuracy" type="string" required="no">
	<cfargument name="max_error_distance" type="string" required="yes">
	<cfargument name="max_error_units" type="string" required="yes">
	<cfargument name="lat_long_remarks" type="string" required="no">
	<cfargument name="lat_deg" type="string" required="no">
	<cfargument name="long_deg" type="string" required="no">
	<cfargument name="dec_lat_min" type="string" required="no">
	<cfargument name="dec_long_min" type="string" required="no">
	<cfargument name="lat_min" type="string" required="no">
	<cfargument name="lat_sec" type="string" required="no">
	<cfargument name="lat_dir" type="string" required="no">
	<cfargument name="long_min" type="string" required="no">
	<cfargument name="long_sec" type="string" required="no">
	<cfargument name="long_dir" type="string" required="no">
	<cfargument name="nearest_named_place" type="string" required="no">
	<cfargument name="lat_long_for_nnp_fg" type="string" required="no">
	<cfargument name="footprint_spatialfit" type="string" required="no">
	
	<!--- Create new locality --->
	<cfset new_locality_id = createNewLocality(
		geog_auth_rec_id=arguments.geog_auth_rec_id,
		spec_locality=arguments.spec_locality,
		sovereign_nation=arguments.sovereign_nation,
		curated_fg=arguments.curated_fg,
		MINIMUM_ELEVATION=arguments.MINIMUM_ELEVATION,
		MAXIMUM_ELEVATION=arguments.MAXIMUM_ELEVATION,
		ORIG_ELEV_UNITS=arguments.ORIG_ELEV_UNITS,
		MIN_DEPTH=arguments.MIN_DEPTH,
		MAX_DEPTH=arguments.MAX_DEPTH,
		DEPTH_UNITS=arguments.DEPTH_UNITS,
		township=arguments.township,
		township_direction=arguments.township_direction,
		range=arguments.range,
		range_direction=arguments.range_direction,
		section=arguments.section,
		section_part=arguments.section_part,
		locality_remarks=arguments.locality_remarks,
		nogeorefbecause=arguments.nogeorefbecause
	)>
	
	<!--- Clone georeference if exists --->
	<cfset new_lat_long_id = cloneGeoreference(arguments.locality_id, new_locality_id)>
	
	<cfif len(new_lat_long_id) GT 0>
		<!--- Update the cloned georeference from the submitted form fields related to the georeference --->
		<cfset updateGeoreference(		
			lat_long_id=new_lat_long_id,
			field_mapping="generic",
			accepted_lat_long_fg=arguments.accepted_lat_long_fg,
			orig_lat_long_units=arguments.orig_lat_long_units,
			datum=arguments.datum,
			lat_long_ref_source=arguments.lat_long_ref_source,
			determined_by_agent_id=arguments.determined_by_agent_id,
			verified_by_agent_id=arguments.verified_by_agent_id,
			determined_date=arguments.determined_date,
			georefmethod=arguments.georefmethod,
			verificationstatus=arguments.verificationstatus,
			extent=arguments.extent,
			extent_units=arguments.extent_units,
			spatialfit=arguments.spatialfit,
			gpsaccuracy=arguments.gpsaccuracy,
			max_error_distance=arguments.max_error_distance,
			max_error_units=arguments.max_error_units,
			lat_long_remarks=arguments.lat_long_remarks,
			dec_lat="",
			dec_long="",
			lat_deg=arguments.lat_deg,
			long_deg=arguments.long_deg,
			nearest_named_place=arguments.nearest_named_place,
			lat_long_for_nnp_fg=arguments.lat_long_for_nnp_fg,
			footprint_spatialfit=arguments.footprint_spatialfit
		)>
	</cfif>
	
	<!--- Handle geology attributes --->
	<cfset handleGeologyAttributes(arguments.geology_data, new_locality_id, "insert")>
	
	<cfif arguments.cecount.ct EQ 1 AND arguments.loccount.ct GT 1>
		<!--- Update existing collecting event to point to new locality --->
		<cfset updateCollectingEventLocality(
			collecting_event_id=arguments.collecting_event_id, 
			new_locality_id=new_locality_id,
			began_date=arguments.began_date,
			ended_date=arguments.ended_date,
			verbatim_date=arguments.verbatim_date,
			collecting_source=arguments.collecting_source,
			verbatim_habitat=arguments.verbatim_habitat,
			verbatim_locality=arguments.verbatim_locality,
			verbatimDepth=arguments.verbatimDepth,
			verbatimelevation=arguments.verbatimelevation,
			coll_event_remarks=arguments.coll_event_remarks,
			collecting_method=arguments.collecting_method,
			habitat_desc=arguments.habitat_desc,
			collecting_time=arguments.collecting_time,
			fish_field_number=arguments.fish_field_number,
			verbatimcoordinates=arguments.verbatimcoordinates,
			verbatimlatitude=arguments.verbatimlatitude,
			verbatimlongitude=arguments.verbatimlongitude,
			verbatimcoordinatesystem=arguments.verbatimcoordinatesystem,
			verbatimsrs=arguments.verbatimsrs,
			startdayofyear=arguments.startdayofyear,
			enddayofyear=arguments.enddayofyear,
			date_determined_by_agent_id=arguments.date_determined_by_agent_id,
			valid_distribution_fg=arguments.valid_distribution_fg,
			verbatim_collectors=arguments.verbatim_collectors,
			verbatim_field_numbers=arguments.verbatim_field_numbers
		)>
	<cfelse>
		<!--- Create new collecting event --->
		<cfset new_collecting_event_id = createNewCollectingEvent(
			new_locality_id=new_locality_id,
			began_date=arguments.began_date,
			ended_date=arguments.ended_date,
			verbatim_date=arguments.verbatim_date,
			collecting_source=arguments.collecting_source,
			verbatim_habitat=arguments.verbatim_habitat,
			verbatim_locality=arguments.verbatim_locality,
			verbatimDepth=arguments.verbatimDepth,
			verbatimelevation=arguments.verbatimelevation,
			coll_event_remarks=arguments.coll_event_remarks,
			collecting_method=arguments.collecting_method,
			habitat_desc=arguments.habitat_desc,
			collecting_time=arguments.collecting_time,
			fish_field_number=arguments.fish_field_number,
			verbatimcoordinates=arguments.verbatimcoordinates,
			verbatimlatitude=arguments.verbatimlatitude,
			verbatimlongitude=arguments.verbatimlongitude,
			verbatimcoordinatesystem=arguments.verbatimcoordinatesystem,
			verbatimsrs=arguments.verbatimsrs,
			startdayofyear=arguments.startdayofyear,
			enddayofyear=arguments.enddayofyear,
			date_determined_by_agent_id=arguments.date_determined_by_agent_id,
			valid_distribution_fg=arguments.valid_distribution_fg,
			verbatim_collectors=arguments.verbatim_collectors,
			verbatim_field_numbers=arguments.verbatim_field_numbers
		)>
		
		<!--- Handle collecting event numbers --->
		<cfif isDefined("arguments.coll_event_numbers_data")>
			<cfset handleCollEventNumbersSplitAndSave(arguments.coll_event_numbers_data, new_collecting_event_id)>
		</cfif>
		
		<!--- Update cataloged item to point to new collecting event --->
		<cfset updateCatalogedItemCollectingEvent(arguments.collection_object_id, new_collecting_event_id)>
	</cfif>
</cffunction>

<!--- Helper function to handle saveCurrent action --->
<cffunction name="handleSaveCurrent" access="private" returntype="void">
	<cfargument name="action" type="string" required="yes">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="collecting_event_id" type="string" required="yes">
	<cfargument name="locality_id" type="string" required="yes">
	<cfargument name="geog_auth_rec_id" type="string" required="yes">
	<cfargument name="spec_locality" type="string" required="yes">
	<cfargument name="sovereign_nation" type="string" required="no">
	<cfargument name="curated_fg" type="string" required="no">
	<cfargument name="MINIMUM_ELEVATION" type="string" required="no">
	<cfargument name="MAXIMUM_ELEVATION" type="string" required="no">
	<cfargument name="ORIG_ELEV_UNITS" type="string" required="no">
	<cfargument name="MIN_DEPTH" type="string" required="no">
	<cfargument name="MAX_DEPTH" type="string" required="no">
	<cfargument name="DEPTH_UNITS" type="string" required="no">
	<cfargument name="township" type="string" required="no">
	<cfargument name="township_direction" type="string" required="no">
	<cfargument name="range" type="string" required="no">
	<cfargument name="range_direction" type="string" required="no">
	<cfargument name="section" type="string" required="no">
	<cfargument name="section_part" type="string" required="no">
	<cfargument name="locality_remarks" type="string" required="no">
	<cfargument name="nogeorefbecause" type="string" required="no">
	<cfargument name="geology_data" type="string" required="no">
	<cfargument name="geology_attributes_to_delete" type="string" required="no">
	<cfargument name="geology_row_count" type="string" required="no">
	<cfargument name="coll_event_numbers_data" type="string" required="no">
	<cfargument name="coll_event_numbers_to_delete" type="string" required="no">
	<cfargument name="coll_event_number_row_count" type="string" required="no">
	<cfargument name="began_date" type="string" required="yes">
	<cfargument name="ended_date" type="string" required="yes">
	<cfargument name="verbatim_date" type="string" required="yes">
	<cfargument name="collecting_source" type="string" required="yes">
	<cfargument name="verbatim_habitat" type="string" required="no">
	<cfargument name="verbatim_locality" type="string" required="no">
	<cfargument name="verbatimDepth" type="string" required="no">
	<cfargument name="verbatimelevation" type="string" required="no">
	<cfargument name="coll_event_remarks" type="string" required="no">
	<cfargument name="collecting_method" type="string" required="no">
	<cfargument name="habitat_desc" type="string" required="no">
	<cfargument name="collecting_time" type="string" required="no">
	<cfargument name="fish_field_number" type="string" required="no">
	<cfargument name="verbatimcoordinates" type="string" required="no">
	<cfargument name="verbatimlatitude" type="string" required="no">
	<cfargument name="verbatimlongitude" type="string" required="no">
	<cfargument name="verbatimcoordinatesystem" type="string" required="no">
	<cfargument name="verbatimsrs" type="string" required="no">
	<cfargument name="startdayofyear" type="string" required="no">
	<cfargument name="enddayofyear" type="string" required="no">
	<cfargument name="date_determined_by_agent_id" type="string" required="no">
	<cfargument name="valid_distribution_fg" type="string" required="no">
	<cfargument name="verbatim_collectors" type="string" required="no">
	<cfargument name="verbatim_field_numbers" type="string" required="no">
	<cfargument name="cecount" type="query" required="yes">
	<cfargument name="loccount" type="query" required="yes">
	<cfargument name="lat_long_id" type="string" required="yes">
	<cfargument name="field_mapping" type="string" required="yes">
	<cfargument name="accepted_lat_long_fg" type="string" required="yes">
	<cfargument name="orig_lat_long_units" type="string" required="yes">
	<cfargument name="datum" type="string" required="yes">
	<cfargument name="lat_long_ref_source" type="string" required="no">
	<cfargument name="determined_by_agent_id" type="string" required="yes">
	<cfargument name="verified_by_agent_id" type="string" required="no">
	<cfargument name="determined_date" type="string" required="no">
	<cfargument name="georefmethod" type="string" required="no">
	<cfargument name="verificationstatus" type="string" required="yes">
	<cfargument name="extent" type="string" required="no">
	<cfargument name="extent_units" type="string" required="no">
	<cfargument name="spatialfit" type="string" required="no">
	<cfargument name="gpsaccuracy" type="string" required="no">
	<cfargument name="max_error_distance" type="string" required="yes">
	<cfargument name="max_error_units" type="string" required="yes">
	<cfargument name="lat_long_remarks" type="string" required="no">
	<cfargument name="lat_deg" type="string" required="no">
	<cfargument name="long_deg" type="string" required="no">
	<cfargument name="dec_lat_min" type="string" required="no">
	<cfargument name="dec_long_min" type="string" required="no">
	<cfargument name="lat_min" type="string" required="no">
	<cfargument name="lat_sec" type="string" required="no">
	<cfargument name="lat_dir" type="string" required="no">
	<cfargument name="long_min" type="string" required="no">
	<cfargument name="long_sec" type="string" required="no">
	<cfargument name="long_dir" type="string" required="no">
	<cfargument name="nearest_named_place" type="string" required="no">
	<cfargument name="lat_long_for_nnp_fg" type="string" required="no">
	<cfargument name="footprint_spatialfit" type="string" required="no">
	
	<cfif arguments.cecount.ct GT 1 OR arguments.loccount.ct GT 1>
		<cfthrow message="Collecting Event or Locality are shared with other cataloged items, cannot save changes to shared records, use split and save instead.">
	</cfif>
	
	<!--- Validate elevation and depth data --->
	<cfset validateElevationDepthData(
		MINIMUM_ELEVATION=arguments.MINIMUM_ELEVATION,
		MAXIMUM_ELEVATION=arguments.MAXIMUM_ELEVATION,
		ORIG_ELEV_UNITS=arguments.ORIG_ELEV_UNITS,
		MIN_DEPTH=arguments.MIN_DEPTH,
		MAX_DEPTH=arguments.MAX_DEPTH,
		DEPTH_UNITS=arguments.DEPTH_UNITS
	)>
	
	<!--- Update existing locality --->
	<cfset updateExistingLocality(
		locality_id=arguments.locality_id,
		geog_auth_rec_id=arguments.geog_auth_rec_id,
		spec_locality=arguments.spec_locality,
		sovereign_nation=arguments.sovereign_nation,
		curated_fg=arguments.curated_fg,
		MINIMUM_ELEVATION=arguments.MINIMUM_ELEVATION,
		MAXIMUM_ELEVATION=arguments.MAXIMUM_ELEVATION,
		ORIG_ELEV_UNITS=arguments.ORIG_ELEV_UNITS,
		MIN_DEPTH=arguments.MIN_DEPTH,
		MAX_DEPTH=arguments.MAX_DEPTH,
		DEPTH_UNITS=arguments.DEPTH_UNITS,
		township=arguments.township,
		township_direction=arguments.township_direction,
		range=arguments.range,
		range_direction=arguments.range_direction,
		section=arguments.section,
		section_part=arguments.section_part,
		locality_remarks=arguments.locality_remarks,
		nogeorefbecause=arguments.nogeorefbecause
	)>
	
	<!--- Handle geology attributes --->
	<cfset handleGeologyAttributes(arguments.geology_data, arguments.locality_id, "update")>
	<cfset deleteGeologyAttributes(arguments.geology_attributes_to_delete)>
	
	<!--- update existing georeference if exists --->
	<cfif len(arguments.lat_long_id) GT 0>
		<cfset updateGeoreference(		
			lat_long_id=arguments.lat_long_id,
			field_mapping="generic",
			accepted_lat_long_fg=arguments.accepted_lat_long_fg,
			orig_lat_long_units=arguments.orig_lat_long_units,
			datum=arguments.datum,
			lat_long_ref_source=arguments.lat_long_ref_source,
			determined_by_agent_id=arguments.determined_by_agent_id,
			verified_by_agent_id=arguments.verified_by_agent_id,
			determined_date=arguments.determined_date,
			georefmethod=arguments.georefmethod,
			verificationstatus=arguments.verificationstatus,
			extent=arguments.extent,
			extent_units=arguments.extent_units,
			spatialfit=arguments.spatialfit,
			gpsaccuracy=arguments.gpsaccuracy,
			max_error_distance=arguments.max_error_distance,
			max_error_units=arguments.max_error_units,
			lat_long_remarks=arguments.lat_long_remarks,
			dec_lat="",
			dec_long="",
			dec_lat_min=arguments.dec_lat_min,	
			dec_long_min=arguments.dec_long_min,
			lat_deg=arguments.lat_deg,
			long_deg=arguments.long_deg,
			lat_min=arguments.dec_lat_min,
			long_min=arguments.dec_long_min,
			lat_sec=arguments.lat_sec,
			long_sec=arguments.long_sec,
			lat_dir=arguments.lat_dir,
			long_dir=arguments.long_dir,
			nearest_named_place=arguments.nearest_named_place,
			lat_long_for_nnp_fg=arguments.lat_long_for_nnp_fg,
			footprint_spatialfit=arguments.footprint_spatialfit
		)>
	</cfif>

	<!--- Handle collecting event numbers --->
	<cfif isDefined("arguments.coll_event_numbers_data") OR isDefined("arguments.coll_event_numbers_to_delete")>
		<cfset handleCollEventNumbersSaveCurrent(
			isDefined("arguments.coll_event_numbers_data") ? arguments.coll_event_numbers_data : "",
			isDefined("arguments.coll_event_numbers_to_delete") ? arguments.coll_event_numbers_to_delete : "",
			arguments.collecting_event_id
		)>
	</cfif>
	
	<!--- Update existing collecting event --->
	<cfset updateExistingCollectingEvent(
		collecting_event_id=arguments.collecting_event_id,
		locality_id=arguments.locality_id,
		began_date=arguments.began_date,
		ended_date=arguments.ended_date,
		verbatim_date=arguments.verbatim_date,
		collecting_source=arguments.collecting_source,
		verbatim_habitat=arguments.verbatim_habitat,
		verbatim_locality=arguments.verbatim_locality,
		verbatimDepth=arguments.verbatimDepth,
		verbatimelevation=arguments.verbatimelevation,
		coll_event_remarks=arguments.coll_event_remarks,
		collecting_method=arguments.collecting_method,
		habitat_desc=arguments.habitat_desc,
		collecting_time=arguments.collecting_time,
		fish_field_number=arguments.fish_field_number,
		verbatimcoordinates=arguments.verbatimcoordinates,
		verbatimlatitude=arguments.verbatimlatitude,
		verbatimlongitude=arguments.verbatimlongitude,
		verbatimcoordinatesystem=arguments.verbatimcoordinatesystem,
		verbatimsrs=arguments.verbatimsrs,
		startdayofyear=arguments.startdayofyear,
		enddayofyear=arguments.enddayofyear,
		date_determined_by_agent_id=arguments.date_determined_by_agent_id,
		valid_distribution_fg=arguments.valid_distribution_fg,
		verbatim_collectors=arguments.verbatim_collectors,
		verbatim_field_numbers=arguments.verbatim_field_numbers
	)>
</cffunction>

<!--- Helper function to validate elevation and depth data --->
<cffunction name="validateElevationDepthData" access="private" returntype="void">
	<cfargument name="MINIMUM_ELEVATION" type="string" required="no">
	<cfargument name="MAXIMUM_ELEVATION" type="string" required="no">
	<cfargument name="ORIG_ELEV_UNITS" type="string" required="no">
	<cfargument name="MIN_DEPTH" type="string" required="no">
	<cfargument name="MAX_DEPTH" type="string" required="no">
	<cfargument name="DEPTH_UNITS" type="string" required="no">
	
	<cfif len(arguments.MINIMUM_ELEVATION) gt 0 OR len(arguments.MAXIMUM_ELEVATION) gt 0>
		<cfif not isDefined("arguments.ORIG_ELEV_UNITS") OR len(arguments.ORIG_ELEV_UNITS) is 0>
			<cfthrow message="You must provide elevation units if you provide elevation data.">
		</cfif>
	</cfif>
	<cfif len(arguments.MIN_DEPTH) gt 0 OR len(arguments.MAX_DEPTH) gt 0>
		<cfif not isDefined("arguments.DEPTH_UNITS") OR len(arguments.DEPTH_UNITS) is 0>
			<cfthrow message="You must provide depth units if you provide depth data.">
		</cfif>
	</cfif>
</cffunction>

<!--- Helper function to create new locality --->
<cffunction name="createNewLocality" access="private" returntype="string">
	<cfargument name="geog_auth_rec_id" type="string" required="yes">
	<cfargument name="spec_locality" type="string" required="yes">
	<cfargument name="sovereign_nation" type="string" required="no">
	<cfargument name="curated_fg" type="string" required="no">
	<cfargument name="MINIMUM_ELEVATION" type="string" required="no">
	<cfargument name="MAXIMUM_ELEVATION" type="string" required="no">
	<cfargument name="ORIG_ELEV_UNITS" type="string" required="no">
	<cfargument name="MIN_DEPTH" type="string" required="no">
	<cfargument name="MAX_DEPTH" type="string" required="no">
	<cfargument name="DEPTH_UNITS" type="string" required="no">
	<cfargument name="township" type="string" required="no">
	<cfargument name="township_direction" type="string" required="no">
	<cfargument name="range" type="string" required="no">
	<cfargument name="range_direction" type="string" required="no">
	<cfargument name="section" type="string" required="no">
	<cfargument name="section_part" type="string" required="no">
	<cfargument name="locality_remarks" type="string" required="no">
	<cfargument name="nogeorefbecause" type="string" required="no">
	
	<!--- Calculate scales for decimal precision --->
	<cfif len(arguments.MAXIMUM_ELEVATION) GT 0>
		<cfset max_elev_scale = len(rereplace(arguments.MAXIMUM_ELEVATION,'^[0-9-]*[.]',''))>
	</cfif>
	<cfif len(arguments.MINIMUM_ELEVATION) GT 0>
		<cfset min_elev_scale = len(rereplace(arguments.MINIMUM_ELEVATION,'^[0-9-]*[.]',''))>
	</cfif>
	<cfif len(arguments.MAX_DEPTH) GT 0>
		<cfset max_depth_scale = len(rereplace(arguments.MAX_DEPTH,'^[0-9-]*[.]',''))>
	</cfif>
	<cfif len(arguments.MIN_DEPTH) GT 0>
		<cfset min_depth_scale = len(rereplace(arguments.MIN_DEPTH,'^[0-9-]*[.]',''))>
	</cfif>

	<cfquery name="newLocality" datasource="uam_god" result="newLocality_result">
		INSERT INTO locality 
		(
			locality_id,
			geog_auth_rec_id, spec_locality, curated_fg, 
			MINIMUM_ELEVATION, MAXIMUM_ELEVATION, ORIG_ELEV_UNITS,
			min_depth, max_depth, depth_units,
			township, township_direction, range, range_direction, section, section_part,
			locality_remarks, nogeorefbecause, sovereign_nation
		) VALUES (
			sq_locality_id.NEXTVAL,
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.geog_auth_rec_id#">,
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.spec_locality#">,
			<cfif isdefined("arguments.curated_fg") AND len(arguments.curated_fg) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.curated_fg#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.MINIMUM_ELEVATION) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="#min_elev_scale#" value="#arguments.MINIMUM_ELEVATION#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.MAXIMUM_ELEVATION) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="#max_elev_scale#" value="#arguments.MAXIMUM_ELEVATION#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.ORIG_ELEV_UNITS) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.ORIG_ELEV_UNITS#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.MIN_DEPTH) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="#min_depth_scale#" value="#arguments.MIN_DEPTH#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.MAX_DEPTH) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="#max_depth_scale#" value="#arguments.MAX_DEPTH#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.DEPTH_UNITS) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.DEPTH_UNITS#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.township) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.township#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.township_direction) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.township_direction#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.range) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.range#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.range_direction) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.range_direction#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.section) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.section#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.section_part) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.section_part#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.locality_remarks) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.locality_remarks#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.nogeorefbecause) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.nogeorefbecause#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.sovereign_nation) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.sovereign_nation#">
			<cfelse>
				null
			</cfif>
		)
	</cfquery>
	
	<cfif newLocality_result.recordcount is 0>
		<cfthrow message="Error creating new locality record.">
	</cfif>
	
	<cfquery name="getLocalityID" datasource="uam_god" result="getLocalityID_result">
		SELECT locality_id
		FROM locality
		WHERE ROWIDTOCHAR(rowid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newLocality_result.GENERATEDKEY#">
	</cfquery>
	
	<cfif len(getLocalityID.locality_id) is 0>
		<cfthrow message="Error obtaining new locality ID.">
	</cfif>
	
	<cfreturn getLocalityID.locality_id>
</cffunction>

<!--- Helper function to clone a georeference for a locality.
  @param source_locality_id: ID of the locality to clone from
  @param target_locality_id: ID of the locality to clone to
  @return lat_long_id of the newly cloned georeference, or an empty string if there is no georeference to clone.
 --->
<cffunction name="cloneGeoreference" access="private" returntype="void">
	<cfargument name="source_locality_id" type="string" required="yes">
	<cfargument name="target_locality_id" type="string" required="yes">
	
	<cfset retval = ""><!--- default return value --->
	<cfquery name="getCurrentGeoref" datasource="uam_god" result="getCurrentGeoref_result">
		SELECT lat_long_id
		FROM lat_long
		WHERE locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.source_locality_id#">
		AND accepted_lat_long_fg = 1
	</cfquery>
	
	<cfif getCurrentGeoref.recordcount EQ 1>
		<!--- disable trigger to allow cloning of lat_long_id --->
		<cfquery name="disableTrigger" datasource="uam_god" result="disableTrigger_result">
			ALTER TRIGGER TR_LATLONG_ACCEPTED_BIUPA DISABLE
		</cfquery>
		<!--- obtain id of next lat_long_id --->
		<cfquery name="getNextLatLongID" datasource="uam_god" result="getNextLatLongID_result">
			SELECT sq_lat_long_id.NEXTVAL AS next_lat_long_id
			FROM dual
		</cfquery>
		<cfif getNextLatLongID_result.recordcount NEQ 1>
			<cfthrow message="Error obtaining next lat_long_id.">
		</cfif>
		<cfset next_lat_long_id = getNextLatLongID.next_lat_long_id>
		<!--- Clone georeference from source locality to target locality --->
		<cfquery name="cloneGeoref" datasource="uam_god" result="cloneGeoref_result">
			INSERT INTO LAT_LONG (
				lat_long_id, locality_id, lat_deg, dec_lat_min, lat_min, lat_sec, lat_dir,
				long_deg, dec_long_min, long_min, long_sec, long_dir,
				dec_lat, dec_long, datum, utm_zone, utm_ew, utm_ns,
				orig_lat_long_units, determined_by_agent_id, determined_date,
				lat_long_ref_source, lat_long_remarks, max_error_distance,
				max_error_units, nearest_named_place, lat_long_for_nnp_fg,
				field_verified_fg, accepted_lat_long_fg, extent,
				gpsaccuracy, georefmethod, verificationstatus,
				spatialfit, geolocate_uncertaintypolygon,
				geolocate_score, geolocate_precision,
				geolocate_numresults, geolocate_parsepattern,
				verified_by_agent_id, error_polygon,
				coordinate_precision, footprint_spatialfit,
				extent_units
			)
			SELECT 
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#next_lat_long_id#"> lat_long_id,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.target_locality_id#"> locality_id,
				lat_deg, dec_lat_min, lat_min, lat_sec, lat_dir,
				long_deg, dec_long_min, long_min, long_sec, long_dir,
				dec_lat, dec_long, datum, utm_zone, utm_ew, utm_ns,
				orig_lat_long_units, determined_by_agent_id, determined_date,
				lat_long_ref_source, lat_long_remarks, max_error_distance,
				max_error_units, nearest_named_place, lat_long_for_nnp_fg,
				field_verified_fg, accepted_lat_long_fg, extent,
				gpsaccuracy, georefmethod, verificationstatus,
				spatialfit, geolocate_uncertaintypolygon,
				geolocate_score, geolocate_precision,
				geolocate_numresults, geolocate_parsepattern,
				verified_by_agent_id, error_polygon,
				coordinate_precision, footprint_spatialfit,
				extent_units
			FROM lat_long
			WHERE locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.source_locality_id#">
			AND accepted_lat_long_fg = 1
		</cfquery>
		<cfquery name="enableTrigger" datasource="uam_god" result="enableTrigger_result">
			ALTER TRIGGER TR_LATLONG_ACCEPTED_BIUPA ENABLE
		</cfquery>
		<cfset retval = next_lat_long_id>
	</cfif>
	<cfif cloneGeoref_result.recordcount EQ 0>
		<cfthrow message="Error cloning georeference for locality ID #arguments.source_locality_id#.">
	</cfif>
	<cfreturn retval>
</cffunction>

<!--- Helper function to handle geology attributes --->
<cffunction name="handleGeologyAttributes" access="private" returntype="void">
	<cfargument name="geology_data" type="string" required="yes">
	<cfargument name="locality_id" type="string" required="yes">
	<cfargument name="action" type="string" required="yes">
	
	<cfif len(arguments.geology_data) GT 0>
		<cfset geology_data = deserializeJSON(urlDecode(arguments.geology_data))>
		<cfif isArray(geology_data)>
			<cfloop array="#geology_data#" index="geoAtt">
				<cfset processGeologyAttribute(geoAtt, arguments.locality_id, arguments.action)>
			</cfloop>
		</cfif>
	</cfif>
</cffunction>

<!--- Helper function to process individual geology attribute --->
<cffunction name="processGeologyAttribute" access="private" returntype="void">
	<cfargument name="geoAtt" type="struct" required="yes">
	<cfargument name="locality_id" type="string" required="yes">
	<cfargument name="action" type="string" required="yes">
	
	<cfset geoDo = "">
	<cfif arguments.action EQ "insert" OR len(arguments.geoAtt.geology_attribute_id) EQ 0>
		<cfset geoDo = 'insert'>
	<cfelse>
		<cfquery name="checkGeologyAttribute" datasource="uam_god" result="checkGeologyAttribute_result">
			SELECT count(*) ct 
			FROM geology_attributes
			WHERE geology_attribute_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.geoAtt.geology_attribute_id#">
		</cfquery>
		<cfif checkGeologyAttribute.ct EQ 1>
			<cfset geoDo = "update">
		<cfelse>
			<cfset geoDo = "insert">
		</cfif>
	</cfif>
	
	<cfif geoDo EQ "insert"> 
		<cfset insertGeologyAttribute(arguments.geoAtt, arguments.locality_id)>
	<cfelse> 
		<cfset updateOnlyGeologyAttribute(arguments.geoAtt, arguments.locality_id)>
	</cfif>
	
	<!--- Handle parent hierarchy if requested --->
	<cfif isDefined("arguments.geoAtt.add_parents") AND ucase(arguments.geoAtt.add_parents) EQ "YES">
		<cfset addGeologyAttributeParents(arguments.geoAtt, arguments.locality_id)>
	</cfif>
</cffunction>


<!--- Helper function to handle collecting event numbers for splitAndSave action --->
<cffunction name="handleCollEventNumbersSplitAndSave" access="private" returntype="void">
	<cfargument name="coll_event_numbers_data" type="string" required="yes">
	<cfargument name="new_collecting_event_id" type="string" required="yes">
	
	<cfif len(arguments.coll_event_numbers_data) GT 0>
		<cfset var collEventNumbersArray = deserializeJSON(urlDecode(arguments.coll_event_numbers_data))>
		<cfif isArray(collEventNumbersArray)>
			<cfloop array="#collEventNumbersArray#" index="collEventNum">
				<cfquery name="insertCollEventNumber" datasource="uam_god" result="insertCollEventNumber_result">
					INSERT INTO coll_event_number (
						coll_event_number_id, collecting_event_id, coll_event_num_series_id, coll_event_number
					) VALUES (
						coll_event_number_seq.NEXTVAL,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.new_collecting_event_id#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collEventNum.coll_event_num_series_id#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collEventNum.coll_event_number#">
					)
				</cfquery>
			</cfloop>
		</cfif>
	</cfif>
</cffunction>

<!--- Helper function to handle collecting event numbers for saveCurrent action --->
<cffunction name="handleCollEventNumbersSaveCurrent" access="private" returntype="void">
	<cfargument name="coll_event_numbers_data" type="string" required="yes">
	<cfargument name="coll_event_numbers_to_delete" type="string" required="yes">
	<cfargument name="collecting_event_id" type="string" required="yes">
	
	<!--- Handle updates/inserts --->
	<cfif len(arguments.coll_event_numbers_data) GT 0>
		<cfset var collEventNumbersArray = deserializeJSON(urlDecode(arguments.coll_event_numbers_data))>
		<cfif isArray(collEventNumbersArray)>
			<cfloop array="#collEventNumbersArray#" index="collEventNum">
				<cfset var collEventNumDo = "">
				<cfif len(collEventNum.coll_event_number_id) EQ 0>
					<cfset collEventNumDo = 'insert'>
				<cfelse>
					<cfif len(collEventNum.coll_event_number_id) GT 0>
						<cfquery name="checkCollEventNumber" datasource="uam_god" result="checkCollEventNumber_result">
							SELECT count(*) ct 
							FROM coll_event_number
							WHERE coll_event_number_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collEventNum.coll_event_number_id#">
						</cfquery>
						<cfif checkCollEventNumber.ct EQ 1>
							<cfset collEventNumDo = "update">
						<cfelse>
							<cfset collEventNumDo = "insert">
						</cfif>
					<cfelse>
						<cfset collEventNumDo = "insert">
					</cfif>
				</cfif>
				<cfif collEventNumDo EQ "insert"> 
					<cfquery name="insertCollEventNumber" datasource="uam_god" result="insertCollEventNumber_result">
						INSERT INTO coll_event_number (
							coll_event_number_id, collecting_event_id, coll_event_num_series_id, coll_event_number
						) VALUES (
							coll_event_number_seq.NEXTVAL,
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collecting_event_id#">,
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collEventNum.coll_event_num_series_id#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collEventNum.coll_event_number#">
						)
					</cfquery>
				<cfelse> 
					<cfquery name="updateCollEventNumber" datasource="uam_god" result="updateCollEventNumber_result">
						UPDATE coll_event_number 
						SET
							collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collecting_event_id#">,
							coll_event_num_series_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collEventNum.coll_event_num_series_id#">,
							coll_event_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collEventNum.coll_event_number#">
						WHERE 
							coll_event_number_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collEventNum.coll_event_number_id#">
					</cfquery>
				</cfif>
			</cfloop>
		</cfif>
	</cfif>
	
	<!--- Handle deletions --->
	<cfif len(arguments.coll_event_numbers_to_delete) GT 0>
		<cfloop list="#arguments.coll_event_numbers_to_delete#" index="collEventNumIDToDelete">
			<cfif len(collEventNumIDToDelete) GT 0>
				<cfquery name="deleteCollEventNumber" datasource="uam_god" result="deleteCollEventNumber_result">
					DELETE FROM coll_event_number
					WHERE coll_event_number_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collEventNumIDToDelete#">
				</cfquery>
			</cfif>
		</cfloop>
	</cfif>
</cffunction>

<!--- Helper function to insert geology attribute --->
<cffunction name="insertGeologyAttribute" access="private" returntype="void">
	<cfargument name="geoAtt" type="struct" required="yes">
	<cfargument name="locality_id" type="string" required="yes">
	
	<cfquery name="insertGeologyAttribute" datasource="uam_god" result="insertGeologyAttribute_result">
		INSERT INTO geology_attributes (
			GEOLOGY_ATTRIBUTE_ID, 
			GEOLOGY_ATTRIBUTE, GEO_ATT_VALUE,
			GEO_ATT_DETERMINER_ID, GEO_ATT_DETERMINED_DATE, GEO_ATT_DETERMINED_METHOD,
			GEO_ATT_REMARK,
			LOCALITY_ID,
			previous_values
		) VALUES (
			sq_geology_attribute_id.NEXTVAL,
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.geoAtt.GEOLOGY_ATTRIBUTE#">,
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.geoAtt.GEO_ATT_VALUE#">,
			<cfif len(arguments.geoAtt.GEO_ATT_DETERMINER_ID) GT 0>
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.geoAtt.GEO_ATT_DETERMINER_ID#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.geoAtt.GEO_ATT_DETERMINED_DATE) GT 0>
				<cfqueryparam cfsqltype="CF_SQL_DATE" value="#dateFormat(arguments.geoAtt.GEO_ATT_DETERMINED_DATE,'yyyy-mm-dd')#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.geoAtt.GEO_ATT_DETERMINED_METHOD) GT 0>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.geoAtt.GEO_ATT_DETERMINED_METHOD#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.geoAtt.GEO_ATT_REMARK) GT 0>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.geoAtt.GEO_ATT_REMARK#">,
			<cfelse>
				null,
			</cfif>
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.locality_id#">,
			null
		)
	</cfquery>
</cffunction>

<!--- Helper function to update geology attribute --->
<cffunction name="updateOnlyGeologyAttribute" access="private" returntype="void">
	<cfargument name="geoAtt" type="struct" required="yes">
	<cfargument name="locality_id" type="string" required="yes">
	
	<cfquery name="updateGeologyAttribute" datasource="uam_god" result="updateGeologyAttribute_result">
		UPDATE geology_attributes 
		SET
		 	LOCALITY_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.locality_id#">,
			GEOLOGY_ATTRIBUTE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.geoAtt.GEOLOGY_ATTRIBUTE#">,
			<cfif len(arguments.geoAtt.GEO_ATT_DETERMINER_ID) GT 0>
				GEO_ATT_DETERMINER_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.geoAtt.GEO_ATT_DETERMINER_ID#">,
			<cfelse>
				GEO_ATT_DETERMINER_ID = null,
			</cfif>
			<cfif len(arguments.geoAtt.GEO_ATT_DETERMINED_DATE) GT 0>
				GEO_ATT_DETERMINED_DATE = <cfqueryparam cfsqltype="CF_SQL_DATE" value="#dateFormat(arguments.geoAtt.GEO_ATT_DETERMINED_DATE,'yyyy-mm-dd')#">,
			<cfelse>
				GEO_ATT_DETERMINED_DATE = null,
			</cfif>
			<cfif len(arguments.geoAtt.GEO_ATT_DETERMINED_METHOD) GT 0>
				GEO_ATT_DETERMINED_METHOD = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.geoAtt.GEO_ATT_DETERMINED_METHOD#">,
			<cfelse>
				GEO_ATT_DETERMINED_METHOD = null,
			</cfif>
			<cfif len(arguments.geoAtt.GEO_ATT_REMARK) GT 0>
				GEO_ATT_REMARK = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.geoAtt.GEO_ATT_REMARK#">,
			<cfelse>
				GEO_ATT_REMARK = null,
			</cfif>
			GEO_ATT_VALUE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.geoAtt.GEO_ATT_VALUE#">
		WHERE 
			geology_attribute_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.geoAtt.geology_attribute_id#">
	</cfquery>
</cffunction>

<!--- Helper function to add geology attribute parents --->
<cffunction name="addGeologyAttributeParents" access="private" returntype="void">
	<cfargument name="geoAtt" type="struct" required="yes">
	<cfargument name="locality_id" type="string" required="yes">
	
	<!--- find the hierarchy id of the inserted/updated node --->
	<cfquery name="getHierarchyID" datasource="uam_god">
		SELECT geology_attribute_hierarchy_id 
		FROM geology_attribute_hierarchy
		WHERE
			attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.geoAtt.GEOLOGY_ATTRIBUTE#">
			and attribute_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.geoAtt.GEO_ATT_VALUE#">
	</cfquery>
	<!--- add any parents of the inserted/updated node that aren't already present --->
	<cfquery name="getParents" datasource="uam_god">
		SELECT * FROM (
			SELECT 
				level as parentagelevel,
				connect_by_root attribute as geology_attribute,
				connect_by_root attribute_value as geo_att_value,
				connect_by_root geology_attribute_hierarchy_id as geology_attribute_hierarchy_id,
				connect_by_root PARENT_ID as parent_id,
				connect_by_root USABLE_VALUE_FG as USABLE_VALUE_FG,
				connect_by_root DESCRIPTION as description
			FROM geology_attribute_hierarchy 
			WHERE
				geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getHierarchyID.geology_attribute_hierarchy_id#">
			CONNECT BY PRIOR geology_attribute_hierarchy_id = parent_id
			ORDER BY level asc
		) WHERE parentagelevel > 1
	</cfquery>
	<cfloop query="getParents">
		<cfquery name="checkParents" datasource="uam_god">
			SELECT count(*) ct 
			FROM geology_attributes
			WHERE
				locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.locality_id#">
				and geology_attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getParents.geology_attribute#">
				and geo_att_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getParents.geo_att_value#">
		</cfquery>
		<cfif checkParents.ct EQ 0>
			<cfquery name="addGeoAttribute" datasource="uam_god" result="addGeoAttribute_result">
				INSERT INTO geology_attributes
					( locality_id,
						previous_values,
						geology_attribute,
						geo_att_value,
						geo_att_determiner_id,
						geo_att_determined_date,
						geo_att_determined_method
					) VALUES (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.locality_id#">,
						NULL,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getParents.geology_attribute#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getParents.geo_att_value#">,
						<cfif isDefined("arguments.geoAtt.geo_att_determiner_id") and len(arguments.geoAtt.geo_att_determiner_id) GT 0>
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.geoAtt.geo_att_determiner_id#">,
						<cfelse>
							NULL,
						</cfif>
						<cfif isDefined("arguments.geoAtt.geo_att_determined_date") and len(arguments.geoAtt.geo_att_determined_date) GT 0>
							<cfqueryparam cfsqltype="CF_SQL_DATE" value="#arguments.geoAtt.geo_att_determined_date#">,
						<cfelse>
							NULL,
						</cfif>
						<cfif isDefined("arguments.geoAtt.geo_att_determined_method") and len(arguments.geoAtt.geo_att_determined_method) GT 0>
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.geoAtt.geo_att_determined_method#">
						<cfelse>
							NULL
						</cfif>
					)
			</cfquery>
		</cfif>
	</cfloop>
</cffunction>

<!--- Helper function to delete geology attributes --->
<cffunction name="deleteGeologyAttributes" access="private" returntype="void">
	<cfargument name="geology_attributes_to_delete" type="string" required="yes">
	
	<cfif len(arguments.geology_attributes_to_delete) GT 0>
		<cfloop list="#arguments.geology_attributes_to_delete#" index="geoAttIDToDelete">
			<cfif len(geoAttIDToDelete) GT 0>
				<cfquery name="deleteGeologyAttribute" datasource="uam_god" result="deleteGeologyAttribute_result">
					DELETE FROM geology_attributes
					WHERE geology_attribute_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geoAttIDToDelete#">
				</cfquery>
			</cfif>
		</cfloop>
	</cfif>
</cffunction>

<!--- Helper function to create new collecting event --->
<cffunction name="createNewCollectingEvent" access="private" returntype="string">
	<cfargument name="new_locality_id" type="string" required="yes">
	<cfargument name="began_date" type="string" required="yes">
	<cfargument name="ended_date" type="string" required="yes">
	<cfargument name="verbatim_date" type="string" required="yes">
	<cfargument name="collecting_source" type="string" required="yes">
	<cfargument name="verbatim_habitat" type="string" required="no">
	<cfargument name="verbatim_locality" type="string" required="no">
	<cfargument name="verbatimDepth" type="string" required="no">
	<cfargument name="verbatimelevation" type="string" required="no">
	<cfargument name="coll_event_remarks" type="string" required="no">
	<cfargument name="collecting_method" type="string" required="no">
	<cfargument name="habitat_desc" type="string" required="no">
	<cfargument name="collecting_time" type="string" required="no">
	<cfargument name="fish_field_number" type="string" required="no">
	<cfargument name="verbatimcoordinates" type="string" required="no">
	<cfargument name="verbatimlatitude" type="string" required="no">
	<cfargument name="verbatimlongitude" type="string" required="no">
	<cfargument name="verbatimcoordinatesystem" type="string" required="no">
	<cfargument name="verbatimsrs" type="string" required="no">
	<cfargument name="startdayofyear" type="string" required="no">
	<cfargument name="enddayofyear" type="string" required="no">
	<cfargument name="date_determined_by_agent_id" type="string" required="no">
	<cfargument name="valid_distribution_fg" type="string" required="no">
	<cfargument name="verbatim_collectors" type="string" required="no">
	<cfargument name="verbatim_field_numbers" type="string" required="no">
	
	<cfquery name="newCollectingEvent" datasource="uam_god" result="newCollectingEvent_result">
		INSERT INTO collecting_event 
		(
			collecting_event_id,
			began_date, ended_date, verbatim_date, collecting_source, locality_id, verbatim_locality, verbatimdepth, verbatimelevation, verbatimCoordinates,
			verbatimLatitude, verbatimLongitude, verbatimCoordinateSystem, verbatimSRS, verbatim_collectors, verbatim_field_numbers, verbatim_habitat,
			coll_event_remarks, collecting_method, habitat_desc, collecting_time, fish_field_number, 
			startDayOfYear, endDayOfYear, date_determined_by_agent_id, valid_distribution_fg
		) VALUES (
			sq_collecting_event_id.NEXTVAL,
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.began_date#">,
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.ended_date#">,
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatim_date#">,
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.collecting_source#">,
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.new_locality_id#">,
			<cfif len(arguments.verbatim_locality) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatim_locality#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.verbatimdepth) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatimdepth#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.verbatimelevation) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatimelevation#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.verbatimCoordinates) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatimCoordinates#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.verbatimLatitude) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatimLatitude#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.verbatimLongitude) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatimLongitude#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.verbatimCoordinateSystem) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatimCoordinateSystem#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.verbatimSRS) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatimSRS#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.verbatim_collectors) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatim_collectors#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.verbatim_field_numbers) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatim_field_numbers#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.verbatim_habitat) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatim_habitat#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.COLL_EVENT_REMARKS) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.COLL_EVENT_REMARKS#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.COLLECTING_METHOD) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.COLLECTING_METHOD#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.HABITAT_DESC) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.HABITAT_DESC#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.COLLECTING_TIME) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.COLLECTING_TIME#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.fish_field_number) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.fish_field_number#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.startDayOfYear) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.startDayOfYear#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.endDayOfYear) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.endDayOfYear#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.date_determined_by_agent_id) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.date_determined_by_agent_id#">,
			<cfelse>
				null,
			</cfif>
			<cfif len(arguments.valid_distribution_fg) gt 0>
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.valid_distribution_fg#">
			<cfelse>
				null
			</cfif>
		)
	</cfquery>
	
	<cfif newCollectingEvent_result.recordcount is 0>
		<cfthrow message="Error creating new collecting event record.">
	</cfif>
	
	<cfquery name="getCollectingEventID" datasource="uam_god" result="getCollectingEventID_result">
		SELECT collecting_event_id
		FROM collecting_event
		WHERE ROWIDTOCHAR(rowid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newCollectingEvent_result.GENERATEDKEY#">
	</cfquery>
	
	<cfif len(getCollectingEventID.collecting_event_id) is 0>
		<cfthrow message="Error obtaining new collecting event ID.">
	</cfif>
	
	<cfreturn getCollectingEventID.collecting_event_id>
</cffunction>

<!--- Helper function to update existing locality --->
<cffunction name="updateExistingLocality" access="private" returntype="void">
	<cfargument name="locality_id" type="string" required="yes">
	<cfargument name="geog_auth_rec_id" type="string" required="yes">
	<cfargument name="spec_locality" type="string" required="yes">
	<cfargument name="sovereign_nation" type="string" required="no">
	<cfargument name="curated_fg" type="string" required="no">
	<cfargument name="MINIMUM_ELEVATION" type="string" required="no">
	<cfargument name="MAXIMUM_ELEVATION" type="string" required="no">
	<cfargument name="ORIG_ELEV_UNITS" type="string" required="no">
	<cfargument name="MIN_DEPTH" type="string" required="no">
	<cfargument name="MAX_DEPTH" type="string" required="no">
	<cfargument name="DEPTH_UNITS" type="string" required="no">
	<cfargument name="township" type="string" required="no">
	<cfargument name="township_direction" type="string" required="no">
	<cfargument name="range" type="string" required="no">
	<cfargument name="range_direction" type="string" required="no">
	<cfargument name="section" type="string" required="no">
	<cfargument name="section_part" type="string" required="no">
	<cfargument name="locality_remarks" type="string" required="no">
	<cfargument name="nogeorefbecause" type="string" required="no">
	
	<!--- Calculate scales for decimal precision --->
	<cfif len(arguments.MAXIMUM_ELEVATION) GT 0>
		<cfset max_elev_scale = len(rereplace(arguments.MAXIMUM_ELEVATION,'^[0-9-]*[.]',''))>
	</cfif>
	<cfif len(arguments.MINIMUM_ELEVATION) GT 0>
		<cfset min_elev_scale = len(rereplace(arguments.MINIMUM_ELEVATION,'^[0-9-]*[.]',''))>
	</cfif>
	<cfif len(arguments.MAX_DEPTH) GT 0>
		<cfset max_depth_scale = len(rereplace(arguments.MAX_DEPTH,'^[0-9-]*[.]',''))>
	</cfif>
	<cfif len(arguments.MIN_DEPTH) GT 0>
		<cfset min_depth_scale = len(rereplace(arguments.MIN_DEPTH,'^[0-9-]*[.]',''))>
	</cfif>

	<!--- Clean up units if no elevation/depth values --->
	<cfif len(arguments.ORIG_ELEV_UNITS) gt 0>
		<cfif len(arguments.MINIMUM_ELEVATION) is 0 AND len(arguments.MAXIMUM_ELEVATION) is 0>
			<cfset arguments.ORIG_ELEV_UNITS = "">
		</cfif>
	</cfif>
	<cfif len(arguments.DEPTH_UNITS) gt 0>
		<cfif len(arguments.MIN_DEPTH) is 0 AND len(arguments.MAX_DEPTH) is 0>
			<cfset arguments.DEPTH_UNITS = "">
		</cfif>
	</cfif>

	<cfquery name="updateLocality" datasource="uam_god" result="updateLocality_result">
		UPDATE locality SET
		geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.geog_auth_rec_id#">,
		spec_locality = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.spec_locality#">,
		<cfif len(arguments.sovereign_nation) GT 0>
			sovereign_nation = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.sovereign_nation#">,
		<cfelse>
			sovereign_nation = null,
		</cfif>
		<cfif isdefined("arguments.curated_fg") AND len(arguments.curated_fg) gt 0>
			curated_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.curated_fg#">,
		<cfelse>
			curated_fg = null,
		</cfif>
		<cfif len(arguments.MINIMUM_ELEVATION) gt 0>
			MINIMUM_ELEVATION = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="#min_elev_scale#" value="#arguments.MINIMUM_ELEVATION#">,
		<cfelse>
			MINIMUM_ELEVATION = null,
		</cfif>
		<cfif len(arguments.MAXIMUM_ELEVATION) gt 0>
			MAXIMUM_ELEVATION = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="#max_elev_scale#" value="#arguments.MAXIMUM_ELEVATION#">,
		<cfelse>
			MAXIMUM_ELEVATION = null,
		</cfif>
		<cfif len(arguments.ORIG_ELEV_UNITS) gt 0>
			ORIG_ELEV_UNITS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.ORIG_ELEV_UNITS#">,
		<cfelse>
			ORIG_ELEV_UNITS = null,
		</cfif>
		<cfif len(arguments.MIN_DEPTH) gt 0>
			min_depth = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="#min_depth_scale#" value="#arguments.MIN_DEPTH#">,
		<cfelse>
			min_depth = null,
		</cfif>
		<cfif len(arguments.MAX_DEPTH) gt 0>
			max_depth = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="#max_depth_scale#" value="#arguments.MAX_DEPTH#">,
		<cfelse>
			max_depth = null,
		</cfif>
		<cfif len(arguments.DEPTH_UNITS) gt 0>
			depth_units = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.DEPTH_UNITS#">,
		<cfelse>
			depth_units = null,
		</cfif>
		<cfif len(arguments.section_part) gt 0>
			section_part = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.section_part#">,
		<cfelse>
			section_part = null,
		</cfif>
		<cfif len(arguments.section) gt 0>
			section = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.section#">,
		<cfelse>
			section = null,
		</cfif>
		<cfif len(arguments.township_direction) gt 0>
			township_direction = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.township_direction#">,
		<cfelse>
			township_direction = null,
		</cfif>
		<cfif len(arguments.township) gt 0>
			township = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.township#">,
		<cfelse>
			township = null,
		</cfif>
		<cfif len(arguments.range_direction) gt 0>
			range_direction = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.range_direction#">,
		<cfelse>
			range_direction = null,
		</cfif>
		<cfif len(arguments.range) gt 0>
			range = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.range#">,
		<cfelse>
			range = null,
		</cfif>
		<cfif len(arguments.locality_remarks) gt 0>
			LOCALITY_REMARKS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.locality_remarks#">,
		<cfelse>
			LOCALITY_REMARKS = null,
		</cfif>
		<!--- last field in set clause, no commas at end --->
		<cfif len(arguments.nogeorefbecause) gt 0>
			nogeorefbecause = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.nogeorefbecause#">
		<cfelse>
			nogeorefbecause = null
		</cfif>
		WHERE locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.locality_id#">
	</cfquery>
	<cfif updateLocality_result.recordcount NEQ 1>
		<cfthrow message="Error updating Locality record #arguments.locality_id#.">
	</cfif>
</cffunction>

<!--- Helper function to update existing collecting event --->
<cffunction name="updateExistingCollectingEvent" access="private" returntype="void">
	<cfargument name="collecting_event_id" type="string" required="yes">
	<cfargument name="locality_id" type="string" required="yes">
	<cfargument name="began_date" type="string" required="yes">
	<cfargument name="ended_date" type="string" required="yes">
	<cfargument name="verbatim_date" type="string" required="yes">
	<cfargument name="collecting_source" type="string" required="yes">
	<cfargument name="verbatim_habitat" type="string" required="no">
	<cfargument name="verbatim_locality" type="string" required="no">
	<cfargument name="verbatimDepth" type="string" required="no">
	<cfargument name="verbatimelevation" type="string" required="no">
	<cfargument name="coll_event_remarks" type="string" required="no">
	<cfargument name="collecting_method" type="string" required="no">
	<cfargument name="habitat_desc" type="string" required="no">
	<cfargument name="collecting_time" type="string" required="no">
	<cfargument name="fish_field_number" type="string" required="no">
	<cfargument name="verbatimcoordinates" type="string" required="no">
	<cfargument name="verbatimlatitude" type="string" required="no">
	<cfargument name="verbatimlongitude" type="string" required="no">
	<cfargument name="verbatimcoordinatesystem" type="string" required="no">
	<cfargument name="verbatimsrs" type="string" required="no">
	<cfargument name="startdayofyear" type="string" required="no">
	<cfargument name="enddayofyear" type="string" required="no">
	<cfargument name="date_determined_by_agent_id" type="string" required="no">
	<cfargument name="valid_distribution_fg" type="string" required="no">
	<cfargument name="verbatim_collectors" type="string" required="no">
	<cfargument name="verbatim_field_numbers" type="string" required="no">
	
	<cfquery name="updateCollectingEvent" datasource="uam_god" result="updateCollectingEvent_result">
		UPDATE collecting_event 
		SET
			began_date = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.began_date#">,
			ended_date = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.ended_date#">,
			verbatim_date = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatim_date#">,
			collecting_source = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.collecting_source#">,
			locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.locality_id#">
			<cfif len(arguments.verbatim_locality) gt 0>
				,verbatim_locality = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatim_locality#">
			<cfelse>
				,verbatim_locality = null
			</cfif>
			<cfif len(arguments.verbatimdepth) gt 0>
				,verbatimdepth = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatimdepth#">
			<cfelse>
				,verbatimdepth = null
			</cfif>
			<cfif len(arguments.verbatimelevation) gt 0>
				,verbatimelevation = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatimelevation#">
			<cfelse>
				,verbatimelevation = null
			</cfif>
			<cfif len(arguments.COLL_EVENT_REMARKS) gt 0>
				,COLL_EVENT_REMARKS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.COLL_EVENT_REMARKS#">
			<cfelse>
				,COLL_EVENT_REMARKS = null
			</cfif>
			<cfif len(arguments.COLLECTING_METHOD) gt 0>
				,COLLECTING_METHOD = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.COLLECTING_METHOD#">
			<cfelse>
				,COLLECTING_METHOD = null
			</cfif>
			<cfif len(arguments.HABITAT_DESC) gt 0>
				,HABITAT_DESC = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.HABITAT_DESC#">
			<cfelse>
				,HABITAT_DESC = null
			</cfif>
			<cfif len(arguments.COLLECTING_TIME) gt 0>
				,COLLECTING_TIME = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.COLLECTING_TIME#">
			<cfelse>
				,COLLECTING_TIME = null
			</cfif>
			<cfif len(arguments.fish_field_number) gt 0>
				,FISH_FIELD_NUMBER = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.fish_field_number#">
			<cfelse>
				,FISH_FIELD_NUMBER = null
			</cfif>
			<cfif len(arguments.verbatimCoordinates) gt 0>
				,verbatimCoordinates = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatimCoordinates#">
			<cfelse>
				,verbatimCoordinates = null
			</cfif>
			<cfif len(arguments.verbatimLatitude) gt 0>
				,verbatimLatitude = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatimLatitude#">
			<cfelse>
				,verbatimLatitude = null
			</cfif>
			<cfif len(arguments.verbatimLongitude) gt 0>
				,verbatimLongitude = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatimLongitude#">
			<cfelse>
				,verbatimLongitude = null
			</cfif>
			<cfif len(arguments.verbatimCoordinateSystem) gt 0>
				,verbatimCoordinateSystem = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatimCoordinateSystem#">
			<cfelse>
				,verbatimCoordinateSystem = null
			</cfif>
			<cfif len(arguments.verbatimSRS) gt 0>
				,verbatimSRS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatimSRS#">
			<cfelse>
				,verbatimSRS = null
			</cfif>
			<cfif len(arguments.startDayOfYear) gt 0>
				,startDayOfYear = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.startDayOfYear#">
			<cfelse>
				,startDayOfYear = null
			</cfif>
			<cfif len(arguments.endDayOfYear) gt 0>
				,endDayOfYear = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.endDayOfYear#">
			<cfelse>
				,endDayOfYear = null
			</cfif>
			<cfif len(arguments.date_determined_by_agent_id) gt 0>
				,date_determined_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.date_determined_by_agent_id#">
			<cfelse>
				,date_determined_by_agent_id = null
			</cfif>
			<cfif len(arguments.valid_distribution_fg) gt 0>
				,valid_distribution_fg = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.valid_distribution_fg#">
			<cfelse>
				,valid_distribution_fg = null
			</cfif>
			<cfif len(arguments.verbatim_collectors) gt 0>
				,verbatim_collectors = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatim_collectors#">
			<cfelse>
				,verbatim_collectors = null
			</cfif>
			<cfif len(arguments.verbatim_field_numbers) gt 0>
				,verbatim_field_numbers = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatim_field_numbers#">
			<cfelse>
				,verbatim_field_numbers = null
			</cfif>
			<cfif len(arguments.verbatim_habitat) gt 0>
				,verbatim_habitat = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatim_habitat#">
			<cfelse>
				,verbatim_habitat = null
			</cfif>
 		WHERE
			 collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collecting_event_id#">
	</cfquery>
	<cfif updateCollectingEvent_result.recordcount NEQ 1>
		<cfthrow message="Error updating Collecting Event record #arguments.collecting_event_id#.">
	</cfif>
</cffunction>


<!--- Helper function to update collecting event locality --->
<cffunction name="updateCollectingEventLocality" access="private" returntype="void">
	<cfargument name="collecting_event_id" type="string" required="yes">
	<cfargument name="new_locality_id" type="string" required="yes">
	<cfargument name="began_date" type="string" required="yes">
	<cfargument name="ended_date" type="string" required="yes">
	<cfargument name="verbatim_date" type="string" required="yes">
	<cfargument name="collecting_source" type="string" required="yes">
	<cfargument name="verbatim_habitat" type="string" required="no">
	<cfargument name="verbatim_locality" type="string" required="no">
	<cfargument name="verbatimDepth" type="string" required="no">
	<cfargument name="verbatimelevation" type="string" required="no">
	<cfargument name="coll_event_remarks" type="string" required="no">
	<cfargument name="collecting_method" type="string" required="no">
	<cfargument name="habitat_desc" type="string" required="no">
	<cfargument name="collecting_time" type="string" required="no">
	<cfargument name="fish_field_number" type="string" required="no">
	<cfargument name="verbatimcoordinates" type="string" required="no">
	<cfargument name="verbatimlatitude" type="string" required="no">
	<cfargument name="verbatimlongitude" type="string" required="no">
	<cfargument name="verbatimcoordinatesystem" type="string" required="no">
	<cfargument name="verbatimsrs" type="string" required="no">
	<cfargument name="startdayofyear" type="string" required="no">
	<cfargument name="enddayofyear" type="string" required="no">
	<cfargument name="date_determined_by_agent_id" type="string" required="no">
	<cfargument name="valid_distribution_fg" type="string" required="no">
	<cfargument name="verbatim_collectors" type="string" required="no">
	<cfargument name="verbatim_field_numbers" type="string" required="no">
	
	<cfquery name="updateCollectingEvent" datasource="uam_god" result="updateCollectingEvent_result">
		UPDATE collecting_event 
		SET
			locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.new_locality_id#">,
			began_date = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.began_date#">,
			ended_date = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.ended_date#">,
			verbatim_date = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatim_date#">,
			collecting_source = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.collecting_source#">
			<cfif len(arguments.verbatim_locality) gt 0>
				,verbatim_locality = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatim_locality#">
			<cfelse>
				,verbatim_locality = null
			</cfif>
			<cfif len(arguments.verbatimdepth) gt 0>
				,verbatimdepth = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatimdepth#">
			<cfelse>
				,verbatimdepth = null
			</cfif>
			<cfif len(arguments.verbatimelevation) gt 0>
				,verbatimelevation = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatimelevation#">
			<cfelse>
				,verbatimelevation = null
			</cfif>
			<cfif len(arguments.COLL_EVENT_REMARKS) gt 0>
				,COLL_EVENT_REMARKS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.COLL_EVENT_REMARKS#">
			<cfelse>
				,COLL_EVENT_REMARKS = null
			</cfif>
			<cfif len(arguments.COLLECTING_METHOD) gt 0>
				,COLLECTING_METHOD = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.COLLECTING_METHOD#">
			<cfelse>
				,COLLECTING_METHOD = null
			</cfif>
			<cfif len(arguments.HABITAT_DESC) gt 0>
				,HABITAT_DESC = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.HABITAT_DESC#">
			<cfelse>
				,HABITAT_DESC = null
			</cfif>
			<cfif len(arguments.COLLECTING_TIME) gt 0>
				,COLLECTING_TIME = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.COLLECTING_TIME#">
			<cfelse>
				,COLLECTING_TIME = null
			</cfif>
			<cfif len(arguments.fish_field_number) gt 0>
				,FISH_FIELD_NUMBER = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.fish_field_number#">
			<cfelse>
				,FISH_FIELD_NUMBER = null
			</cfif>
			<cfif len(arguments.verbatimCoordinates) gt 0>
				,verbatimCoordinates = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatimCoordinates#">
			<cfelse>
				,verbatimCoordinates = null
			</cfif>
			<cfif len(arguments.verbatimLatitude) gt 0>
				,verbatimLatitude = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatimLatitude#">
			<cfelse>
				,verbatimLatitude = null
			</cfif>
			<cfif len(arguments.verbatimLongitude) gt 0>
				,verbatimLongitude = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatimLongitude#">
			<cfelse>
				,verbatimLongitude = null
			</cfif>
			<cfif len(arguments.verbatimCoordinateSystem) gt 0>
				,verbatimCoordinateSystem = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatimCoordinateSystem#">
			<cfelse>
				,verbatimCoordinateSystem = null
			</cfif>
			<cfif len(arguments.verbatimSRS) gt 0>
				,verbatimSRS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatimSRS#">
			<cfelse>
				,verbatimSRS = null
			</cfif>
			<cfif len(arguments.startDayOfYear) gt 0>
				,startDayOfYear = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.startDayOfYear#">
			<cfelse>
				,startDayOfYear = null
			</cfif>
			<cfif len(arguments.endDayOfYear) gt 0>
				,endDayOfYear = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.endDayOfYear#">
			<cfelse>
				,endDayOfYear = null
			</cfif>
			<cfif len(arguments.date_determined_by_agent_id) gt 0>
				,date_determined_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.date_determined_by_agent_id#">
			<cfelse>
				,date_determined_by_agent_id = null
			</cfif>
			<cfif len(arguments.valid_distribution_fg) gt 0>
				,valid_distribution_fg = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.valid_distribution_fg#">
			<cfelse>
				,valid_distribution_fg = 1
			</cfif>
			<cfif len(arguments.verbatim_collectors) gt 0>
				,verbatim_collectors = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatim_collectors#">
			<cfelse>
				,verbatim_collectors = null
			</cfif>
			<cfif len(arguments.verbatim_field_numbers) gt 0>
				,verbatim_field_numbers = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatim_field_numbers#">
			<cfelse>
				,verbatim_field_numbers = null
			</cfif>
			<cfif len(arguments.verbatim_habitat) gt 0>
				,verbatim_habitat = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.verbatim_habitat#">
			<cfelse>
				,verbatim_habitat = null
			</cfif>
 		WHERE
			collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collecting_event_id#">
	</cfquery>
	<cfif updateCollectingEvent_result.recordcount NEQ 1>
		<cfthrow message="Error updating existing Collecting Event record #arguments.collecting_event_id#.">
	</cfif>
</cffunction>

<!--- Helper function to update cataloged item collecting event --->
<cffunction name="updateCatalogedItemCollectingEvent" access="private" returntype="void">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="new_collecting_event_id" type="string" required="yes">
	
	<cfquery name="updateCatalogedItem" datasource="uam_god" result="updateCatalogedItem_result">
		UPDATE cataloged_item
		SET collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.new_collecting_event_id#">
		WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">
	</cfquery>
</cffunction>

<!--- Helper function to ensure trigger is enabled --->
<cffunction name="ensureTriggerEnabled" access="private" returntype="void">
	<cftry>
		<cfquery name="enableTrigger" datasource="uam_god" result="enableTrigger_result">
			ALTER TRIGGER TR_LATLONG_ACCEPTED_BIUPA ENABLE
		</cfquery>
	<cfcatch></cfcatch>
	</cftry>
</cffunction>


</cfcomponent>
