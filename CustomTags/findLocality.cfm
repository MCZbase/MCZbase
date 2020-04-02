<!--- custom tag cf_findLocality  returns query object localityResults --->
<cfinclude template="/includes/functionLib.cfm">
<cfset linguisticFlag = false>
<cfif isdefined("accentInsensitive") AND accentInsensitive EQ 1>
	<cfset linguisticFlag=true>
</cfif>
<cfset includeCounts = false>
<cfif isdefined("include_counts") AND include_counts EQ 1 >
	<cfset includeCounts=true>
</cfif>
<cfif isdefined("collection_id") and len(collection_id) gt 0>
	<cfif not isdefined("collnOper") or len(collnOper) is 0>
		<cfset collnOper="usedOnlyBy">
	</cfif>
</cfif>
<cfif not isdefined("begDateOper")>
	<cfset begDateOper="=">
</cfif>
<cfif not isdefined("endDateOper")>
	<cfset endDateOper="=">
</cfif>
<cfif not isdefined("maxElevOper")>
	<cfset maxElevOper="=">
</cfif>
<cfif not isdefined("minElevOper")>
	<cfset minElevOper="=">
</cfif>
<cfif not isdefined("maxDepthOper")>
	<cfset maxDepthOper="=">
</cfif>
<cfif not isdefined("minDepthOper")>
	<cfset minDepthOper="=">
</cfif>
<cfif not isdefined("gs_comparator")>
	<cfset minDepthOper="=">
</cfif>
<cfoutput>
<cftransaction>
	<cfif linguisticFlag >
		<!--- Set up the session to run an accent insensitive search --->
		<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			ALTER SESSION SET NLS_COMP = LINGUISTIC
		</cfquery>
		<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			ALTER SESSION SET NLS_SORT = GENERIC_M_AI
		</cfquery>
	</cfif>
	<!--- run the query --->
	<cfquery name="caller.localityResults" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select 
			<cfif (isdefined("geology_attribute") AND len(#geology_attribute#) gt 0) OR (isdefined("geo_att_value") AND len(#geo_att_value#) gt 0)>
				distinct
			</cfif>
			geog_auth_rec.geog_auth_rec_id,
			locality.locality_id,
			collecting_event.collecting_event_id,
			higher_geog,
			spec_locality,
			sovereign_nation,
			began_date,
			ended_date,
			verbatim_date,
			verbatim_locality,
			collecting_source,
			collecting_method,
			CASE orig_lat_long_units
				WHEN 'decimal degrees' THEN dec_lat || 'd'
				WHEN 'deg. min. sec.' THEN lat_deg || 'd ' || lat_min || 'm ' || lat_sec || 's ' || lat_dir
				WHEN 'degrees dec. minutes' THEN lat_deg || 'd ' || dec_lat_min || 'm ' || lat_dir
			END LatitudeString,
			CASE orig_lat_long_units
				WHEN 'decimal degrees' THEN dec_long || 'd'
				WHEN'degrees dec. minutes' THEN long_deg || 'd ' || dec_long_min || 'm ' || long_dir
				WHEN 'deg. min. sec.' THEN long_deg || 'd ' || long_min || 'm ' || long_sec || 's ' || long_dir
			END LongitudeString,
			nogeorefbecause,
			max_error_distance,
			max_error_units,
			lat_long_ref_source,
			determined_date,
			minimum_elevation,
			maximum_elevation,
			orig_elev_units,
			coordDet.agent_name coordinateDeterminer,
			concatGeologyAttributeDetail(locality.locality_id) geolAtts,
			max_depth,
			min_depth,
			depth_units,
			<cfif includeCounts >
				MCZBASE.get_collcodes_for_locality(locality.locality_id)  as collcountlocality
			<cfelse>
				null as collcountlocality
			</cfif>
		from
			geog_auth_rec 
				left join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id
				left join accepted_lat_long on locality.locality_id = accepted_lat_long.locality_id 
				left join preferred_agent_name coordDet on accepted_lat_long.determined_by_agent_id = coordDet.agent_id
				left join collecting_event on locality.locality_id=collecting_event.locality_id
				<cfif (isdefined("geology_attribute") AND len(#geology_attribute#) gt 0) OR (isdefined("geo_att_value") AND len(#geo_att_value#) gt 0)>
					left join geology_attributes on locality.locality_id = geology_attributes.locality_id 
				</cfif>
		where
			geog_auth_rec.geog_auth_rec_id > -1
			<cfif isdefined("locality_id") and len(#locality_id#) gt 0>
				AND locality.locality_id = <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#locality_id#">
			</cfif>
			<cfif isdefined("geog_auth_rec_id") and len(#geog_auth_rec_id#) gt 0>
				AND geog_auth_rec.geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#geog_auth_rec_id#">
			</cfif>
			<cfif isdefined("collecting_event_id") and len(#collecting_event_id#) gt 0>
				AND collecting_event.collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#collecting_event_id#">
			</cfif>
			<cfif isdefined("collection_id") and len(collection_id) gt 0>
				<cfif collnOper is "usedOnlyBy">
					AND locality.locality_id in 
							(select locality_id from vpd_collection_locality where collection_id =  <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#collection_id#"> ) 
					AND locality.locality_id not in 
							(select locality_id from vpd_collection_locality where collection_id <>  <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#collection_id#"> )
				<cfelseif collnOper is "usedBy">
					AND locality.locality_id in 
						(select locality_id from vpd_collection_locality where collection_id =  <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#collection_id#"> )
				<cfelseif collnOper is "notUsedBy">
					AND locality.locality_id  not in
						(select locality_id from vpd_collection_locality where collection_id =  <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#collection_id#"> )
				</cfif>
			</cfif>
			<cfif isdefined("geology_attribute") and len(#geology_attribute#) gt 0>
				AND geology_attributes.geology_attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geology_attribute#">
			</cfif>
			<cfif isdefined("geo_att_value") and len(#geo_att_value#) gt 0>
				<cfif isdefined("geology_attribute_hier") and #geology_attribute_hier# is 1>
					AND geology_attributes.geo_att_value 
						IN ( SELECT attribute_value
	 						FROM geology_attribute_hierarchy
							START WITH upper(attribute_value) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(geo_att_value)#%">
							CONNECT BY PRIOR geology_attribute_hierarchy_id = parent_id )
				<cfelse>
					AND upper(geology_attributes.geo_att_value) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(geo_att_value)#%">
				</cfif>
			</cfif>
			<cfif isdefined("began_date") and len(#began_date#) gt 0>
				<cfswitch expression="#begDateOper#">
					<cfcase value = ">">
						AND began_date > <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#began_date#">
					</cfcase>
					<cfcase value = "<">
						AND began_date < <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#began_date#">
					</cfcase>
					<cfdefaultcase>
						AND began_date = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#began_date#">
					</cfdefaultcase>
				</cfswitch>
			</cfif>
			<cfif isdefined("ended_date") and len(#ended_date#) gt 0>
				<cfswitch expression="#endDateOper#">
					<cfcase value = ">">
						AND ended_date > <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ended_date#">
					</cfcase>
					<cfcase value = "<">
						AND ended_date < <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ended_date#">
					</cfcase>
					<cfdefaultcase>
						AND ended_date = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ended_date#">
					</cfdefaultcase>
				</cfswitch>
			</cfif>
			<cfif isdefined("verbatim_date") and len(#verbatim_date#) gt 0>
				AND upper(verbatim_date) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(verbatim_date)#%">
			</cfif>
			<cfif isdefined("sovereign_nation") and len(#sovereign_nation#) gt 0>
				<cfif left(sovereign_nation,1) is "!">
					AND upper(sovereign_nation) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(sovereign_nation,len(sovereign_nation)-1))#">
				<cfelse>
					AND upper(sovereign_nation) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(sovereign_nation)#">
				</cfif>
			</cfif>
			<cfif isdefined("verbatim_locality") and len(#verbatim_locality#) gt 0>
				AND upper(verbatim_locality) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(verbatim_locality)#%">
			</cfif>
			<cfif isdefined("coll_event_remarks") and len(#coll_event_remarks#) gt 0>
				AND upper(coll_event_remarks) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(coll_event_remarks)#%">
			</cfif>
			<cfif isdefined("collecting_source") and len(#collecting_source#) gt 0>
				AND upper(collecting_source) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(collecting_source)#%">
			</cfif>
			<cfif isdefined("collecting_method") and len(#collecting_method#) gt 0>
				AND upper(collecting_method) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(collecting_method)#%">
			</cfif>
			<cfif isdefined("habitat_desc") and len(#habitat_desc#) gt 0>
				AND upper(habitat_desc) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(habitat_desc)#%">
			</cfif>
			<cfif isdefined("spec_locality") and len(#spec_locality#) gt 0>
				AND upper(spec_locality) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(spec_locality)#%">
			</cfif>
			<cfif isdefined("locality_remarks") and len(#locality_remarks#) gt 0>
				AND upper(locality_remarks) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(locality_remarks)#%">
			</cfif>
			<cfif isdefined("maximum_elevation") and len(#maximum_elevation#) gt 0>
				<cfswitch expression="#maxElevOper#">
					<cfcase value = ">">
						AND maximum_elevation > <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#maximum_elevation#">
					</cfcase>
					<cfcase value = "<">
						AND maximum_elevation < <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#maximum_elevation#">
					</cfcase>
					<cfcase value = "<>">
						AND maximum_elevation <> <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#maximum_elevation#">
					</cfcase>
					<cfdefaultcase>
						AND maximum_elevation = <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#maximum_elevation#">
					</cfdefaultcase>
				</cfswitch>
			</cfif>
			<cfif isdefined("minimum_elevation") and len(#minimum_elevation#) gt 0>
				<cfswitch expression="#minElevOper#">
					<cfcase value = ">">
						AND minimum_elevation > <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#minimum_elevation#">
					</cfcase>
					<cfcase value = "<">
						AND minimum_elevation < <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#minimum_elevation#">
					</cfcase>
					<cfcase value = "<>">
						AND minimum_elevation <> <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#minimum_elevation#">
					</cfcase>
					<cfdefaultcase>
						AND minimum_elevation = <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#minimum_elevation#">
					</cfdefaultcase>
				</cfswitch>
			</cfif>
			<cfif isdefined("orig_elev_units") and len(#orig_elev_units#) gt 0>
				AND orig_elev_units = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#orig_elev_units#">
			</cfif>
			<cfif isdefined("max_depth") and len(#max_depth#) gt 0>
				<cfswitch expression="#maxDepthOper#">
					<cfcase value = ">">
						AND max_depth > <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#max_depth#">
					</cfcase>
					<cfcase value = "<">
						AND max_depth < <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#max_depth#">
					</cfcase>
					<cfcase value = "<>">
						AND max_depth <> <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#max_depth#">
					</cfcase>
					<cfdefaultcase>
						AND max_depth = <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#max_depth#">
					</cfdefaultcase>
				</cfswitch>
			</cfif>
			<cfif isdefined("min_depth") and len(#min_depth#) gt 0>
				<cfswitch expression="#minDepthOper#">
					<cfcase value = ">">
						AND min_depth > <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#min_depth#">
					</cfcase>
					<cfcase value = "<">
						AND min_depth < <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#min_depth#">
					</cfcase>
					<cfcase value = "<>">
						AND min_depth <> <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#min_depth#">
					</cfcase>
					<cfdefaultcase>
						AND min_depth = <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#min_depth#">
					</cfdefaultcase>
				</cfswitch>
			</cfif>
			<cfif isdefined("depth_units") and len(#orig_elev_units#) gt 0>
				AND depth_units = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#depth_units#">
			</cfif>
			<cfif isdefined("higher_geog") and len(#higher_geog#) gt 0>
				<cfif left(higher_geog,1) is "=">
					AND upper(higher_geog) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#(ucase(right(higher_geog,len(higher_geog)-1)))#">
				<cfelse>
					AND upper(higher_geog) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#(ucase(higher_geog))#%">
				</cfif>
			</cfif>
			<cfif isdefined("continent_ocean") and len(#continent_ocean#) gt 0>
				<cfif left(#continent_ocean#,1) is "=">
					AND upper(continent_ocean) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(continent_ocean,len(continent_ocean)-1))#">
				<cfelseif left(#continent_ocean#,1) is "!">
					AND upper(continent_ocean) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(continent_ocean,len(continent_ocean)-1))#">
				<cfelseif #continent_ocean# eq 'NULL'>
					AND continent_ocean is NULL 
				<cfelse>
					AND upper(continent_ocean) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(continent_ocean)#%">
				</cfif>
			</cfif>
			<cfif isdefined("country") and len(#country#) gt 0>
				<cfif left(country,1) is "=">
					AND upper(country) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(country,len(country)-1))#">
				<cfelseif left(country,1) is "!">
					AND upper(country) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(country,len(country)-1))#">
				<cfelseif country eq 'NULL'>
					AND country is NULL
				<cfelse>
					AND upper(country) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(country)#%">
				</cfif>
			</cfif>
			<cfif isdefined("state_prov") and len(#state_prov#) gt 0>
				AND upper(state_prov) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(state_prov)#%">
			</cfif>
			<cfif isdefined("county") and len(#county#) gt 0>
				AND upper(county) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(county)#%">
			</cfif>
			<cfif isdefined("quad") and len(#quad#) gt 0>
				AND upper(quad) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(quad)#%">
			</cfif>
			<cfif isdefined("feature") and len(#feature#) gt 0>
				AND feature = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#feature#">
			</cfif>
			<cfif isdefined("ocean_region") and len(#ocean_region#) gt 0>
				AND upper(ocean_region) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(ocean_region)#%">
			</cfif>
			<cfif isdefined("ocean_subregion") and len(#ocean_subregion#) gt 0>
				AND upper(ocean_subregion) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(ocean_subregion)#%">
			</cfif>
			<cfif isdefined("sea") and len(#sea#) gt 0>
				AND upper(sea) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(sea)#%">
			</cfif>
			<cfif isdefined("water_feature") and len(#water_feature#) gt 0>
				AND water_feature = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#water_feature#">
			</cfif>
			<cfif isdefined("island_group") and len(#island_group#) gt 0>
				AND island_group = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#island_group#">
			</cfif>
			<cfif isdefined("island") and len(#island#) gt 0>
				AND upper(island) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(island)#%">
			</cfif>
			<cfif isdefined("NoGeorefBecause") AND len(#NoGeorefBecause#) gt 0>
				AND upper(NoGeorefBecause) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(NoGeorefBecause)#%">
			</cfif>
			<cfif isdefined("VerificationStatus") AND len(#VerificationStatus#) gt 0>
				AND VerificationStatus = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VerificationStatus#">
			</cfif>
			<cfif isdefined("GeorefMethod") AND len(#GeorefMethod#) gt 0>
				AND GeorefMethod = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#GeorefMethod#">
			</cfif>
			<cfif isdefined("nullNoGeorefBecause") and len(#nullNoGeorefBecause#) gt 0>
				AND NoGeorefBecause IS NULL
			</cfif>
			<cfif isdefined("isIncomplete") AND len(#isIncomplete#) gt 0>
				AND ( GPSACCURACY IS NULL OR EXTENT IS NULL OR MAX_ERROR_DISTANCE = 0 or MAX_ERROR_DISTANCE IS NULL
			</cfif>
			<cfif isdefined("findNoAccGeoRef") and len(#findNoAccGeoRef#) gt 0>
				AND locality.locality_id IN (select locality_id from lat_long) 
				AND locality.locality_id NOT IN (select locality_id from lat_long where accepted_lat_long_fg=1)
			</cfif>
			<cfif isdefined("findNoGeoRef") and len(#findNoGeoRef#) gt 0>
				AND locality.locality_id NOT IN (select locality_id from lat_long)
			</cfif>
			<cfif isdefined("coordinateDeterminer") and len(#coordinateDeterminer#) gt 0>
				AND upper(agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(coordinateDeterminer)#%">
			</cfif>
			<cfif isdefined("geolocate_precision") and len(#geolocate_precision#) gt 0>
				AND lower(accepted_lat_long.geolocate_precision) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geolocate_precision#">
			</cfif>
			<cfif isdefined("geolocate_score") and len(#geolocate_score#) gt 0>
				<cfswitch expression="#gs_comparator#">
					<cfcase value = "between">
						AND accepted_lat_long.geolocate_score 
							BETWEEN <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#geolocate_score#"> 
							AND <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#geolocate_score2#">
					</cfcase>
					<cfcase value = ">">
						AND accepted_lat_long.geolocate_score > <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#geolocate_score#">
					</cfcase>
					<cfcase value = "<">
						AND accepted_lat_long.geolocate_score < <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#geolocate_score#">
					</cfcase>
					<cfcase value = "<>">
						AND accepted_lat_long.geolocate_score <> <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#geolocate_score#">
					</cfcase>
					<cfdefaultcase>
						AND accepted_lat_long.geolocate_score = <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#geolocate_score#">
					</cfdefaultcase>
				</cfswitch>
			</cfif>
			<cfif isdefined("onlyShared") and len(#onlyShared#) gt 0>
				AND locality.locality_id in (select locality_id from VPD_COLLECTION_LOCALITY group by locality_id having count(*) > 1)
			</cfif>

	</cfquery>
	<cfif linguisticFlag >
		<!--- Reset NLS_COMP back to the default, or the session will keep using the generic_m_ai comparison/sort on subsequent searches. --->
		<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			ALTER SESSION SET NLS_COMP = BINARY
		</cfquery>
	</cfif>
</cftransaction>
<cfif caller.localityResults.recordcount is 0>
	<span class="error">Your search found no matches.</span>
	<cfabort>
</cfif>
</cfoutput>
