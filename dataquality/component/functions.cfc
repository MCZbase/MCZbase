<!---
/dataquality/component/functions.cfc

Copyright 2022 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	 http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Invocations of TDWG Biodiversity Data Quality Task Group 2 CORE
test implementations in the event_date_qc, sci_name_qc, and geo_ref_qc
libraries found in github.com/filteredpush/ repositories.

--->
<cfcomponent>
<cf_rolecheck>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<!--- obtain QC report concerning Geospatial terms on a record from flat or from locality 
  @param target_id the collection_object_id or locality_id for which to run tests
  @param target FLAT or LOCALITY to specify whether target_id is for a collection object or a locality.
  @return a json serialization of a structure containing preamendment, amendment, and postamendment
    phase structures containing lists of test results identified by test guid and containing 
    label, type, status, comment, value terms.
--->
<cffunction name="getSpaceQCReport" access="remote">
	<cfargument name="target_id" type="string" required="yes">
	<cfargument name="target" type="string" required="yes">

	<cfset result=structNew()> <!--- overall result to return --->
	<cfset r=structNew()><!--- temporary result for an individual test, create new after each test --->
	<cfset preamendment=structNew()><!--- pre-amendment phase measures and validations --->
	<cfset amendment=structNew()><!--- amendment phase --->
	<cfset postamendment=structNew()><!--- post-amendment phase measures and validations --->
	<cftry>
		<cfswitch expression="#ucase(target)#">
			<cfcase value="FLAT">
				<cfquery name="queryrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT guid as item_label, 
						basisofrecord,
						highergeographyid,
						continent, country, countrycode,
						spec_locality as locality,
						dec_lat as decimal_latitude, dec_long as decimal_longitude, datum as geodeticDatum,
						coordinateuncertaintyinmeters,
						verbatimlatitude, verbatimlongitude, verbatimelevation, verbatimlocality, 
						max_depth_in_m, min_depth_in_m, max_elev_in_m, min_elev_in_m,
						waterbody, island_group, island
					FROM DIGIR_QUERY.digir_filtered_flat
					WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_id#">
				</cfquery>
			</cfcase>
			<cfcase value="LOCALITY">
				<cfquery name="queryrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT distinct 
                  locality.locality_id as item_label,
                  '' as basisofrecord,
                  highergeographyid,
                  (CASE WHEN geog_auth_rec.continent_ocean like '% Ocean' THEN '' ELSE geog_auth_rec.continent_ocean END) as continent, 
                  country, 
                  MCZBASE.get_countrycode(geog_auth_rec.country) countrycode,
                  spec_locality as locality,
                  accepted_lat_long.dec_lat as decimal_latitude, 
                  accepted_lat_long.dec_long as decimal_longitude, 
                  decode(accepted_lat_long.datum,'WGS84','EPSG:4326',accepted_lat_long.datum) as geodeticDatum,
						to_meters(accepted_lat_long.max_error_distance, accepted_lat_long.max_error_units) coordinateuncertaintyinmeters,
                  decode(accepted_lat_long.orig_lat_long_units,
                                'decimal degrees',
                                        to_char(decimalZero(accepted_lat_long.dec_lat)) || 'd',
                                'deg. min. sec.',
                                        to_char(decimalZero(accepted_lat_long.lat_deg)) || 'd ' ||
                                        to_char(decimalZero(accepted_lat_long.lat_min)) || 'm ' ||
                                        to_char(decimalZero(accepted_lat_long.lat_sec)) || 's ' ||
                                        accepted_lat_long.lat_dir,
                                'degrees dec. minutes',
                                        to_char(decimalZero(accepted_lat_long.lat_deg)) || 'd ' ||
                                        to_char(decimalZero(accepted_lat_long.dec_lat_min)) || 'm ' ||
                                        accepted_lat_long.lat_dir) verbatimlatitude,
                        decode(accepted_lat_long.orig_lat_long_units,
                                'decimal degrees',
                                        to_char(decimalZero(accepted_lat_long.dec_long)) || 'd',
                                'deg. min. sec.',
                                        to_char(decimalZero(accepted_lat_long.long_deg)) || 'd ' ||
                                        to_char(decimalZero(accepted_lat_long.long_min)) || 'm ' ||
                                        to_char(decimalZero(accepted_lat_long.long_sec)) || 's ' ||
                                        accepted_lat_long.long_dir,
                                'UTM', 
                                    'UTM E/W: ' || to_char(accepted_lat_long.UTM_EW) 
                                    || '; UTM Zone: ' || 
                                    decode(accepted_lat_long.UTM_ZONE,
                                        null,'not given',
                                        accepted_lat_long.UTM_ZONE
                                    ),
                                'degrees dec. minutes',
                                        to_char(decimalZero(accepted_lat_long.long_deg)) || 'd ' ||
                                        to_char(decimalZero(accepted_lat_long.dec_long_min)) || 'm ' ||
                                        accepted_lat_long.long_dir) verbatimlongitude,
                  nvl2(minimum_elevation, 
                      '', 
                      minimum_elevation || decode(minimum_elevation,maximum_elevation,' ', '-' || maximum_elevation || ' ') ||  orig_elev_units
                      ) as verbatimelevation, 
                  '' verbatimlocality,
                  to_meters(locality.max_depth, locality.depth_units) max_depth_in_m, 
                  to_meters(locality.min_depth, locality.depth_units) min_depth_in_m, 
                  to_meters(locality.maximum_elevation, locality.orig_elev_units) max_elev_in_m, 
                  to_meters(locality.minimum_elevation, locality.orig_elev_units) min_elev_in_m,
                  decode (water_feature, null, 
                           decode (sea, null, 
                              decode (ocean_subregion, null, 
                                 decode (ocean_region, null, 
                                   decode ( (CASE WHEN continent_ocean like '% Ocean' THEN continent_ocean ELSE '' END), null, 
                                        '', 
                                       (CASE WHEN continent_ocean like '% Ocean' THEN continent_ocean ELSE '' END)
                                   ), 
                                ocean_region),
                              ocean_subregion),
                           sea),
                         water_feature) as  waterbody,
                 island_group, island
               FROM locality
                    join geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
                    left join accepted_lat_long on locality.locality_id = accepted_lat_long.locality_id
					WHERE locality.locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_id#">
				</cfquery>
			</cfcase>
			<cfdefaultcase>
				<cfthrow message="Unknown target type for geospatial report. Should be FLAT or LOCALITY">
			</cfdefaultcase>
		</cfswitch>
		<cfif queryrow.recordcount is 1>
			<cfset result.STATUS="success">
			<cfset result.TARGET_ID=target_id >
			<cfset result.GUID=queryrow.item_label>
			<cfset result.ERROR="">

			<!--- store local copies of query results to use in pre-amendment phase and overwrite in ammendment phase  --->
			<cfset country = queryrow.country>
			<cfset countrycode = queryrow.countrycode>
			<cfset decimal_latitude = queryrow.decimal_latitude>
			<cfset decimal_longitude = queryrow.decimal_longitude>
			<cfset coordinateuncertaintyinmeters = queryrow.coordinateuncertaintyinmeters>
			<cfset geodeticDatum = queryrow.geodeticDatum>
			<cfset verbatimlatitude = queryrow.verbatimlatitude>
			<cfset verbatimlongitude = queryrow.verbatimlongitude>
			<cfset max_depth_in_m = queryrow.max_depth_in_m>
			<cfset min_depth_in_m = queryrow.min_depth_in_m>
			<cfset max_elev_in_m = queryrow.max_elev_in_m>
			<cfset min_elev_in_m = queryrow.min_elev_in_m>

			<cfobject type="Java" class="org.filteredpush.qc.georeference.DwCGeoRefDQ" name="dwcGeoRefDQ">
			<cfobject type="Java" class="org.filteredpush.qc.georeference.DwCGeoRefDQDefaults" name="dwcGeoRefDQDefaults">
			<cfobject type="Java" class="org.datakurator.ffdq.annotations.Mechanism" name="Mechanism">
			<cfobject type="Java" class="org.datakurator.ffdq.annotations.Provides" name="Provides">
			<cfobject type="Java" class="org.datakurator.ffdq.annotations.Validation" name="Validation">
			<cfobject type="Java" class="org.datakurator.ffdq.annotations.Amendment" name="AmendmentC">
			<!--- Obtain mechanism from annotation on class --->
			<cfset result.mechanism = dwcGeoRefDQ.getClass().getAnnotation(Mechanism.getClass()).label() >
			<cfset aString = ""><!--- a String variable, for invocation of getClass() --->

			<!--- pre-amendment phase --->

			<cfset array5String = ArrayNew(1)>
			<cfset ArraySet(array5String,1,5,aString.getClass())>
			<cfset providesGuid = dwcGeoRefDQ.getClass().getMethod("validationCoordinatesCountrycodeConsistent",array5String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcGeoRefDQ.validationCoordinatesCountrycodeConsistent(javaCast("string",decimal_latitude),javaCast("string",decimal_longitude), countrycode, "10000", "") >
			<cfset r.label = dwcGeoRefDQ.getClass().getMethod("validationCoordinatesCountrycodeConsistent",array5String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment[providesGuid] = r >
			<cfset r=structNew()>

			<cfset array2String = ArrayNew(1)>
			<cfset ArraySet(array2String,1,2,aString.getClass())>
			<cfset providesGuid = dwcGeoRefDQ.getClass().getMethod("validationCoordinatesNotzero",array2String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcGeoRefDQ.validationCoordinatesNotzero(javaCast("string",decimal_latitude),javaCast("string",decimal_longitude)) >
			<cfset r.label = dwcGeoRefDQ.getClass().getMethod("validationCoordinatesNotzero",array2String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment[providesGuid] = r >
			<cfset r=structNew()>

			<cfset array1String = ArrayNew(1)>
			<cfset ArraySet(array1String,1,1,aString.getClass())>
			<cfset providesGuid = dwcGeoRefDQ.getClass().getMethod("validationCoordinateuncertaintyInrange",array1String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcGeoRefDQ.validationCoordinateuncertaintyInrange(javaCast("string",coordinateuncertaintyinmeters)) >
			<cfset r.label = dwcGeoRefDQ.getClass().getMethod("validationCoordinateuncertaintyInrange",array1String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment[providesGuid] = r >
			<cfset r=structNew()>

			<cfset providesGuid = dwcGeoRefDQ.getClass().getMethod("validationCountrycodeNotempty",array1String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcGeoRefDQ.validationCountrycodeNotempty(countrycode) >
			<cfset r.label = dwcGeoRefDQ.getClass().getMethod("validationCountrycodeNotempty",array1String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment[providesGuid] = r >
			<cfset r=structNew()>

			<cfset providesGuid = dwcGeoRefDQ.getClass().getMethod("validationCountrycodeStandard",array1String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcGeoRefDQ.validationCountrycodeStandard(countrycode) >
			<cfset r.label = dwcGeoRefDQ.getClass().getMethod("validationCountrycodeStandard",array1String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment[providesGuid] = r >
			<cfset r=structNew()>

			<cfset providesGuid = dwcGeoRefDQ.getClass().getMethod("validationCountryCountrycodeConsistent",array2String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcGeoRefDQ.validationCountryCountrycodeConsistent(country, countrycode) >
			<cfset r.label = dwcGeoRefDQ.getClass().getMethod("validationCountryCountrycodeConsistent",array2String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment[providesGuid] = r >
			<cfset r=structNew()>

			<cfset providesGuid = dwcGeoRefDQ.getClass().getMethod("validationMindepthLessthanMaxdepth",array2String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcGeoRefDQ.validationMindepthLessthanMaxdepth(min_depth_in_m, max_depth_in_m) >
			<cfset r.label = dwcGeoRefDQ.getClass().getMethod("validationMindepthLessthanMaxdepth",array2String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment[providesGuid] = r >
			<cfset r=structNew()>

			<cfset providesGuid = dwcGeoRefDQDefaults.getClass().getMethod("validationCountryFound",array1String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcGeoRefDQDefaults.validationCountryFound(country) >
			<cfset r.label = dwcGeoRefDQDefaults.getClass().getMethod("validationCountryFound",array1String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment[providesGuid] = r >
			<cfset r=structNew()>

			<cfset providesGuid = dwcGeoRefDQ.getClass().getMethod("validationCountryNotempty",array1String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcGeoRefDQ.validationCountryNotempty(country) >
			<cfset r.label = dwcGeoRefDQ.getClass().getMethod("validationCountryNotempty",array1String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment[providesGuid] = r >
			<cfset r=structNew()>

			<cfset providesGuid = dwcGeoRefDQ.getClass().getMethod("validationDecimallatitudeNotempty",array1String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcGeoRefDQ.validationDecimallatitudeNotempty(javaCast("string",decimal_latitude)) >
			<cfset r.label = dwcGeoRefDQ.getClass().getMethod("validationDecimallatitudeNotempty",array1String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment[providesGuid] = r >
			<cfset r=structNew()>

			<cfset providesGuid = dwcGeoRefDQ.getClass().getMethod("validationDecimallatitudeInrange",array1String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcGeoRefDQ.validationDecimallatitudeInrange(javaCast("string",decimal_latitude)) >
			<cfset r.label = dwcGeoRefDQ.getClass().getMethod("validationDecimallatitudeInrange",array1String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment[providesGuid] = r >
			<cfset r=structNew()>

			<cfset providesGuid = dwcGeoRefDQ.getClass().getMethod("validationDecimallongitudeNotempty",array1String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcGeoRefDQ.validationDecimallongitudeNotempty(javaCast("string",decimal_longitude)) >
			<cfset r.label = dwcGeoRefDQ.getClass().getMethod("validationDecimallongitudeNotempty",array1String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment[providesGuid] = r >
			<cfset r=structNew()>

			<cfset providesGuid = dwcGeoRefDQ.getClass().getMethod("validationDecimallongitudeInrange",array1String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcGeoRefDQ.validationDecimallongitudeInrange(javaCast("string",decimal_longitude)) >
			<cfset r.label = dwcGeoRefDQ.getClass().getMethod("validationDecimallongitudeInrange",array1String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment[providesGuid] = r >
			<cfset r=structNew()>

			<cfset providesGuid = dwcGeoRefDQ.getClass().getMethod("validationGeodeticdatumNotempty",array1String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcGeoRefDQ.validationGeodeticdatumNotempty(geodeticDatum) >
			<cfset r.label = dwcGeoRefDQ.getClass().getMethod("validationGeodeticdatumNotempty",array1String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment[providesGuid] = r >
			<cfset r=structNew()>

			<cfset providesGuid = dwcGeoRefDQ.getClass().getMethod("validationGeodeticdatumStandard",array1String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcGeoRefDQ.validationGeodeticdatumStandard(geodeticDatum) >
			<cfset r.label = dwcGeoRefDQ.getClass().getMethod("validationGeodeticdatumStandard",array1String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment[providesGuid] = r >
			<cfset r=structNew()>

			<!--- amendment phase --->

			<cfset providesGuid = dwcGeoRefDQ.getClass().getMethod("amendmentCountrycodeFromCoordinates",array5String).getAnnotation(Provides.getClass()).value() >
         <cfset dqResponse= dwcGeoRefDQ.amendmentCountrycodeFromCoordinates(javaCast("string",decimal_latitude), javaCast("string",decimal_longitude), geodeticDatum, countrycode, "") >
			<cfset r.label = dwcGeoRefDQ.getClass().getMethod("amendmentCountrycodeFromCoordinates",array5String).getAnnotation(AmendmentC.getClass()).description() >
         <cfset r.type = "AMENDMENT" >
         <cfset r.status = dqResponse.getResultState().getLabel() >
         <cfif r.status eq "AMENDED" OR r.status EQ "FILLED_IN">
            <cfset countryCode = dqResponse.getValue().getObject().get("dwc:countryCode") >
            <cfset r.value = dqResponse.getValue().getObject().toString() >
         <cfelse>
            <cfset r.value = "">
         </cfif>
         <cfset r.comment = dqResponse.getComment() >
         <cfset amendment[providesGuid] = r >
         <cfset r=structNew()>

			<cfset providesGuid = dwcGeoRefDQ.getClass().getMethod("amendmentCountrycodeStandardized",array1String).getAnnotation(Provides.getClass()).value() >
         <cfset dqResponse= dwcGeoRefDQ.amendmentCountrycodeStandardized(countrycode) >
			<cfset r.label = dwcGeoRefDQ.getClass().getMethod("amendmentCountrycodeStandardized",array1String).getAnnotation(AmendmentC.getClass()).description() >
         <cfset r.type = "AMENDMENT" >
         <cfset r.status = dqResponse.getResultState().getLabel() >
         <cfif r.status eq "AMENDED" OR r.status EQ "FILLED_IN">
            <cfset countryCode = dqResponse.getValue().getObject().get("dwc:countryCode") >
            <cfset r.value = dqResponse.getValue().getObject().toString() >
         <cfelse>
            <cfset r.value = "">
         </cfif>
         <cfset r.comment = dqResponse.getComment() >
         <cfset amendment[providesGuid] = r >
         <cfset r=structNew()>


			<!--- post-amendment phase --->

			<cfset array5String = ArrayNew(1)>
			<cfset ArraySet(array5String,1,5,aString.getClass())>
			<cfset providesGuid = dwcGeoRefDQ.getClass().getMethod("validationCoordinatesCountrycodeConsistent",array5String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcGeoRefDQ.validationCoordinatesCountrycodeConsistent(javaCast("string",decimal_latitude),javaCast("string",decimal_longitude), countrycode, "10000", "") >
			<cfset r.label = dwcGeoRefDQ.getClass().getMethod("validationCoordinatesCountrycodeConsistent",array5String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment[providesGuid] = r >
			<cfset r=structNew()>

			<cfset array2String = ArrayNew(1)>
			<cfset ArraySet(array2String,1,2,aString.getClass())>
			<cfset providesGuid = dwcGeoRefDQ.getClass().getMethod("validationCoordinatesNotzero",array2String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcGeoRefDQ.validationCoordinatesNotzero(javaCast("string",decimal_latitude),javaCast("string",decimal_longitude)) >
			<cfset r.label = dwcGeoRefDQ.getClass().getMethod("validationCoordinatesNotzero",array2String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment[providesGuid] = r >
			<cfset r=structNew()>

			<cfset array1String = ArrayNew(1)>
			<cfset ArraySet(array1String,1,1,aString.getClass())>
			<cfset providesGuid = dwcGeoRefDQ.getClass().getMethod("validationCoordinateuncertaintyInrange",array1String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcGeoRefDQ.validationCoordinateuncertaintyInrange(javaCast("string",coordinateuncertaintyinmeters)) >
			<cfset r.label = dwcGeoRefDQ.getClass().getMethod("validationCoordinateuncertaintyInrange",array1String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment[providesGuid] = r >
			<cfset r=structNew()>

			<cfset providesGuid = dwcGeoRefDQ.getClass().getMethod("validationCountrycodeNotempty",array1String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcGeoRefDQ.validationCountrycodeNotempty(countrycode) >
			<cfset r.label = dwcGeoRefDQ.getClass().getMethod("validationCountrycodeNotempty",array1String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment[providesGuid] = r >
			<cfset r=structNew()>

			<cfset providesGuid = dwcGeoRefDQ.getClass().getMethod("validationCountrycodeStandard",array1String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcGeoRefDQ.validationCountrycodeStandard(countrycode) >
			<cfset r.label = dwcGeoRefDQ.getClass().getMethod("validationCountrycodeStandard",array1String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment[providesGuid] = r >
			<cfset r=structNew()>

			<cfset providesGuid = dwcGeoRefDQ.getClass().getMethod("validationCountryCountrycodeConsistent",array2String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcGeoRefDQ.validationCountryCountrycodeConsistent(country, countrycode) >
			<cfset r.label = dwcGeoRefDQ.getClass().getMethod("validationCountryCountrycodeConsistent",array2String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment[providesGuid] = r >
			<cfset r=structNew()>

			<cfset providesGuid = dwcGeoRefDQ.getClass().getMethod("validationMindepthLessthanMaxdepth",array2String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcGeoRefDQ.validationMindepthLessthanMaxdepth(min_depth_in_m, max_depth_in_m) >
			<cfset r.label = dwcGeoRefDQ.getClass().getMethod("validationMindepthLessthanMaxdepth",array2String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment[providesGuid] = r >
			<cfset r=structNew()>

			<cfset providesGuid = dwcGeoRefDQDefaults.getClass().getMethod("validationCountryFound",array1String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcGeoRefDQDefaults.validationCountryFound(country) >
			<cfset r.label = dwcGeoRefDQDefaults.getClass().getMethod("validationCountryFound",array1String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment[providesGuid] = r >
			<cfset r=structNew()>

			<cfset providesGuid = dwcGeoRefDQ.getClass().getMethod("validationCountryNotempty",array1String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcGeoRefDQ.validationCountryNotempty(country) >
			<cfset r.label = dwcGeoRefDQ.getClass().getMethod("validationCountryNotempty",array1String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment[providesGuid] = r >
			<cfset r=structNew()>

			<cfset providesGuid = dwcGeoRefDQ.getClass().getMethod("validationDecimallatitudeNotempty",array1String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcGeoRefDQ.validationDecimallatitudeNotempty(javaCast("string",decimal_latitude)) >
			<cfset r.label = dwcGeoRefDQ.getClass().getMethod("validationDecimallatitudeNotempty",array1String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment[providesGuid] = r >
			<cfset r=structNew()>

			<cfset providesGuid = dwcGeoRefDQ.getClass().getMethod("validationDecimallatitudeInrange",array1String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcGeoRefDQ.validationDecimallatitudeInrange(javaCast("string",decimal_latitude)) >
			<cfset r.label = dwcGeoRefDQ.getClass().getMethod("validationDecimallatitudeInrange",array1String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment[providesGuid] = r >
			<cfset r=structNew()>

			<cfset providesGuid = dwcGeoRefDQ.getClass().getMethod("validationDecimallongitudeNotempty",array1String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcGeoRefDQ.validationDecimallongitudeNotempty(javaCast("string",decimal_longitude)) >
			<cfset r.label = dwcGeoRefDQ.getClass().getMethod("validationDecimallongitudeNotempty",array1String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment[providesGuid] = r >
			<cfset r=structNew()>

			<cfset providesGuid = dwcGeoRefDQ.getClass().getMethod("validationDecimallongitudeInrange",array1String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcGeoRefDQ.validationDecimallongitudeInrange(javaCast("string",decimal_longitude)) >
			<cfset r.label = dwcGeoRefDQ.getClass().getMethod("validationDecimallongitudeInrange",array1String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment[providesGuid] = r >
			<cfset r=structNew()>

			<cfset providesGuid = dwcGeoRefDQ.getClass().getMethod("validationGeodeticdatumNotempty",array1String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcGeoRefDQ.validationGeodeticdatumNotempty(geodeticDatum) >
			<cfset r.label = dwcGeoRefDQ.getClass().getMethod("validationGeodeticdatumNotempty",array1String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment[providesGuid] = r >
			<cfset r=structNew()>

			<cfset providesGuid = dwcGeoRefDQ.getClass().getMethod("validationGeodeticdatumStandard",array1String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcGeoRefDQ.validationGeodeticdatumStandard(geodeticDatum) >
			<cfset r.label = dwcGeoRefDQ.getClass().getMethod("validationGeodeticdatumStandard",array1String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment[providesGuid] = r >
			<cfset r=structNew()>

			<!--- Add results from phases to result to return --->

			<cfset result["PREAMENDMENT"] = preamendment >

			<cfset result["AMENDMENT"] = amendment >

			<cfset result["POSTAMENDMENT"] = postamendment >

		<cfelse>
			<cfset result.STATUS="fail">
			<cfset result.TARGET_ID=target_id>
			<cfset result.ERROR="record not found">
		</cfif>
   <cfcatch>
		<cfset result.STATUS="fail">
		<cfset result.TARGET_ID=target_id>
		<cfset line = cfcatch.tagcontext[1].line>
		<cfset result.ERROR=cfcatch.message & '; ' & cfcatch.detail & ' [line:' & line & ']' >
   </cfcatch>
	</cftry>
   <cfreturn serializeJSON(result) >
</cffunction>

<!--- Lookup a scientific name in WoRMS and various GBIF checklist bank lists.
  @param taxon_name_id the primary key of the taxon record to look up 
  @return a json structure containing matches on each service 
--->
<cffunction name="lookupName" access="remote">
	<cfargument name="taxon_name_id" type="string" required="yes">

	<cfset result=structNew()> <!--- overall result to return --->

	<cftry>
		<cfquery name="queryrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT scientific_name as item_label, 
				kingdom, phylum, phylclass, phylorder, family, genus,
				scientific_name, author_text,
				taxonid,
				scientificnameid,
				taxon_name_id
			FROM taxonomy
			WHERE taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
		</cfquery>
	
		<cfif queryrow.recordcount EQ 1>
			<cfloop query="queryrow">

				<cfobject type="Java" class="org.filteredpush.qc.sciname.services.Validator" name="validator">
				<cfobject type="Java" class="org.filteredpush.qc.sciname.services.WoRMSService" name="wormsService">
				<cfobject type="Java" class="org.filteredpush.qc.sciname.services.GBIFService" name="gbifService">
				<cfobject type="Java" class="org.filteredpush.qc.sciname.services.IRMNGService" name="irmngService">
				<cfobject type="Java" class="edu.harvard.mcz.nametools.NameUsage" name="nameUsage">
				<cfobject type="Java" class="edu.harvard.mcz.nametools.ICZNAuthorNameComparator" name="icznComparator">

				<cfset comparator = icznComparator.init(.75,.5)>
				<cfset lookupName = nameUsage.init()>
				<cfset lookupName.setInputDbPK(val(queryrow.taxon_name_id))>
				<cfset lookupName.setScientificName(queryrow.scientific_name)>
				<cfset lookupName.setAuthorship(queryrow.author_text)>
				<cfset lookupName.setAuthorComparator(comparator)>
				<cfif len(queryrow.family) GT 0>
					<cfset lookupName.setFamily(queryrow.family)>
				</cfif>
				<cfif len(queryrow.kingdom) GT 0>
					<cfset lookupName.setKingdom(queryrow.kingdom)>
				</cfif>
				
				<!--- lookup in WoRMS --->
				<cfset wormsAuthority = wormsService.init(false)>
				<cfset returnName = wormsAuthority.validate(lookupName)>
				<cfset r=structNew()>
				<cfif isDefined("returnName")>
					<cfset r.MATCHDESCRIPTION = returnName.getMatchDescription()>
					<cfset r.SCIENTIFICNAME = returnName.getScientificName()>
					<cfset r.AUTHORSHIP = returnName.getAuthorship()>
					<cfset r.GUID = returnName.getGuid()>
					<cfset r.AUTHORSTRINGDISTANCE = returnName.getAuthorshipStringEditDistance()>
					<cfset habitatVals = "">
					<cfset separator = "">
					<cfset habitats = returnName.getExtension()>
					<cfif  habitats.get("marine") EQ "true"><cfset habitatVals = "Marine"><cfset separator=", "></cfif>
					<cfif  habitats.get("brackish") EQ "true"><cfset habitatVals = "#habitatVals##separator#Brackish"><cfset separator=", "></cfif>
					<cfif  habitats.get("freshwater") EQ "true"><cfset habitatVals = "#habitatVals##separator#Freshwater"><cfset separator=", "></cfif>
					<cfif  habitats.get("terrestrial") EQ "true"><cfset habitatVals = "#habitatVals##separator#Terrestrial"><cfset separator=", "></cfif>
					<cfif  habitats.get("extinct") EQ "true"><cfset habitatVals = "#habitatVals##separator#Extinct"><cfset separator=", "></cfif>
					<cfset r.HABITATFLAGS = "#habitatVals#">
				</cfif>
				<cfset result["WoRMS"] = r>

				<cfif find(" ", trim(queryrow.scientific_name)) EQ 0>
					<!--- lookup genera and higher taxa in IRMNG --->
					<cfset irmngAuthority = irmngService.init(false)>
					<cfset returnName = irmngAuthority.validate(lookupName)>
					<cfset r=structNew()>
					<cfif isDefined("returnName")>
						<cfset r.MATCHDESCRIPTION = returnName.getMatchDescription()>
						<cfset r.SCIENTIFICNAME = returnName.getScientificName()>
						<cfset r.AUTHORSHIP = returnName.getAuthorship()>
						<cfset r.GUID = returnName.getGuid()>
						<cfset r.AUTHORSTRINGDISTANCE = returnName.getAuthorshipStringEditDistance()>
					</cfif>
					<cfset result["IRMNG"] = r>
				</cfif>

				<!--- lookup in GBIF Backbone --->
				<cfset gbifAuthority = gbifService.init()>
				<cfset r=structNew()>
				<cftry>
					<cfset returnName = gbifAuthority.validate(lookupName)>
				<cfcatch>
					<cfset r.MATCHDESCRIPTION = "Error">
					<cfset r.SCIENTIFICNAME = "">
					<cfset r.AUTHORSHIP = "">
					<cfset r.GUID = "">
					<cfset r.AUTHORSTRINGDISTANCE = "">
					<cfset r.HABITATFLAGS = "">
				</cfcatch>
				</cftry>
				<cfif isDefined("returnName")>
					<cfset r.MATCHDESCRIPTION = returnName.getMatchDescription()>
					<cfset r.SCIENTIFICNAME = returnName.getScientificName()>
					<cfset r.AUTHORSHIP = returnName.getAuthorship()>
					<cfset r.GUID = returnName.getGuid()>
					<cfset r.AUTHORSTRINGDISTANCE = returnName.getAuthorshipStringEditDistance()>
					<cfset r.HABITATFLAGS = "">
				</cfif>
				<cfset result["GBIF Backbone"] = r>

				<!--- lookup in GBIF copy of paleobiology db --->
				<cfset gbifAuthority = gbifService.init(gbifService.KEY_PALEIOBIOLOGY_DATABASE)>
				<cfset returnName = gbifAuthority.validate(lookupName)>
				<cfset r=structNew()>
				<cfif isDefined("returnName")>
					<cfset r.MATCHDESCRIPTION = returnName.getMatchDescription()>
					<cfset r.SCIENTIFICNAME = returnName.getScientificName()>
					<cfset r.AUTHORSHIP = returnName.getAuthorship()>
					<cfset r.GUID = returnName.getGuid()>
					<cfset r.AUTHORSTRINGDISTANCE = returnName.getAuthorshipStringEditDistance()>
					<cfset r.HABITATFLAGS = "">
				</cfif>
				<cfset result["Paleobiology DB in GBIF"] = r>
			</cfloop>
		</cfif>
   <cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
   </cfcatch>
	</cftry>
   <cfreturn serializeJSON(result) >
</cffunction>

<!-------------------------------------------->
<!--- obtain QC report concerning Taxon Name terms on a record from flat or from taxonomy 
  @param target_id the collection_object_id or taxon_name_id for which to run tests
  @param target FLAT or TAXONOMY to specify whether target_id is for a collection object or a taxon.
  @return a json serialization of a structure containing preamendment, amendment, and postamendment
    phase structures containing lists of test results identified by test guid and containing 
    label, type, status, comment, value terms.
--->
<cffunction name="getNameQCReport" access="remote">
	<cfargument name="target_id" type="string" required="yes">
	<cfargument name="target" type="string" required="yes">

	<cfset result=structNew()> <!--- overall result to return --->
	<cfset r=structNew()><!--- temporary result for an individual test, create new after each test --->
	<cfset preamendment=structNew()><!--- pre-amendment phase measures and validations --->
	<cfset amendment=structNew()><!--- amendment phase --->
	<cfset postamendment=structNew()><!--- post-amendment phase measures and validations --->
	<cftry>
		<cfswitch expression="#ucase(target)#">
			<cfcase value="FLAT">
				<cfquery name="queryrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT guid as item_label, 
						basisofrecord,
						kingdom, phylum, phylclass, phylorder, '' as superfamily, family, subfamily, tribe, genus, '' as subgenus,
						scientific_name, author_text,
						taxonid,
						scientificnameid,
						taxonrank as rank,
						species as specificEpithet,
						subspecies as infraspecificEpithet
					FROM DIGIR_QUERY.digir_filtered_flat
					WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_id#">
						and rownum < 2
				</cfquery>
			</cfcase>
			<cfcase value="TAXONOMY">
				<cfquery name="queryrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT scientific_name as item_label, 
						'' as basisofrecord,
						kingdom, phylum, phylclass, phylorder, superfamily, family, subfamily, tribe, genus, subgenus,
						scientific_name, author_text,
						taxonid,
						scientificnameid,
						get_taxonrank(taxon_name_id) as rank,
						species as specificEpithet,
						subspecies as infraspecificEpithet
					FROM taxonomy
					WHERE taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_id#">
				</cfquery>
			</cfcase>
			<cfdefaultcase>
				<cfthrow message="Unknown target type for taxon report. Should be FLAT or TAXONOMY">
			</cfdefaultcase>
		</cfswitch>
		<cfif queryrow.recordcount is 1>
			<cfset result.STATUS="success">
			<cfset result.TARGET_ID=target_id >
			<cfset result.GUID=queryrow.item_label>
			<cfset result.ERROR="">

			<!--- store local copies of query results to use in pre-amendment phase and overwrite in ammendment phase  --->
			<cfset kingdom = queryrow.kingdom>
			<cfset phylum = queryrow.phylum>
			<cfset phylclass = queryrow.phylclass>
			<cfset phylorder = queryrow.phylorder>
			<cfset superfamily = queryrow.superfamily>
			<cfset family = queryrow.family>
			<cfset subfamily = queryrow.subfamily>
			<cfset tribe = queryrow.tribe>
			<cfset genus = queryrow.genus>
			<cfset genericname = queryrow.genus>
			<cfset subgenus = queryrow.subgenus>
			<cfset scientific_name = "#trim(queryrow.scientific_name)#">
			<cfset author_text = "#trim(queryrow.author_text)#">
			<cfset rank = queryrow.rank>
			<cfset specificEpithet = queryrow.specificEpithet>
			<cfset infraspecificEpithet = queryrow.infraspecificEpithet>
			<cfset taxonid = queryrow.taxonid>
			<cfset scientificnameid = queryrow.scientificnameid>
			<cfif len(author_text) GT 0 AND #scientific_name.endsWith(author_text)#>
				<cfset dwc_scientificName = #queryrow.scientific_name#>
				<cfset scientific_name = Replace(queryrow.scientific_name,queryrow.author_text,"")>
			<cfelse>
				<cfset dwc_scientificName = trim("#queryrow.scientific_name# #queryrow.author_text#")>
			</cfif>
			<cfobject type="Java" class="java.text.Normalizer" name="normalizer">
			<cfobject type="Java" class="java.text.Normalizer$Form" name="normalizerForm">
			<cfset dwc_scientificName = normalizer.normalize(javaCast("string",dwc_scientificName), normalizerForm.NFC)>

			<cfobject type="Java" class="org.filteredpush.qc.sciname.Taxon" name="taxon">
			<cfobject type="Java" class="org.filteredpush.qc.sciname.SciNameSourceAuthority" name="sciNameSourceAuthority">
			<cfobject type="Java" class="org.filteredpush.qc.sciname.DwCSciNameDQ" name="dwcSciNameDQ">
			<cfobject type="Java" class="org.datakurator.ffdq.annotations.Mechanism" name="Mechanism">
			<cfobject type="Java" class="org.datakurator.ffdq.annotations.Validation" name="Validation">
			<cfobject type="Java" class="org.datakurator.ffdq.annotations.Amendment" name="AmendmentC">
			<cfobject type="Java" class="org.datakurator.ffdq.annotations.Provides" name="Provides">
			<!--- Obtain mechanism from annotation on class --->
			<cfset result.mechanism = dwcSciNameDQ.getClass().getAnnotation(Mechanism.getClass()).label() >

			<cfset wormsAuthority = sciNameSourceAuthority.init("WORMS")>
			<cfset gbifAuthority = sciNameSourceAuthority.init("GBIF_BACKBONE_TAXONOMY")>
			<cfset irmngAuthority = sciNameSourceAuthority.init("IRMNG")>

			<!--- pre-amendment phase --->
			<cfset taxonObj = taxon.init()>
			<cfset taxonObj.setTaxonID(taxonid)>
			<cfset taxonObj.setKingdom(kingdom)>
			<cfset taxonObj.setPhylum(phylum)>
			<cfset taxonObj.setTaxonomic_class(phylclass)>
			<cfset taxonObj.setOrder(phylorder)>
			<cfset taxonObj.setSuperfamily(superfamily)>
			<cfset taxonObj.setFamily(family)>
			<cfset taxonObj.setSubfamily(subfamily)>
			<cfset taxonObj.setTribe(tribe)>
			<cfset taxonObj.setGenus(genus)>
			<cfset taxonObj.setGenericName(genus)>
			<cfset taxonObj.setScientificName(dwc_scientificName)>
			<cfset taxonObj.setScientificNameAuthorship(author_text)>
			<cfset taxonObj.setScientificNameID(scientificnameid)>
			<!--- 
			 * #120	VALIDATION_TAXONID_NOTEMPTY 401bf207-9a55-4dff-88a5-abcd58ad97fa
 			 * #121	VALIDATION_TAXONID_COMPLETE a82c7e3a-3a50-4438-906c-6d0fefa9e984
 			 * #105	VALIDATION_TAXON_NOTEMPTY 06851339-843f-4a43-8422-4e61b9a00e75
			 * #123	VALIDATION_CLASSIFICATION_CONSISTENT 2750c040-1d4a-4149-99fe-0512785f2d5f
 			 * #70	VALIDATION_TAXON_UNAMBIGUOUS 4c09f127-737b-4686-82a0-7c8e30841590
			 * #81	VALIDATION_KINGDOM_FOUND 125b5493-052d-4a0d-a3e1-ed5bf792689e
			 * #22	VALIDATION_PHYLUM_FOUND eaad41c5-1d46-4917-a08b-4fd1d7ff5c0f
			 * #77	VALIDATION_CLASS_FOUND 2cd6884e-3d14-4476-94f7-1191cfff309b
			 * #83	VALIDATION_ORDER_FOUND 81cc974d-43cc-4c0f-a5e0-afa23b455aa3
			 * #28	VALIDATION_FAMILY_FOUND 3667556d-d8f5-454c-922b-af8af38f613c
			 * #122	VALIDATION_GENUS_FOUND f2ce7d55-5b1d-426a-b00e-6d4efe3058ec
			 * #82	VALIDATION_SCIENTIFICNAME_NOTEMPTY 7c4b9498-a8d9-4ebb-85f1-9f200c788595
			 * #46	VALIDATION_SCIENTIFICNAME_FOUND 3f335517-f442-4b98-b149-1e87ff16de45
 			 * #101	VALIDATION_POLYNOMIAL_CONSISTENT 17f03f1f-f74d-40c0-8071-2927cfc9487b
			 * #161	VALIDATION_TAXONRANK_NOTEMPTY 14da5b87-8304-4b2b-911d-117e3c29e890
 			 * #162	VALIDATION_TAXONRANK_STANDARD 7bdb13a4-8a51-4ee5-be7f-20693fdb183e
			--->
			<cfset r=structNew()>
			<cfset aString = "">
			<!--- @Provides("2750c040-1d4a-4149-99fe-0512785f2d5f") --->
			<cfset providesGuid = dwcSciNameDQ.getClass().getMethod("validationClassificationConsistent",[aString.getClass(),aString.getClass(),aString.getClass(),aString.getClass(),aString.getClass(),aString.getClass(),aString.getClass(),aString.getClass(),aString.getClass(),aString.getClass(),sciNameSourceAuthority.getClass()]).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcSciNameDQ.validationClassificationConsistent(kingdom, phylum, phylclass, phylorder, superfamily, family, subfamily, tribe, "", genus, gbifAuthority) >
			<cfset r.label = dwcSciNameDQ.getClass().getMethod("validationClassificationConsistent",[aString.getClass(),aString.getClass(),aString.getClass(),aString.getClass(),aString.getClass(),aString.getClass(),aString.getClass(),aString.getClass(),aString.getClass(),aString.getClass(),sciNameSourceAuthority.getClass()]).getAnnotation(Validation.getClass()).description() >
			<cfset r.label = replace(r.label,"bdq:sourceAuthority","GBIF")>
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment[providesGuid] = r >
			<cfset r=structNew()>

			<!--- @Provides("401bf207-9a55-4dff-88a5-abcd58ad97fa") --->
			<cfset providesGuid = dwcSciNameDQ.getClass().getMethod("validationTaxonidNotempty",[aString.getClass()]).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcSciNameDQ.validationTaxonidNotempty(taxonid) >
			<cfset r.label = dwcSciNameDQ.getClass().getMethod("validationTaxonidNotempty",[aString.getClass()]).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment[providesGuid] = r >
			<cfset r=structNew()>

			<!--- @Provides("a82c7e3a-3a50-4438-906c-6d0fefa9e984") --->
			<cfset providesGuid = dwcSciNameDQ.getClass().getMethod("validationTaxonidComplete",[aString.getClass()]).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcSciNameDQ.validationTaxonidComplete(taxonid) >
			<cfset r.label = dwcSciNameDQ.getClass().getMethod("validationTaxonidComplete",[aString.getClass()]).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment[providesGuid] = r >
			<cfset r=structNew()>

			<!--- @Provides("14da5b87-8304-4b2b-911d-117e3c29e890") --->
			<cfset providesGuid = dwcSciNameDQ.getClass().getMethod("validationTaxonrankNotempty",[aString.getClass()]).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcSciNameDQ.validationTaxonrankNotempty(rank) >
			<cfset r.label = dwcSciNameDQ.getClass().getMethod("validationTaxonrankNotempty",[aString.getClass()]).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment[providesGuid] = r >
			<cfset r=structNew()>

			<!--- @Provides("7bdb13a4-8a51-4ee5-be7f-20693fdb183e") --->
			<cfset providesGuid = dwcSciNameDQ.getClass().getMethod("validationTaxonrankStandard",[aString.getClass(),aString.getClass()]).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcSciNameDQ.validationTaxonrankStandard(rank,"https://rs.gbif.org/vocabulary/gbif/rank.xml") >
			<cfset r.label = dwcSciNameDQ.getClass().getMethod("validationTaxonrankStandard",[aString.getClass(),aString.getClass()]).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment[providesGuid] = r >
			<cfset r=structNew()>

			<!--- @Provides("7c4b9498-a8d9-4ebb-85f1-9f200c788595") --->
			<cfset dqResponse = dwcSciNameDQ.validationScientificnameNotempty(dwc_scientificName) >
			<cfset r.label = "dwc:scientificName contains a value" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["7c4b9498-a8d9-4ebb-85f1-9f200c788595"] = r >
			<cfset r=structNew()>

			<!--- @Provides("f2ce7d55-5b1d-426a-b00e-6d4efe3058ec") --->
			<cfset dqResponse = dwcSciNameDQ.validationGenusFound(genus,gbifAuthority) >
			<cfset r.label = "dwc:genus is known to GBIF" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["f2ce7d55-5b1d-426a-b00e-6d4efe3058ec"] = r >
			<cfset r=structNew()>

			<!--- @Provides("3f335517-f442-4b98-b149-1e87ff16de45") --->
			<cfset dqResponse = dwcSciNameDQ.validationScientificnameFound(dwc_scientificName,gbifAuthority) >
			<cfset r.label = "dwc:scientificName is known to GBIF" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["3f335517-f442-4b98-b149-1e87ff16de45"] = r >
			<cfset r=structNew()>

			<!--- @Provides("3667556d-d8f5-454c-922b-af8af38f613c") --->
			<cfset dqResponse = dwcSciNameDQ.validationFamilyFound(family,gbifAuthority) >
			<cfset r.label = "dwc:family is known to GBIF" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["3667556d-d8f5-454c-922b-af8af38f613c"] = r >
			<cfset r=structNew()>

			<!--- @Provides("81cc974d-43cc-4c0f-a5e0-afa23b455aa3") --->
			<cfset dqResponse = dwcSciNameDQ.validationOrderFound(phylorder,gbifAuthority) >
			<cfset r.label = "dwc:order is known to GBIF" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["81cc974d-43cc-4c0f-a5e0-afa23b455aa3"] = r >
			<cfset r=structNew()>

			<!--- @Provides("2cd6884e-3d14-4476-94f7-1191cfff309b") --->
			<cfset dqResponse = dwcSciNameDQ.validationClassFound(phylclass,gbifAuthority) >
			<cfset r.label = "dwc:class is known to GBIF" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["2cd6884e-3d14-4476-94f7-1191cfff309b"] = r >
			<cfset r=structNew()>

			<!--- @Provides("eaad41c5-1d46-4917-a08b-4fd1d7ff5c0f") --->
			<cfset dqResponse = dwcSciNameDQ.validationPhylumFound(phylum,gbifAuthority) >
			<cfset r.label = "dwc:phylum is known to GBIF" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["eaad41c5-1d46-4917-a08b-4fd1d7ff5c0f"] = r >
			<cfset r=structNew()>

			<!--- @Provides("125b5493-052d-4a0d-a3e1-ed5bf792689e") --->
			<cfset dqResponse = dwcSciNameDQ.validationKingdomFound(kingdom,gbifAuthority) >
			<cfset r.label = "dwc:kingdom is known to GBIF" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["125b5493-052d-4a0d-a3e1-ed5bf792689e"] = r >
			<cfset r=structNew()>

			<!--- @Provides("06851339-843f-4a43-8422-4e61b9a00e75") --->
			<cfset array25String = ArrayNew(1)>
			<cfset ArraySet(array25String,1,25,aString.getClass())>
			<cfset providesGuid = dwcSciNameDQ.getClass().getMethod("validationTaxonNotempty",array25String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcSciNameDQ.validationTaxonNotempty(phylclass, genus, '', phylum, scientificnameid, taxonid, '', subgenus, '', '', '', '', kingdom, family, dwc_scientificname, genericName, '', specificEpithet, infraspecificEpithet, phylorder, '', subfamily, superfamily, tribe, "") >
			<cfset r.label = dwcSciNameDQ.getClass().getMethod("validationTaxonNotempty",array25String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment[providesGuid] = r >
			<cfset r=structNew()>

			<!--- @Provides("4c09f127-737b-4686-82a0-7c8e30841590") --->
			<cfset arrayForTaxonUnamb = ArrayNew(1)>
			<cfset ArraySet(arrayForTaxonUnamb,1,27,aString.getClass())>
			<cfset providesGuid = dwcSciNameDQ.getClass().getMethod("validationTaxonUnambiguous",arrayForTaxonUnamb).getAnnotation(Provides.getClass()).value() >
			<cfif len(taxonid) GT 0 AND find("marinespecies.org",taxonid) GT 0>
				<cfset dqResponse = dwcSciNameDQ.validationTaxonUnambiguous(taxonObj,wormsAuthority.getName()) >
			<cfelseif len(taxonid) GT 0 AND find("irmng.org",taxonid) GT 0>
				<cfset dqResponse = dwcSciNameDQ.validationTaxonUnambiguous(taxonObj,irmngAuthority.getName()) >
			<cfelse>
				<cfset dqResponse = dwcSciNameDQ.validationTaxonUnambiguous(taxonObj,gbifAuthority.getName()) >
			</cfif>
			<cfset r.label = dwcSciNameDQ.getClass().getMethod("validationTaxonUnambiguous",arrayForTaxonUnamb).getAnnotation(Validation.getClass()).description() >
			<cfif len(taxonid) GT 0 AND find("marinespecies.org",taxonid) GT 0>
				<cfset r.label = replace(r.label,"bdq:sourceAuthority","WoRMS")>
			<cfelseif len(taxonid) GT 0 AND find("irmng.org",taxonid) GT 0>
				<cfset r.label = replace(r.label,"bdq:sourceAuthority","IRMNG")>
			<cfelse>
				<cfset r.label = replace(r.label,"bdq:sourceAuthority","GBIF")>
			</cfif>
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment[providesGuid] = r >
			<cfset r=structNew()>

			<!--- @Provides("17f03f1f-f74d-40c0-8071-2927cfc9487b") --->
			<cfset array4String = ArrayNew(1)>
			<cfset ArraySet(array4String,1,4,aString.getClass())>
			<cfset providesGuid = dwcSciNameDQ.getClass().getMethod("validationPolynomialConsistent",array4String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcSciNameDQ.validationPolynomialConsistent(scientific_name, genericname, specificEpithet, infraspecificEpithet) >
			<cfset r.label = dwcSciNameDQ.getClass().getMethod("validationPolynomialConsistent",array4String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment[providesGuid] = r >
			<cfset r=structNew()>

			<!--- amendment phase --->
			<!--- 
 			* #57	AMENDMENT_TAXONID_FROM_TAXON 431467d6-9b4b-48fa-a197-cd5379f5e889
			* #71	AMENDMENT_SCIENTIFICNAME_FROM_TAXONID f01fb3f9-2f7e-418b-9f51-adf50f202aea
			* #163	AMENDMENT_TAXONRANK_STANDARDIZED e39098df-ef46-464c-9aef-bcdeee2a88cb
			--->

			<!---  @Provides("431467d6-9b4b-48fa-a197-cd5379f5e889") --->
			<cfset dqResponse = dwcSciNameDQ.amendmentTaxonidFromTaxon(taxonObj,wormsAuthority) >
			<cfset r.label = "lookup taxonID for taxon" >
			<cfset r.type = "AMENDMENT" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "AMENDED" OR r.status EQ "FILLED_IN">
				<cfset taxonid = dqResponse.getValue().getObject().get("dwc:taxonID") >
				<cfset r.value = dqResponse.getValue().getObject().toString() >
			<cfelse>
				<cfset r.value = "">
			</cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfif r.status EQ "AMENDED" OR r.status EQ "FILLED_IN">
				<!--- amendment ran, thus report it --->
				<cfset amendment["431467d6-9b4b-48fa-a197-cd5379f5e889"] = r >
			</cfif>
			<cfset r=structNew()>

			<cfset providesGuid = dwcSciNameDQ.getClass().getMethod("amendmentTaxonrankStandardized",[aString.getClass(),aString.getClass()]).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcSciNameDQ.amendmentTaxonrankStandardized(rank,"https://rs.gbif.org/vocabulary/gbif/rank.xml") >
			<cfset r.label = dwcSciNameDQ.getClass().getMethod("amendmentTaxonrankStandardized",[aString.getClass(),aString.getClass()]).getAnnotation(AmendmentC.getClass()).description() >
			<cfset r.type = "AMENDMENT" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "AMENDED" OR r.status EQ "FILLED_IN">
				<cfset rank = dqResponse.getValue().getObject().get("dwc:taxonRank") >
				<cfset r.value = dqResponse.getValue().getObject().toString() >
			<cfelse>
				<cfset r.value = "">
			</cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfif r.status EQ "AMENDED" OR r.status EQ "FILLED_IN">
				<cfset amendment[providesGuid] = r >
			</cfif>
			<cfset r=structNew()>

			<cfif len(dwc_scientificName) EQ 0 AND len(taxonID) GT 0>
				<!--- not expected to be run --->
				<cfset providesGuid = dwcSciNameDQ.getClass().getMethod("amendmentScientificnameFromTaxonid",[aString.getClass(),aString.getClass(),sciNameSourceAuthority.getClass()]).getAnnotation(Provides.getClass()).value() >
				<cfset dqResponse = dwcSciNameDQ.amendmentScientificnameFromTaxonid(taxonID, dwc_scientificName, wormsAuthority) >
				<cfset r.label = dwcSciNameDQ.getClass().getMethod("amendmentScientificnameFromTaxonid",[aString.getClass(),aString.getClass(),aString.getClass(),sciNameSourceAuthority.getClass()]).getAnnotation(AmendmentC.getClass()).description() >
				<cfset r.type = "AMENDMENT" >
				<cfset r.status = dqResponse.getResultState().getLabel() >
				<cfif r.status eq "AMENDED" OR r.status EQ "FILLED_IN">
					<cfset rank = dqResponse.getValue().getObject().get("dwc:taxonRank") >
					<cfset r.value = dqResponse.getValue().getObject().toString() >
				<cfelse>
					<cfset r.value = "">
				</cfif>
				<cfset r.comment = dqResponse.getComment() >
				<cfif r.status EQ "AMENDED" OR r.status EQ "FILLED_IN">
					<cfset amendment[providesGuid] = r >
				</cfif>
				<cfset r=structNew()>
			</cfif>

			<!--- post-amendment phase --->
			<cfset taxonObj = taxon.init()>
			<cfset taxonObj.setTaxonID(taxonid)>
			<cfset taxonObj.setKingdom(kingdom)>
			<cfset taxonObj.setPhylum(phylum)>
			<cfset taxonObj.setTaxonomic_class(phylclass)>
			<cfset taxonObj.setOrder(phylorder)>
			<cfset taxonObj.setSuperfamily(superfamily)>
			<cfset taxonObj.setFamily(family)>
			<cfset taxonObj.setSubfamily(subfamily)>
			<cfset taxonObj.setTribe(tribe)>
			<cfset taxonObj.setGenus(genus)>
			<cfset taxonObj.setGenericName(genus)>
			<cfset taxonObj.setScientificName(dwc_scientificName)>
			<cfset taxonObj.setScientificNameAuthorship(author_text)>
			<cfset taxonObj.setScientificNameID(scientificnameid)>

			<cfset providesGuid = dwcSciNameDQ.getClass().getMethod("validationClassificationConsistent",[aString.getClass(),aString.getClass(),aString.getClass(),aString.getClass(),aString.getClass(),aString.getClass(),aString.getClass(),aString.getClass(),aString.getClass(),aString.getClass(),sciNameSourceAuthority.getClass()]).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcSciNameDQ.validationClassificationConsistent(kingdom, phylum, phylclass, phylorder, superfamily, family, subfamily, tribe, "", genus, gbifAuthority) >
			<cfset r.label = dwcSciNameDQ.getClass().getMethod("validationClassificationConsistent",[aString.getClass(),aString.getClass(),aString.getClass(),aString.getClass(),aString.getClass(),aString.getClass(),aString.getClass(),aString.getClass(),aString.getClass(),aString.getClass(),sciNameSourceAuthority.getClass()]).getAnnotation(Validation.getClass()).description() >
			<cfset r.label = replace(r.label,"bdq:sourceAuthority","GBIF")>
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment[providesGuid] = r >
			<cfset r=structNew()>

			<!--- @Provides("401bf207-9a55-4dff-88a5-abcd58ad97fa") --->
			<cfset providesGuid = dwcSciNameDQ.getClass().getMethod("validationTaxonidNotempty",[aString.getClass()]).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcSciNameDQ.validationTaxonidNotempty(taxonid) >
			<cfset r.label = dwcSciNameDQ.getClass().getMethod("validationTaxonidNotempty",[aString.getClass()]).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment[providesGuid] = r >
			<cfset r=structNew()>

			<!--- @Provides("a82c7e3a-3a50-4438-906c-6d0fefa9e984") --->
			<cfset providesGuid = dwcSciNameDQ.getClass().getMethod("validationTaxonidComplete",[aString.getClass()]).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcSciNameDQ.validationTaxonidComplete(taxonid) >
			<cfset r.label = dwcSciNameDQ.getClass().getMethod("validationTaxonidComplete",[aString.getClass()]).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment[providesGuid] = r >
			<cfset r=structNew()>

			<!--- @Provides("14da5b87-8304-4b2b-911d-117e3c29e890") --->
			<cfset providesGuid = dwcSciNameDQ.getClass().getMethod("validationTaxonrankNotempty",[aString.getClass()]).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcSciNameDQ.validationTaxonrankNotempty(rank) >
			<cfset r.label = dwcSciNameDQ.getClass().getMethod("validationTaxonrankNotempty",[aString.getClass()]).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment[providesGuid] = r >
			<cfset r=structNew()>

			<!--- @Provides("7bdb13a4-8a51-4ee5-be7f-20693fdb183e") --->
			<cfset providesGuid = dwcSciNameDQ.getClass().getMethod("validationTaxonrankStandard",[aString.getClass(),aString.getClass()]).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcSciNameDQ.validationTaxonrankStandard(rank,"https://rs.gbif.org/vocabulary/gbif/rank.xml") >
			<cfset r.label = dwcSciNameDQ.getClass().getMethod("validationTaxonrankStandard",[aString.getClass(),aString.getClass()]).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment[providesGuid] = r >
			<cfset r=structNew()>

			<!--- @Provides("7c4b9498-a8d9-4ebb-85f1-9f200c788595") --->
			<cfset dqResponse = dwcSciNameDQ.validationScientificnameNotempty(dwc_scientificName) >
			<cfset r.label = "dwc:scientificName contains a value" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["7c4b9498-a8d9-4ebb-85f1-9f200c788595"] = r >
			<cfset r=structNew()>

			<!--- @Provides("3f335517-f442-4b98-b149-1e87ff16de45") --->
			<cfset dqResponse = dwcSciNameDQ.validationScientificnameFound(dwc_scientificName,gbifAuthority) >
			<cfset r.label = "dwc:scientificName is known to GBIF" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["3f335517-f442-4b98-b149-1e87ff16de45"] = r >
			<cfset r=structNew()>

			<!--- @Provides("f2ce7d55-5b1d-426a-b00e-6d4efe3058ec") --->
			<cfset dqResponse = dwcSciNameDQ.validationGenusFound(genus,gbifAuthority) >
			<cfset r.label = "dwc:genus is known to GBIF" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["f2ce7d55-5b1d-426a-b00e-6d4efe3058ec"] = r >
			<cfset r=structNew()>

			<!--- @Provides("3667556d-d8f5-454c-922b-af8af38f613c") --->
			<cfset dqResponse = dwcSciNameDQ.validationFamilyFound(family,gbifAuthority) >
			<cfset r.label = "dwc:family is known to GBIF" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["3667556d-d8f5-454c-922b-af8af38f613c"] = r >
			<cfset r=structNew()>
	
			<!--- @Provides("81cc974d-43cc-4c0f-a5e0-afa23b455aa3") --->
			<cfset dqResponse = dwcSciNameDQ.validationOrderFound(phylorder,gbifAuthority) >
			<cfset r.label = "dwc:order is known to GBIF" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["81cc974d-43cc-4c0f-a5e0-afa23b455aa3"] = r >
			<cfset r=structNew()>

			<!--- @Provides("2cd6884e-3d14-4476-94f7-1191cfff309b") --->
			<cfset dqResponse = dwcSciNameDQ.validationClassFound(phylclass,gbifAuthority) >
			<cfset r.label = "dwc:class is known to GBIF" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["2cd6884e-3d14-4476-94f7-1191cfff309b"] = r >
			<cfset r=structNew()>

			<!--- @Provides("eaad41c5-1d46-4917-a08b-4fd1d7ff5c0f") --->
			<cfset dqResponse = dwcSciNameDQ.validationPhylumFound(phylum,gbifAuthority) >
			<cfset r.label = "dwc:phylum is known to GBIF" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["eaad41c5-1d46-4917-a08b-4fd1d7ff5c0f"] = r >
			<cfset r=structNew()>

			<!--- @Provides("125b5493-052d-4a0d-a3e1-ed5bf792689e") --->
			<cfset dqResponse = dwcSciNameDQ.validationKingdomFound(kingdom,gbifAuthority) >
			<cfset r.label = "dwc:kingdom is known to GBIF" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["125b5493-052d-4a0d-a3e1-ed5bf792689e"] = r >
			<cfset r=structNew()>

			<!--- @Provides("06851339-843f-4a43-8422-4e61b9a00e75") --->
			<cfset providesGuid = dwcSciNameDQ.getClass().getMethod("validationTaxonNotempty",array25String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcSciNameDQ.validationTaxonNotempty(phylclass, genus, '', phylum, scientificNameId, taxonId, '', subgenus, '', '', '', '', kingdom, family, dwc_scientificname, genericName, '', specificEpithet, infraspecificEpithet, phylorder, '', subfamily, superfamily, tribe, "") >
			<cfset r.label = dwcSciNameDQ.getClass().getMethod("validationTaxonNotempty",array25String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment[providesGuid] = r >
			<cfset r=structNew()>

			<!--- @Provides("4c09f127-737b-4686-82a0-7c8e30841590") --->
			<cfset providesGuid = dwcSciNameDQ.getClass().getMethod("validationTaxonUnambiguous",arrayForTaxonUnamb).getAnnotation(Provides.getClass()).value() >
			<cfif len(taxonid) GT 0 AND find("marinespecies.org",taxonid) GT 0>
				<cfset dqResponse = dwcSciNameDQ.validationTaxonUnambiguous(taxonObj,wormsAuthority.getName()) >
			<cfelseif len(taxonid) GT 0 AND find("irmng.org",taxonid) GT 0>
				<cfset dqResponse = dwcSciNameDQ.validationTaxonUnambiguous(taxonObj,irmngAuthority.getName()) >
			<cfelse>
				<cfset dqResponse = dwcSciNameDQ.validationTaxonUnambiguous(taxonObj,gbifAuthority.getName()) >
			</cfif>
			<cfset r.label = dwcSciNameDQ.getClass().getMethod("validationTaxonUnambiguous",arrayForTaxonUnamb).getAnnotation(Validation.getClass()).description() >
			<cfif len(taxonid) GT 0 AND find("marinespecies.org",taxonid) GT 0>
				<cfset r.label = replace(r.label,"bdq:sourceAuthority","WoRMS")>
			<cfelseif len(taxonid) GT 0 AND find("irmng.org",taxonid) GT 0>
				<cfset r.label = replace(r.label,"bdq:sourceAuthority","IRMNG")>
			<cfelse>
				<cfset r.label = replace(r.label,"bdq:sourceAuthority","GBIF")>
			</cfif>
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment[providesGuid] = r >
			<cfset r=structNew()>

			<!--- @Provides("17f03f1f-f74d-40c0-8071-2927cfc9487b") --->
			<cfset array4String = ArrayNew(1)>
			<cfset ArraySet(array4String,1,4,aString.getClass())>
			<cfset providesGuid = dwcSciNameDQ.getClass().getMethod("validationPolynomialConsistent",array4String).getAnnotation(Provides.getClass()).value() >
			<cfset dqResponse = dwcSciNameDQ.validationPolynomialConsistent(scientific_name, genericname, specificEpithet, infraspecificEpithet) >
			<cfset r.label = dwcSciNameDQ.getClass().getMethod("validationPolynomialConsistent",array4String).getAnnotation(Validation.getClass()).description() >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment[providesGuid] = r >
			<cfset r=structNew()>

			<!--- Add results from phases to result to return --->

			<cfset result["PREAMENDMENT"] = preamendment >

			<cfset result["AMENDMENT"] = amendment >

			<cfset result["POSTAMENDMENT"] = postamendment >

		<cfelse>
			<cfset result.STATUS="fail">
			<cfset result.TARGET_ID=target_id>
			<cfset result.ERROR="record not found">
		</cfif>
    <cfcatch>
			<cfset result.STATUS="fail">
			<cfset result.TARGET_ID=target_id>
			<cfset line = cfcatch.tagcontext[1].line>
			<cfset result.ERROR=cfcatch.message & '; ' & cfcatch.detail & ' [line:' & line & ']' >
    </cfcatch>
	</cftry>
    <cfreturn serializeJSON(result) >
</cffunction>

<!-------------------------------------------->
<!--- obtain QC report concerning Event (temporal) terms on a record from flat
  @param target_id the collection_object_id or colecting_event_id for which to run tests
  @param target FLAT or COLLEVENT to specify whether target_id is for a collection object 
    or a collecting event.
  @return a json serialization of a structure containing preamendment, amendment, and postamendment
    phase structures containing lists of test results identified by test guid and containing 
    label, type, status, comment, value terms.
 --->
<cffunction name="getEventQCReportFlat" access="remote">
	<cfargument name="target_id" type="string" required="yes">
	<cfargument name="target" type="string" required="yes">

	<cfset result=structNew()> <!--- overall result to return --->
	<cfset r=structNew()><!--- temporary result for an individual test, create new after each test --->
	<cfset preamendment=structNew()><!--- pre-amendment phase measures and validations --->
	<cfset amendment=structNew()><!--- amendment phase --->
	<cfset postamendment=structNew()><!--- post-amendment phase measures and validations --->
	<cftry>
		<cfswitch expression="#ucase(target)#">
			<cfcase value="FLAT">
				<cfquery name="flatrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT guid as item_label,
						basisofrecord,
						began_date, ended_date, verbatim_date, day, month, year, 
						dayofyear, endDayOfYear,
						scientific_name, made_date
					FROM DIGIR_QUERY.digir_filtered_flat
					WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_id#">
				</cfquery>
			</cfcase>
			<cfcase value="COLLEVENT">
				<cfquery name="flatrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT collecting_event_id as item_label, 
						'' as basisofrecord,
						began_date, ended_date, verbatim_date, day, month, year, 
						dayofyear, endDayOfYear,
						scientific_name, made_date
					FROM DIGIR_QUERY.digir_filtered_flat
					WHERE collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_id#">
						AND rownum < 2
				</cfquery>
			</cfcase>
			<cfdefaultcase>
				<cfthrow message="Unknown target type for taxon report. Should be FLAT or TAXONOMY">
			</cfdefaultcase>
		</cfswitch>

		<cfif flatrow.recordcount is 1>
			<cfset result.STATUS="success">
			<cfset result.TARGET_ID=target_id>
			<cfset result.GUID=flatrow.item_label>
			<cfset result.ERROR="">

			<!--- store local copies of query results to use in pre-amendment phase  --->
			<cfif flatrow.began_date EQ flatrow.ended_date>
				<cfset eventDate = flatrow.began_date>
			<cfelse>
				<cfset eventDate = flatrow.began_date & "/" & flatrow.ended_date>
			</cfif>

			<cfset dateIdentified = flatrow.made_date>
			<cfset verbatimEventDate = flatrow.verbatim_date>
			<cfset startDayOfYear = ToString(flatrow.dayofyear) >
			<cfset endDayOfYear= flatrow.endDayOfYear >
			<cfset year=ToString(flatrow.year) >
			<cfset month=ToString(flatrow.month) >
			<cfset day=ToString(flatrow.day) >

			<cfobject type="Java" class="org.filteredpush.qc.date.DwCOtherDateDQ" name="dwcOtherDateQC">
			<cfobject type="Java" class="org.filteredpush.qc.date.DwCOtherDateDQDefaults" name="dwcOtherDateQCDefaults">
			<cfobject type="Java" class="org.filteredpush.qc.date.DwCEventDQ" name="dwcEventDQ">
			<cfobject type="Java" class="org.filteredpush.qc.date.DwCEventDQDefaults" name="dwcEventDQDefaults">
			<cfobject type="Java" class="org.datakurator.ffdq.annotations.Mechanism" name="Mechanism">
			<cfobject type="Java" class="org.datakurator.ffdq.annotations.Provides" name="Provides">
			<!--- Obtain mechanism from annotation on class --->
			<cfset result.mechanism = dwcEventDQ.getClass().getAnnotation(Mechanism.getClass()).label() >

			<!--- pre-amendment phase --->

			<!--- @Provides("56b6c695-adf1-418e-95d2-da04cad7be53") --->
			<!--- TODO: Provide metadata from annotations --->
			<!---
			dwcEventDQ.getClass().getMethod('measureEventdateDurationinseconds',String.class).getAnnotation(Provides.getClass()).label();

			<cfset methodArray = dwcEventDQ.getClass().getMethods() >

			<cfloop from="0" to="#arraylen(methodArray)#" index="i">
				<cfset method = methodArray[i]>
				<cfset provides = method.getAnnotation(Provides.getClass()).label() >

			</cfloop>

			--->

			<cfset dqResponse = dwcEventDQ.measureEventdateDurationinseconds(eventDate) >
			<cfset r.label = "dwc:eventDate precision in seconds" >
			<cfset r.type = "MEASURE" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT">
				<cfset r.value = dqResponse.getValue().getObject() >
				<cfset days = Round(r.value / 60 / 60 / 24)>
				<cfif days EQ 1><cfset s=""><cfelse><cfset s="s"></cfif>
				<cfset r.comment = dqResponse.getComment() & " (" & days & " day" & s &")" >
			<cfelse>
				<cfset r.value = "">
				<cfset r.comment = dqResponse.getComment()  >
			</cfif>
			<cfset preamendment["56b6c695-adf1-418e-95d2-da04cad7be53"] = r >
			<cfset r=structNew()>

			<!--- @Provides("66269bdd-9271-4e76-b25c-7ab81eebe1d8") --->
			<cfset dqResponse = dwcOtherDateQC.validationDateidentifiedStandard(dateIdentified) >
			<cfset r.label = "dwc:dateIdentified in standard format" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["66269bdd-9271-4e76-b25c-7ab81eebe1d8"] = r >
			<cfset r=structNew()>

			<!--- @Provides("dc8aae4b-134f-4d75-8a71-c4186239178e") --->
			<cfset dqResponse = dwcOtherDateQCDefaults.validationDateidentifiedInrange(dateIdentified, eventDate)>
			<cfset r.label = "dwc:dateIdentified in range" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["dc8aae4b-134f-4d75-8a71-c4186239178e"] = r >
			<cfset r=structNew()>

			<!---  @Provides("47ff73ba-0028-4f79-9ce1-ee7008d66498") --->
			<cfset dqResponse =  dwcEventDQ.validationDayStandard(day) >
			<cfset r.label = "dwc:day in standard format" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["47ff73ba-0028-4f79-9ce1-ee7008d66498"] = r >
			<cfset r=structNew()>

			<!--- @Provides("5618f083-d55a-4ac2-92b5-b9fb227b832f") --->
			<cfset dqResponse = dwcEventDQ.validationDayInrange(year, month, day) >
			<cfset r.label = "dwc:day in range for month and year" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["5618f083-d55a-4ac2-92b5-b9fb227b832f"] = r >
			<cfset r=structNew()>

			<!---  @Provides("9a39d88c-7eee-46df-b32a-c109f9f81fb8") --->
			<cfset dqResponse =dwcEventDQ.validationEnddayofyearInrange(endDayOfYear, eventDate) >
			<cfset r.label = "dwc:endDayOfYear in range for year" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["9a39d88c-7eee-46df-b32a-c109f9f81fb8"] = r >
			<cfset r=structNew()>

			<!---  @Provides("41267642-60ff-4116-90eb-499fee2cd83f") --->
			<cfset dqResponse = dwcEventDQ.validationEventTemporalNotEmpty(eventDate,verbatimEventDate,year,month,day,startDayOfYear,endDayOfYear) >
			<cfset r.label = "dwc:Event terms contain some value" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["41267642-60ff-4116-90eb-499fee2cd83f"] = r >
			<cfset r=structNew()>

			<!--- @Provides("5618f083-d55a-4ac2-92b5-b9fb227b832f")  --->
			<cfset dqResponse = dwcEventDQ.validationEventConsistent(eventDate,year,month,day,startDayOfYear,endDayOfYear) >
			<cfset r.label = "dwc:Event terms are consistent" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["5618f083-d55a-4ac2-92b5-b9fb227b832f"] = r >
			<cfset r=structNew()>

			<!--- @Provides("f51e15a6-a67d-4729-9c28-3766299d2985") --->
			<cfset dqResponse = dwcEventDQ.validationEventdateNotEmpty(eventDate) >
			<cfset r.label = "dwc:eventDate contains a value" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["f51e15a6-a67d-4729-9c28-3766299d2985"] = r >
			<cfset r=structNew()>

			<!---  @Provides("4f2bf8fd-fc5c-493f-a44c-e7b16153c803") --->
			<cfset dqResponse = dwcEventDQ.validationEventdateStandard(eventDate) >
			<cfset r.label = "dwc:eventDate is in standard form" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["4f2bf8fd-fc5c-493f-a44c-e7b16153c803"] = r >
			<cfset r=structNew()>

			<!--- @Provides("3cff4dc4-72e9-4abe-9bf3-8a30f1618432") --->
			<cfset dqResponse = dwcEventDQDefaults.validationEventdateInrange(eventDate) >
			<cfset r.label = "dwc:eventDate is in range" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["3cff4dc4-72e9-4abe-9bf3-8a30f1618432"] = r >
			<cfset r=structNew()>

			<!--- @Provides("01c6dafa-0886-4b7e-9881-2c3018c98bdc") --->
			<cfset dqResponse = dwcEventDQ.validationMonthStandard(month) >
			<cfset r.label = "dwc:month is in standard form" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["01c6dafa-0886-4b7e-9881-2c3018c98bdc"] = r >
			<cfset r=structNew()>

			<!--- @Provides("85803c7e-2a5a-42e1-b8d3-299a44cafc46") --->
			<cfset dqResponse = dwcEventDQ.validationStartdayofyearInrange(startDayOfYear,eventDate) >
			<cfset r.label = "dwc:startDayOfYear is in range for year" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["85803c7e-2a5a-42e1-b8d3-299a44cafc46"] = r >
			<cfset r=structNew()>

			<!--- @Provides("c09ecbf9-34e3-4f3e-b74a-8796af15e59f") --->
			<cfset dqResponse = dwcEventDQ.validationYearNotEmpty(year) >
			<cfset r.label = "dwc:Year contains a value" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["c09ecbf9-34e3-4f3e-b74a-8796af15e59f"] = r >
			<cfset r=structNew()>

			<!--- @Provides("ad0c8855-de69-4843-a80c-a5387d20fbc8") --->
			<cfset dqResponse = dwcEventDQDefaults.validationYearInrange(year) >
			<cfset r.label = "dwc:Year is in range" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["ad0c8855-de69-4843-a80c-a5387d20fbc8"] = r >
			<cfset r=structNew()>

			<!--- amendment phase --->

			<!---  @Provides("39bb2280-1215-447b-9221-fd13bc990641") --->
			<cfset dqResponse= dwcOtherDateQC.amendmentDateidentifiedStandardized(dateIdentified) >
			<cfset r.label = "standardize dwc:dateIdentified" >
			<cfset r.type = "AMENDMENT" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "AMENDED">
				<cfset dateIdentified = dqResponse.getValue().getObject().get("dwc:dateIdentified") >
				<cfset r.value = dqResponse.getValue().getObject().toString() >
			<cfelse>
				<cfset r.value = "">
			</cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset amendment["39bb2280-1215-447b-9221-fd13bc990641"] = r >
			<cfset r=structNew()>

			<!--- @Provides("b129fa4d-b25b-43f7-9645-5ed4d44b357b") --->
			<cfset dqResponse = dwcEventDQ.amendmentDayStandardized(day) >
			<cfset r.label = "standardize dwc:day" >
			<cfset r.type = "AMENDMENT" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "AMENDED">
				<cfset day = dqResponse.getValue().getObject().get("dwc:day") >
				<cfset r.value = dqResponse.getValue().getObject().toString() >
			<cfelse>
				<cfset r.value = "">
			</cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset amendment["b129fa4d-b25b-43f7-9645-5ed4d44b357b"] = r >
			<cfset r=structNew()>

			<!--- @Provides("2e371d57-1eb3-4fe3-8a61-dff43ced50cf") --->
			<cfset dqResponse = dwcEventDQ.amendmentMonthStandardized(month) >
			<cfset r.label = "standardize dwc:month" >
			<cfset r.type = "AMENDMENT" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "AMENDED">
				<cfset month = dqResponse.getValue().getObject().get("dwc:month") >
				<cfset r.value = dqResponse.getValue().getObject().toString() >
			<cfelse>
				<cfset r.value = "">
			</cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset amendment["2e371d57-1eb3-4fe3-8a61-dff43ced50cf"] = r >
			<cfset r=structNew()>

			<!--- @Provides("6d0a0c10-5e4a-4759-b448-88932f399812") --->
			<cfset dqResponse = dwcEventDQ.amendmentEventdateFromVerbatim(eventDate, verbatimEventDate) >
			<cfset r.label = "fill in dwc:eventDate from dwc:verbatimEventDate " >
			<cfset r.type = "AMENDMENT" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status EQ "FILLED_IN">
				<cfset eventDate = dqResponse.getValue().getObject().get("dwc:eventDate") >
				<cfset r.value = dqResponse.getValue().getObject().toString() >
			<cfelse>
				<cfset r.value = "">
			</cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset amendment["6d0a0c10-5e4a-4759-b448-88932f399812"] = r >
			<cfset r=structNew()>

			<!---  @Provides("eb0a44fa-241c-4d64-98df-ad4aa837307b") --->
			<cfset dqResponse = dwcEventDQ.amendmentEventdateFromYearstartdayofyearenddayofyear(eventDate, year, startDayOfYear, endDayOfYear) >
			<cfset r.label = "fill in dwc:eventDate from dwc:year, dwc:startDayOfYear and dwc:endDayOfYear" >
			<cfset r.type = "AMENDMENT" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "AMENDED">
				<cfset eventDate = dqResponse.getValue().getObject().get("dwc:eventDate") >
				<cfset r.value = dqResponse.getValue().getObject().toString() >
			<cfelse>
				<cfset r.value = "">
			</cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset amendment["eb0a44fa-241c-4d64-98df-ad4aa837307b"] = r >
			<cfset r=structNew()>

			<!--- @Provides("3892f432-ddd0-4a0a-b713-f2e2ecbd879d") --->
			<cfset dqResponse = dwcEventDQ.amendmentEventdateFromYearmonthday(eventDate, year, month, day) >
			<cfset r.label = "fill in dwc:eventDate from dwc:year, dwc:month, and dwc:day " >
			<cfset r.type = "AMENDMENT" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status EQ "FILLED_IN">
				<cfset eventDate = dqResponse.getValue().getObject().get("dwc:eventDate") >
				<cfset r.value = dqResponse.getValue().getObject().toString() >
			<cfelse>
				<cfset r.value = "">
			</cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset amendment["3892f432-ddd0-4a0a-b713-f2e2ecbd879d"] = r >
			<cfset r=structNew()>

			<!--- @Provides("718dfc3c-cb52-4fca-b8e2-0e722f375da7") --->
			<cfset dqResponse = dwcEventDQ.amendmentEventdateStandardized(eventDate) >
			<cfset r.label = "standardize dwc:eventDate " >
			<cfset r.type = "AMENDMENT" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "AMENDED">
				<cfset eventDate = dqResponse.getValue().getObject().get("dwc:eventDate") >
				<cfset r.value = dqResponse.getValue().getObject().toString() >
			<cfelse>
				<cfset r.value = "">
			</cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset amendment["718dfc3c-cb52-4fca-b8e2-0e722f375da7"] = r >
			<cfset r=structNew()>

			<!--- @Provides("710fe118-17e1-440f-b428-88ba3f547d6d") --->
			<cfset dqResponse = dwcEventDQ.amendmentEventFromEventdate(eventDate, year,month,day, startDayOfYear, endDayOfYear) >
			<cfset r.label = "fill in other Event terms from dwc:eventDate" >
			<cfset r.type = "AMENDMENT" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status EQ "FILLED_IN">
				<!--- conditionally change terms for which values are proposed --->
				<cfif dqResponse.getValue().getObject().get("dwc:month") NEQ '' ><cfset month = dqResponse.getValue().getObject().get("dwc:month") ></cfif>
				<cfif dqResponse.getValue().getObject().get("dwc:day") NEQ '' ><cfset day = dqResponse.getValue().getObject().get("dwc:day") ></cfif>
				<cfif dqResponse.getValue().getObject().get("dwc:year") NEQ '' ><cfset year = dqResponse.getValue().getObject().get("dwc:year") ></cfif>
				<cfif dqResponse.getValue().getObject().get("dwc:startDayOfYear") NEQ '' ><cfset startDayOfYear = dqResponse.getValue().getObject().get("dwc:startDayOfYear") ></cfif>
				<cfif dqResponse.getValue().getObject().get("dwc:endDayOfYear") NEQ '' ><cfset endDayOfYear = dqResponse.getValue().getObject().get("dwc:endDayOfYear") ></cfif>
				<cfset r.value = dqResponse.getValue().getObject().toString() >
			<cfelse>
				<cfset r.value = "">
			</cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset amendment["710fe118-17e1-440f-b428-88ba3f547d6d"] = r >
			<cfset r=structNew()>


			<!--- post-amendment phase --->

			<!--- @Provides("56b6c695-adf1-418e-95d2-da04cad7be53") --->
			<cfset dqResponse = dwcEventDQ.measureEventdateDurationinseconds(eventDate) >
			<cfset r.label = "dwc:eventDate precision in seconds" >
			<cfset r.type = "MEASURE" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT">
				<cfset r.value = dqResponse.getValue().getObject() >
				<cfset days = Round(r.value / 60 / 60 / 24)>
				<cfif days EQ 1><cfset s=""><cfelse><cfset s="s"></cfif>
				<cfset r.comment = dqResponse.getComment() & " (" & days & " day" & s &")" >
			<cfelse>
				<cfset r.value = "">
				<cfset r.comment = dqResponse.getComment()  >
			</cfif>
			<cfset postamendment["56b6c695-adf1-418e-95d2-da04cad7be53"] = r >
			<cfset r=structNew()>

			<!--- @Provides("66269bdd-9271-4e76-b25c-7ab81eebe1d8") --->
			<cfset dqResponse = dwcOtherDateQC.validationDateidentifiedStandard(dateIdentified) >
			<cfset r.label = "dwc:dateIdentified in standard format" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["66269bdd-9271-4e76-b25c-7ab81eebe1d8"] = r >
			<cfset r=structNew()>

			<!--- @Provides("dc8aae4b-134f-4d75-8a71-c4186239178e") --->
			<cfset dqResponse = dwcOtherDateQCDefaults.validationDateidentifiedInrange(dateIdentified, eventDate)>
			<cfset r.label = "dwc:dateIdentified in range" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["dc8aae4b-134f-4d75-8a71-c4186239178e"] = r >
			<cfset r=structNew()>

			<!---  @Provides("47ff73ba-0028-4f79-9ce1-ee7008d66498") --->
			<cfset dqResponse =  dwcEventDQ.validationDayStandard(day) >
			<cfset r.label = "dwc:day in standard format" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["47ff73ba-0028-4f79-9ce1-ee7008d66498"] = r >
			<cfset r=structNew()>

			<!--- @Provides("5618f083-d55a-4ac2-92b5-b9fb227b832f") --->
			<cfset dqResponse = dwcEventDQ.validationDayInrange(year, month, day) >
			<cfset r.label = "dwc:day in range for month and year" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["5618f083-d55a-4ac2-92b5-b9fb227b832f"] = r >
			<cfset r=structNew()>

			<!---  @Provides("9a39d88c-7eee-46df-b32a-c109f9f81fb8") --->
			<cfset dqResponse =dwcEventDQ.validationEnddayofyearInrange(endDayOfYear, eventDate) >
			<cfset r.label = "dwc:endDayOfYear in range for year" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["9a39d88c-7eee-46df-b32a-c109f9f81fb8"] = r >
			<cfset r=structNew()>

			<!---  @Provides("41267642-60ff-4116-90eb-499fee2cd83f") --->
			<cfset dqResponse = dwcEventDQ.validationEventTemporalNotEmpty(eventDate,verbatimEventDate,year,month,day,startDayOfYear, endDayOfYear) >
			<cfset r.label = "dwc:Event terms contain some value" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["41267642-60ff-4116-90eb-499fee2cd83f"] = r >
			<cfset r=structNew()>

			<!--- @Provides("5618f083-d55a-4ac2-92b5-b9fb227b832f")  --->
			<cfset dqResponse = dwcEventDQ.validationEventConsistent(eventDate,year,month,day,startDayOfYear, endDayOfYear) >
			<cfset r.label = "dwc:Event terms are consistent" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["5618f083-d55a-4ac2-92b5-b9fb227b832f"] = r >
			<cfset r=structNew()>

			<!--- @Provides("f51e15a6-a67d-4729-9c28-3766299d2985") --->
			<cfset dqResponse = dwcEventDQ.validationEventdateNotEmpty(eventDate) >
			<cfset r.label = "dwc:eventDate contains a value" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["f51e15a6-a67d-4729-9c28-3766299d2985"] = r >
			<cfset r=structNew()>

			<!---  @Provides("4f2bf8fd-fc5c-493f-a44c-e7b16153c803") --->
			<cfset dqResponse = dwcEventDQ.validationEventdateStandard(eventDate) >
			<cfset r.label = "dwc:eventDate is in standard form" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["4f2bf8fd-fc5c-493f-a44c-e7b16153c803"] = r >
			<cfset r=structNew()>

			<!--- @Provides("3cff4dc4-72e9-4abe-9bf3-8a30f1618432") --->
			<cfset dqResponse = dwcEventDQDefaults.validationEventdateInrange(eventDate) >
			<cfset r.label = "dwc:eventDate is in range" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["3cff4dc4-72e9-4abe-9bf3-8a30f1618432"] = r >
			<cfset r=structNew()>

			<!--- @Provides("01c6dafa-0886-4b7e-9881-2c3018c98bdc") --->
			<cfset dqResponse = dwcEventDQ.validationMonthStandard(month) >
			<cfset r.label = "dwc:month is in standard form" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["01c6dafa-0886-4b7e-9881-2c3018c98bdc"] = r >
			<cfset r=structNew()>

			<!--- @Provides("85803c7e-2a5a-42e1-b8d3-299a44cafc46") --->
			<cfset dqResponse = dwcEventDQ.validationStartdayofyearInrange(startDayOfYear,eventDate) >
			<cfset r.label = "dwc:startDayOfYear is in range for year" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["85803c7e-2a5a-42e1-b8d3-299a44cafc46"] = r >
			<cfset r=structNew()>

			<!--- @Provides("c09ecbf9-34e3-4f3e-b74a-8796af15e59f") --->
			<cfset dqResponse = dwcEventDQ.validationYearNotEmpty(year) >
			<cfset r.label = "dwc:Year contains a value" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["c09ecbf9-34e3-4f3e-b74a-8796af15e59f"] = r >
			<cfset r=structNew()>

			<!--- @Provides("ad0c8855-de69-4843-a80c-a5387d20fbc8") --->
			<cfset dqResponse = dwcEventDQDefaults.validationYearInrange(year) >
			<cfset r.label = "dwc:Year is in range" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["ad0c8855-de69-4843-a80c-a5387d20fbc8"] = r >
			<cfset r=structNew()>

			<cfset r=structNew()>

			<!--- Add results from phases to result to return --->

			<cfset result["PREAMENDMENT"] = preamendment >

			<cfset result["AMENDMENT"] = amendment >

			<cfset result["POSTAMENDMENT"] = postamendment >

		<cfelse>
			<cfset result.STATUS="fail">
			<cfset result.TARGET_ID=target_id>
			<cfset result.ERROR="record not found">
		</cfif>
    <cfcatch>
			<cfset result.STATUS="fail">
			<cfset result.TARGET_ID=target_id>
			<cfset line = cfcatch.tagcontext[1].line>
			<cfset result.ERROR=cfcatch.message & '; ' & cfcatch.detail & ' [line:' & line & ']' >
    </cfcatch>
	</cftry>
    <cfreturn serializeJSON(result) >
</cffunction>

</cfcomponent>
