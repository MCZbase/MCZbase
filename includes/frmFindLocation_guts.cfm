<script language="javascript" type="text/javascript">
	function nada(){}
	function toggleGeogDetail(onOff) {
		if (onOff==0) {
			$("#geogDetail").hide();
			$("#geogDetailCtl").attr('onCLick','toggleGeogDetail(1)').html('Show More Options');
		} else {
			$("#geogDetail").show();
			$("#geogDetailCtl").attr('onCLick','toggleGeogDetail(0)').html('Show Fewer Options');
		}
		jQuery.getJSON("/component/functions.cfc",
			{
				method : "saveLocSrchPref",
				id : 'GeogDetail',
				onOff : onOff,
				returnformat : "json",
				queryformat : 'column'
			},
			nada
		);
	}
	function toggleLocDetail(onOff) {
		if (onOff==0) {
			$("#locDetail").hide();
			$("#locDetailCtl").attr('onCLick','toggleLocDetail(1)').html('Show More Options');
		} else {
			$("#locDetail").show();
			$("#locDetailCtl").attr('onCLick','toggleLocDetail(0)').html('Show Fewer Options');
		}
		jQuery.getJSON("/component/functions.cfc",
			{
				method : "saveLocSrchPref",
				id : 'LocDetail',
				onOff : onOff,
				returnformat : "json",
				queryformat : 'column'
			},
			nada
		);
	}
	function toggleGeorefDetail(onOff) {
		if (onOff==0) {
			$("#georefDetail").hide();
			$("#georefDetailCtl").attr('onCLick','toggleGeorefDetail(1)').html('Show More Options');
		} else {
			$("#georefDetail").show();
			$("#georefDetailCtl").attr('onCLick','toggleGeorefDetail(0)').html('Show Fewer Options');
		}
		jQuery.getJSON("/component/functions.cfc",
			{
				method : "saveLocSrchPref",
				id : 'GeorefDetail',
				onOff : onOff,
				returnformat : "json",
				queryformat : 'column'
			},
			nada
		);
	}
	function toggleEventDetail(onOff) {
		if (onOff==0) {
			$("#eventDetail").hide();
			$("#eventDetailCtl").attr('onCLick','toggleEventDetail(1)').html('Show More Options');
		} else {
			$("#eventDetail").show();
			$("#eventDetailCtl").attr('onCLick','toggleEventDetail(0)').html('Show Fewer Options');
		}
		jQuery.getJSON("/component/functions.cfc",
			{
				method : "saveLocSrchPref",
				id : 'EventDetail',
				onOff : onOff,
				returnformat : "json",
				queryformat : 'column'
			},
			nada
		);
	}

	 function show(aval) {
    if (aval == "between") {
    hiddenDiv.style.display='inline-block';
	hiddenDivlabel.style.display='inline-block';
    Form.fileURL.focus();
    }
    else{
    hiddenDiv.style.display='none';
			hiddenDivlabel.style.display='none';
    }
  }
</script>
<cfoutput>
<cfif not isdefined("showLocality")>
	<cfset showLocality=0>
</cfif>
<cfif not isdefined("showEvent")>
	<cfset showEvent=0>
</cfif>
<cfif not isdefined("showSpecimenCounts")><!--- show or hide the specimen counts control, show by default if locality section is included --->
	<cfset showSpecimenCounts = true>
</cfif>
<cfquery name="ctElevUnit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
	select orig_elev_units from ctorig_elev_units order by orig_elev_units
</cfquery>
<cfquery name="ctDepthUnit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
        select depth_units from ctdepth_units order by depth_units
</cfquery>
<cfquery name="ctFeature" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
	select distinct(feature) from ctfeature order by feature
</cfquery>
<cfquery name="ctWater_Feature" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
	select distinct(water_feature) from ctwater_feature order by water_feature
</cfquery>
<cfquery name="ctIslandGroup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
	select island_group from ctisland_group order by island_group
</cfquery>
<cfquery name="ctCollectingSource" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
	select collecting_source from ctcollecting_source order by collecting_source
</cfquery>
<cfquery name="ctVerificationStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
	select VerificationStatus from ctVerificationStatus order by VerificationStatus
</cfquery>
<cfquery name="ctGeorefMethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
	select georefMethod from ctgeorefmethod order by georefMethod
</cfquery>
<cfquery name="ctgeology_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
	select geology_attribute from ctgeology_attribute order by ordinal
</cfquery>
<cfquery name="ctsovereign_nation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
	select ctsovereign_nation.sovereign_nation, count(locality_id) as ct from ctsovereign_nation
 		left join locality on ctsovereign_nation.sovereign_nation=locality.sovereign_nation
	group by ctsovereign_nation.sovereign_nation
        order by sovereign_nation
</cfquery>
<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
	select collection,collection_id from collection order by collection
</cfquery>

<table>
    <tr><td>
        <span id="_generic_m_ai">Accent&nbsp;Insensitive?</span><input type="checkbox" name="accentInsensitive" id="accentInsensitive" value="1">
    </td></tr>
    <tr><td>
	<div class="locGroup">
		<span id="geogDetailCtl" class="infoLink" onclick="toggleGeogDetail(1)";>Show More Options</span>
		<table>
		<tr>
			<td>
				<label for="higher_geog">Higher Geog</label>
				<input type="text" name="higher_geog" id="higher_geog" size="75">
				<span class="infolink" onclick="var e=document.getElementById('higher_geog');e.value='='+e.value;">
									Add = for exact match
				</span>
			</td>
		</tr>
	</table>
		<div id="geogDetail" class="noShow">
		<table>
			<tr>
				<td>
					<label for="continent_ocean">Continent or Ocean</label>
					<input type="text" name="continent_ocean" id="continent_ocean" size="50">
				        <span class="infolink" onclick="var e=document.getElementById('continent_ocean');e.value='='+e.value;">
									Add = for exact match
				        </span>
				</td>
				<td style="padding-left: 1em;">
					<label for="ocean_region">Ocean Region</label>
					<input type="text" name="ocean_region" id="ocean_region" size="50">
				</td>
			</tr>
			<tr>
			<td>
				<label for="ocean_subregion">Ocean SubRegion</label>
				<input type="text" name="ocean_subregion" id="ocean_subregion" size="50">
			</td>
			<td style="padding-left: 1em;">
				<label for="sea">Sea</label>
				<input type="text" name="sea" id="sea" size="50">
			</td>
			</tr>
			<tr>
			<td>
				<label for="island">Island</label>
						<input type="text" name="island" id="island" size="50">
			</td>
			<td style="padding-left: 1em;">
				<label for="island_group">Island Group</label>
					<select name="island_group" id="island_group">
						<option value=""></option>
						<cfloop query="ctIslandGroup">
							<option value = "#ctIslandGroup.island_group#">#ctIslandGroup.island_group#</option>
						</cfloop>
					</select>
			</td>
			</tr>
			<tr>
			<td>
				<label for="feature">Land Feature</label>
				<select name="feature" id="feature">
					<option value=""></option>
					<cfloop query="ctFeature">
						<option value = "#ctFeature.feature#">#ctFeature.feature#</option>
					</cfloop>
				</select>
			</td>
			<td style="padding-left: 1em;">
					<label for="water_feature">Water Feature</label>
						<select name="water_feature" id="water_feature">
							<option value=""></option>
								<cfloop query="ctWater_Feature">
								<option value = "#ctWater_Feature.water_feature#">#ctWater_Feature.water_feature#</option>
								</cfloop>
						</select>
			</td>
			</tr>
			<tr>
				<td>
					<label for="country">Country</label>
					<input type="text" name="country" id="country" size="50">
				        <span class="infolink" onclick="var e=document.getElementById('country');e.value='='+e.value;">
									Add = for exact match
				        </span>
				</td>
				<td style="padding-left: 1em;">
					<label for="state_prov">State or Province</label>
					<input type="text" name="state_prov" id="state_prov" size="50">
				</td>
			</tr>
			<tr>
				<td>
					<label for="county">County</label>
					<input type="text" name="county" id="county" size="50">
				</td>
				<td style="padding-left: 1em;">
					<label for="quad">Quad</label>
					<input type="text" name="quad" id="quad" size="50">
				</td>
				</tr>
				<tr>
				<td>&nbsp;</td>
        <td style="padding-left: 1em;">
					<label for="geog_auth_rec_id">Geog Auth Rec ID</label>
					<input type="text" name="geog_auth_rec_id" id="geog_auth_rec_id">
				</td>
			</tr>
		</table>
		</div>

</div>

<cfif #showLocality# is 1>
	<div class="locGroup">
		<span id="locDetailCtl" class="infoLink" onclick="toggleLocDetail(1)";>Show More Options</span>
	<table>
		<tr>
			<td colspan="2">
				<label for="spec_locality">Specific Locality</label>
				<input type="text" name="spec_locality" id="spec_locality" size="75">
			</td>
		</tr>
		</table>
		<div id="locDetail" class="noShow">
		<table>
			<tr>
				<td>
					<label for="collnOper">Collection</label>
					<select name="collnOper" id="collnOper" size="1">
						<option value=""></option>
						<option value="usedOnlyBy">used only by</option>
						<option value="usedBy">used by</option>
						<option value="notUsedBy">not used by</option>
					</select>
					<select name="collection_id" id="collection_id" size="1">
						<option value=""></option>
						<cfloop query="ctcollection">
							<option value="#ctcollection.collection_id#">#ctcollection.collection#</option>
						</cfloop>
					</select>
				</td>
				<td>
					<label for="locality_id">Locality ID</label>
					<input type="text" name="locality_id" id="locality_id">
				</td>
			</tr>
			<tr>
				<td>
					<label for="MinElevOper">Minimum Elevation (only with units below)</label>
					<select name="MinElevOper" id="MinElevOper" size="1">
						<option value="=">is</option>
						<option value="<>">is not</option>
						<option value=">">more than</option>
						<option value="<">less than</option>
					</select>
					<input type="text" name="minimum_elevation" id="minimum_elevation">
				</td>
				<td>
					<label for="minDepthOper">Minimum Depth (only with units below)</label>
					<select name="minDepthOper" id="MinDepthOper" size="1">
						<option value="=">is</option>
						<option value="<>">is not</option>
						<option value=">">more than</option>
						<option value="<">less than</option>
					</select>
					<input type="text" name="min_depth" id="min_depth">
				</td>
			</tr>
			<tr>
				<td>
					<label for="MaxElevOper">Maximum Elevation (only with units below)</label>
					<select name="MaxElevOper" id="MaxElevOper" size="1">
						<option value="=">is</option>
						<option value="<>">is not</option>
						<option value=">">more than</option>
						<option value="<">less than</option>
					</select>
					<input type="text" name="maximum_elevation" id="maximum_elevation">
				</td>
				<td>
					<label for="MaxDepthOper">Maximum Depth (only with units below)</label>
					<select name="MaxDepthOper" id="MaxDepthOper" size="1">
						<option value="=">is</option>
						<option value="<>">is not</option>
						<option value=">">more than</option>
						<option value="<">less than</option>
					</select>
					<input type="text" name="max_depth" id="max_depth">
				</td>
			</tr>
			<tr>
				<td>
					<label for="orig_elev_units">Elevation Units</label>
					<select name="orig_elev_units" id="orig_elev_units" size="1">
						<option value=""></option>
						<cfloop query="ctElevUnit">
							<option value="#ctElevUnit.orig_elev_units#">#ctElevUnit.orig_elev_units#</option>
						</cfloop>
					</select>
				</td>
				<td>
					<label for="depth_units">Depth Units</label>
					<select name="depth_units" id="depth_units" size="1">
						<option value=""></option>
						<cfloop query="ctDepthUnit">
							<option value="#ctDepthUnit.Depth_units#">#ctDepthUnit.Depth_units#</option>
						</cfloop>
					  	</select>
				</td>
			</tr>
			<tr>
				<td>
					<label for="MinElevOperM">Minimum Elevation (in meters)</label>
					<select name="MinElevOperM" id="MinElevOperM" size="1">
						<option value="=">is</option>
						<option value="<>">is not</option>
						<option value=">">more than</option>
						<option value="<">less than</option>
					</select>
					<input type="text" name="minimum_elevation_m" id="minimum_elevation_m">
				</td>
				<td>
					<label for="minDepthOperM">Minimum Depth (in meters)</label>
					<select name="minDepthOperM" id="MinDepthOperM" size="1">
						<option value="=">is</option>
						<option value="<>">is not</option>
						<option value=">">more than</option>
						<option value="<">less than</option>
					</select>
					<input type="text" name="min_depth_m" id="min_depth_m">
				</td>
			</tr>
			<tr>
				<td>
					<label for="MaxElevOperM">Maximum Elevation (in meters)</label>
					<select name="MaxElevOperM" id="MaxElevOperM" size="1">
						<option value="=">is</option>
						<option value="<>">is not</option>
						<option value=">">more than</option>
						<option value="<">less than</option>
					</select>
					<input type="text" name="maximum_elevation_m" id="maximum_elevation_m">
				</td>
				<td>
					<label for="MaxDepthOperM">Maximum Depth (in meters)</label>
					<select name="MaxDepthOperM" id="MaxDepthOperM" size="1">
						<option value="=">is</option>
						<option value="<>">is not</option>
						<option value=">">more than</option>
						<option value="<">less than</option>
					</select>
					<input type="text" name="max_depth_m" id="max_depth_m">
				</td>
			</tr>
			<tr>
				<td colspan="2">
					<label for="locality_remarks">Locality Remarks</label>
					<input type="text" name="locality_remarks" id="locality_remarks" size="80">
				</td>
			</tr>
			<tr>
				<td colspan=2>
					<table>
						<tr>
							<td>
								<label for="geology_attribute">Geology Attribute</label>
								<select name="geology_attribute" id="geology_attribute">
									<option value="">Anything</option>
									<cfloop query="ctgeology_attribute">
										<option value = "#ctgeology_attribute.geology_attribute#">#ctgeology_attribute.geology_attribute#</option>
									</cfloop>
								</select>
							</td>
							<td>
								<label for="geo_att_value">Attribute Value</label>
								<input type="text" name="geo_att_value">
							</td>
							<td>
								<label for="geology_attribute_hier">Traverse Hierarchies?</label>
								<select name="geology_attribute_hier" id="geology_attribute_hier">
									<option selected="selected" value="0">No</option>
									<option value="1">Yes</option>
								</select>
							</td>
						</tr>
					</table>
				</td>
			</tr>
			<tr>
				<td>
					<label for="sovereign_nation">Sovereign Nation</label>
					<select name="sovereign_nation" id="sovereign_nation" size="1">
						<option value=""></option>
						<cfloop query="ctsovereign_nation">
							<option value="#ctsovereign_nation.sovereign_nation#">#ctsovereign_nation.sovereign_nation#(#ctsovereign_nation.ct#)</option>
						</cfloop>
						<cfloop query="ctsovereign_nation" startRow="1">
							<option value="!#ctsovereign_nation.sovereign_nation#">!#ctsovereign_nation.sovereign_nation#</option>
						</cfloop>
					</select>
				</td>
				<td>
					<label for="curated_fg">Vetted</label>
					<select name="curated_fg" id="curated_fg">
						<option value=""></option>
						<option value="0">No</option>
						<option value="1">Yes *</option>
					</select>
			</tr>
		</table>
		<span id="georefDetailCtl" class="infoLink" style="font-size: 12px;margin-left: 600px;margin-bottom: 1em;display:block;" onclick="toggleGeorefDetail(1)";>Show Georeference Options</span>
		<div id="georefDetail" class="noShow">
		<table cellpadding="0" cellspacign="0">
			<tr>
				<td>
					<label for="findNoGeoRef">No Georeferences</label>
					<input type="checkbox" name="findNoGeoRef" id="findNoGeoRef">
				</td>
				<td>
					<label for="findHasGeoRef">Has Georeferences</label>
					<input type="checkbox" name="findHasGeoRef" id="findHasGeoRef">
				<td>
					<label for="findNoAccGeoRef">No Accepted Georeferences</label>
					<input type="checkbox" name="findNoAccGeoRef" id="findNoAccGeoRef">
				</td>
			</tr>
			<tr>
				<td>
					<label for="NoGeorefBecause">NoGeorefBecause</label>
					<input type="text" name="NoGeorefBecause" size="50" id="NoGeorefBecause">
				</td>
				<td>
					<label for="isIncomplete">isIncomplete</label>
					<input type="checkbox" name="isIncomplete" id="isIncomplete">
				</td>
				<td>
					<label for="nullNoGeorefBecause">NULL NoGeorefBecause</label>
					<input type="checkbox" name="nullNoGeorefBecause" id="nullNoGeorefBecause">
				</td>
			</tr>
			<tr>
				<td colspan="2">
					<label for="VerificationStatus">VerificationStatus</label>
					<select name="VerificationStatus" id="VerificationStatus" size="1">
						<option value=""></option>
						<cfloop query="ctVerificationStatus">
							<option value="#VerificationStatus#">#VerificationStatus#</option>
						</cfloop>
					</select>
				</td>
				<td>
					<div style="margin-left: 2em;" class="geolocateScoreDiv">
						<label>Shared Localities Only</label>
						<input type="checkbox" name="onlyShared" id="onlyShared">
					</div>
				</td>
			</tr>
			<tr>
				<td colspan="2">
					<label for="GeorefMethod">GeorefMethod</label>
					<select name="GeorefMethod" id="GeorefMethod" size="1" style="width: 400px;">
						<option value=""></option>
						<cfloop query="ctGeorefMethod">
							<option value="#GeorefMethod#">#GeorefMethod#</option>
						</cfloop>
					</select>
				</td>
				<td>
						<div style="margin-left: 2em;" class="geolocateScoreDiv">
							<label>Geolocate Precision</label>
							<select name="geolocate_precision" id="geolocate_precision" size="1">
								<option value="" SELECTED></option>
								<option value="high" >high</option>
								<option value="medium" >medium</option>
								<option value="low" >low</option>
							</select>

						</div>
				</td>
			</tr>
			<tr>
				<td colspan="2">
					<label for="coordinateDeterminer">Coordinate Determiner</label>
					<input type="text" name="coordinateDeterminer" size="50" id="coordinateDeterminer">
				</td>

				<td>


							<div style="margin-left: 2em;" class="geolocateScoreDiv">
							<label>Geolocate Score</label>
							<select name="gs_comparator" id="gs_comparator" size="1" onchange="java_script_:show(this.options[this.selectedIndex].value)">
								<option value="=" SELECTED>=</option>
								<option value="<" ><</option>
								<option value=">" >></option>
								<option value="between" >between</option>
							</select>

							<label id="hiddenDivlabel" style="display:none;">Min</label>
							<input type="text" name="geolocate_score" size="3" id="geolocate_score">

							<div id="hiddenDiv" style="display:none"><span style="font-size: 12px;">&amp;</span>
								<label style="display: inline;">Max</label>
								<input type="text" name="geolocate_score2" size="3" id="geolocate_score2">
							</div>
							</div>
				</td>
			</tr>
		</table>
	</div>
	</div>
	</div>
</cfif>
	<!--------------------------------------- event ----------------------------------------------------------->
	<cfif #showEvent# is 1>
	<div class="locGroup">
		<span id="eventDetailCtl" class="infoLink" onclick="toggleEventDetail(1)";>Show More Options</span>
	<table cellpadding="0" cellspacign="0">
		<tr>
			<td>
				<label for="verbatim_locality">Verbatim Locality</label>
				<input type="text" name="verbatim_locality" id="verbatim_locality" size="75">
			</td>
		</tr>
		<tr>
			<td>
				<label for="begDateOper">Began Date</label>
				<select name="begDateOper" id="begDateOper" size="1">
	            	<option value="=">is</option>
	                <option value="<">before</option>
	                <option value=">">after</option>
	            </select>
				<input type="text" name="began_date" id="began_date">
			</td>
		</tr>
		<tr>
			<td>
				<label for="endDateOper">Ended Date</label>
				<select name="endDateOper" id="endDateOper" size="1">
	            	<option value="=">is</option>
	                <option value="<">before</option>
	                <option value=">">after</option>
	            </select>
				<input type="text" name="ended_date" id="ended_date">
			</td>
		</tr>
	</table>
		<div id="eventDetail" class="noShow">
			<table cellpadding="0" cellspacign="0">
			<tr>
				<td style="padding-right: 1em;">
					<label for="verbatim_date">Verbatim Date</label>
					<input type="text" name="verbatim_date" id="verbatim_date" size="30">
				</td>
                <td>
                	<label for="verbatimCoordinates">Verbatim Coordinates</label>
					<input type="text" name="verbatimCoordinates" id="verbatimCoordinates" size="30">
                  </td>
                	<td style="padding-left: 1em;">
					<label for="collecting_method">Collecting Method</label>
					<input type="text" name="collecting_method" id="collecting_method" size="30">
				</td>
			</tr>
			<tr>
				<td style="padding-right: 1em;">
					<label for="coll_event_remarks">Collecting Event Remarks</label>
					<input type="text" name="coll_event_remarks" id="coll_event_remarks" size="30">
				</td>
                 <td>
                	<label for="verbatimCoordinateSystem">Verbatim Coordinate System</label>
					<input type="text" name="verbatimCoordinateSystem" id="verbatimCoordinateSystem" size="30">
                  </td>
                	<td style="padding-left: 1em;">
					<label for="habitat_desc">Habitat</label>
					<input type="text" name="habitat_desc" id="habitat_desc" size="30">
				</td>
			</tr>
			<tr>
				<td style="padding-right: 1em;">
					<label for="collecting_source">Collecting Source</label>
					<select name="collecting_source" id="collecting_source" size="1">
		            	<option value=""></option>
		                <cfloop query="ctCollectingSource">
		                	<option value="#ctCollectingSource.collecting_source#">#ctCollectingSource.collecting_source#</option>
		                </cfloop>
		           	</select>
				</td>
                	 <td>
                	<label for="verbatimSRS">Verbatim SRS (e.g., datum)</label>
					<input type="text" name="verbatimSRS" id="verbatimSRS" size="30">
                  </td>
                	<td style="padding-left: 1em;">
					<label for="collecting_event_id">Collecting Event ID</label>
					<input type="text" name="collecting_event_id" id="collecting_event_id" >
				</td>
			</tr>
			<tr>
				<td style="padding-right: 1em;">
					<label for="verbatimdepth">Verbatim Depth</label>
					<input type="text" name="verbatimdepth" id="verbatimdepth" size="30">
				</td>
				<td>
					<label for="verbatimelevation">Verbatim Elevation</label>
					<input type="text" name="verbatimelevation" id="verbatimelevation" size="30">
				</td>
				<td>
				</td>
			</tr>

		</table>
		</div>
		</div>
		</cfif>
<table>
	<tr>
		<td align="center">
			<input type="submit"
				value="Search"
				class="schBtn"
				onmouseover="this.className='schBtn btnhov'"
				onmouseout="this.className='schBtn'">&nbsp;&nbsp;
         <input type="reset"
				value="Clear Form"
				class="clrBtn"
				onmouseover="this.className='clrBtn btnhov'"
				onmouseout="this.className='clrBtn'">
		</td>
		<td>
			<cfif showLocality is 1 AND showSpecimenCounts>
				<label for="include_counts">Include Specimen Counts?</label>
				<select name="include_counts" id="include_counts">
					<option selected="selected" value="0">No</option>
					<option value="1">Yes</option>
				</select>
			</cfif>
		</td>
	</tr>
</table>
</td></tr></table>
<cfif isdefined("session.locSrchPrefs") and len(session.locSrchPrefs) gt 0>
	<cfloop list="#session.locSrchPrefs#" index="i">
		<cfset r='toggle' & i>
		<script type="text/javascript" language="javascript">
			#r#(1);
		</script>
	</cfloop>
</cfif>

</cfoutput>
