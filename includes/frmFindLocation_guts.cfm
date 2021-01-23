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
	select geology_attribute from ctgeology_attribute order by geology_attribute
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

<table class="table table-responsive">
    <tr><td>
        <span id="_generic_m_ai">Accent&nbsp;Insensitive?</span><input type="checkbox" name="accentInsensitive" id="accentInsensitive" value="1">
    </td></tr>
    <tr><td>
	<div class="locGroup">
		<span id="geogDetailCtl" class="infoLink" onclick="toggleGeogDetail(1)";>Show More Options</span>
		<table class="table">
		<tr>
			<td colspan="2">
				<label for="higher_geog">Higher Geog
				<input type="text" name="higher_geog" id="higher_geog" class="form-control form-control-sm w-100">
				<span class="infolink" onclick="var e=document.getElementById('higher_geog');e.value='='+e.value;">
									Add = for exact match</label>
				</span>
			</td>
		</tr>
	</table>
		<div id="geogDetail" class="noShow">
		<table class="table table-fixed">
			<tr>
				<td>
					<label for="continent_ocean">Continent or Ocean
					<input type="text" name="continent_ocean" id="continent_ocean" class="form-control form-control-sm">
				        <span class="infolink" onclick="var e=document.getElementById('continent_ocean');e.value='='+e.value;">
									Add = for exact match
				        </span></label>
				</td>
				<td class="pl-3">
					<label for="ocean_region">Ocean Region
					<input type="text" name="ocean_region" id="ocean_region" class="form-control form-control-sm"></label>
				</td>
			</tr>
			<tr>
			<td>
				<label for="ocean_subregion">Ocean SubRegion
				<input type="text" name="ocean_subregion" id="ocean_subregion" class="form-control form-control-sm"></label>
			</td>
			<td class="pl-3">
				<label for="sea">Sea
				<input type="text" name="sea" id="sea" class="form-control form-control-sm"></label>
			</td>
			</tr>
			<tr>
			<td>
				<label for="island">Island
						<input type="text" name="island" id="island" class="form-control form-control-sm"></label>
			</td>
			<td class="pl-3">
				<label for="island_group">Island Group
					<select name="island_group" id="island_group"  class="form-control form-control-sm">
						<option value=""></option>
						<cfloop query="ctIslandGroup">
							<option value = "#ctIslandGroup.island_group#">#ctIslandGroup.island_group#</option>
						</cfloop>
					</select></label>
			</td>
			</tr>
			<tr>
			<td>
				<label for="feature">Land Feature
				<select name="feature" id="feature" class="form-control form-control-sm">
					<option value=""></option>
					<cfloop query="ctFeature">
						<option value = "#ctFeature.feature#">#ctFeature.feature#</option>
					</cfloop>
				</select></label>
			</td>
				<td class="pl-3">
					<label for="water_feature">Water Feature
						<select name="water_feature" id="water_feature" class="form-control form-control-sm">
							<option value=""></option>
								<cfloop query="ctWater_Feature">
								<option value = "#ctWater_Feature.water_feature#">#ctWater_Feature.water_feature#</option>
								</cfloop>
						</select></label>
			</td>
			</tr>
			<tr>
				<td>
					<label for="country">Country
					<input type="text" name="country" id="country" class="form-control form-control-sm">
				        <span class="infolink" onclick="var e=document.getElementById('country');e.value='='+e.value;">
									Add = for exact match
				        </span></label>
				</td>
				<td class="pl-3">
					<label for="state_prov">State or Province
					<input type="text" name="state_prov" id="state_prov" class="form-control form-control-sm"></label>
				</td>
			</tr>
			<tr>
				<td>
					<label for="county">County
					<input type="text" name="county" id="county" class="form-control form-control-sm"></label>
				</td>
					<td class="pl-3">
					<label for="quad">Quad
					<input type="text" name="quad" id="quad" class="form-control form-control-sm"></label>
				</td>
				</tr>
				<tr>
				<td>&nbsp;</td>
        	<td class="pl-3">
					<label for="geog_auth_rec_id">Geog Auth Rec ID
					<input type="text" name="geog_auth_rec_id" id="geog_auth_rec_id" class="form-control form-control-sm"></label>
				</td>
			</tr>
		</table>
		</div>

</div>

<cfif #showLocality# is 1>
	<div class="locGroup">
		<span id="locDetailCtl" class="infoLink" onclick="toggleLocDetail(1)";>Show More Options</span>
	<table class="table table-responsive">
		<tr>
			<td>
				<label for="spec_locality">Specific Locality
				<input type="text" name="spec_locality" id="spec_locality" class="form-control form-control-sm"></label>
			</td>
		</tr>
		</table>
		<div id="locDetail" class="noShow">
		<table class="table table-responsive">
			<tr>
				<td>
					<label for="collnOper" class="mb-0">Collection</label>
					<div class="input-group">
					<div class="input-group-prepend">
					<select name="collnOper" id="collnOper" size="1" class="form-control form-control-sm">
						<option value="">Choose</option>
						<option value="usedOnlyBy">used only by</option>
						<option value="usedBy">used by</option>
						<option value="notUsedBy">not used by</option>
						</select></div>
					<select name="collection_id" id="collection_id" size="1" class="form-control input-group-append mr-5 form-control-sm d-flex">
						<option value=""></option>
						<cfloop query="ctcollection">
							<option value="#ctcollection.collection_id#">#ctcollection.collection#</option>
						</cfloop>
					</select>
					</div>
				</td>
				<td>
					<label for="locality_id">Locality ID
					<input type="text" name="locality_id" id="locality_id" class="form-control form-control-sm"></label>
				</td>
			</tr>
			<tr>
				<td>
					<label for="MinElevOper" class="mb-0">Minimum Elevation (only with units below)</label>
					<div class="input-group">
					<div class="input-group-prepend">
					<select name="MinElevOper" id="MinElevOper" size="1" class="form-control form-control-sm">
						<option value="=">is</option>
						<option value="<>">is not</option>
						<option value=">">more than</option>
						<option value="<">less than</option>
						</select></div>
					<input type="text" name="minimum_elevation" id="minimum_elevation" class="form-control input-group-append mr-5 form-control-sm d-flex">
						</div>
				</td>
				<td>
					<label for="minDepthOper" class="mb-0">Minimum Depth (only with units below)</label>
						<div class="input-group">
					<div class="input-group-prepend">
					<select name="minDepthOper" id="MinDepthOper" size="1" class="form-control form-control-sm">
						<option value="=">is</option>
						<option value="<>">is not</option>
						<option value=">">more than</option>
						<option value="<">less than</option>
						</select></div>
					<input type="text" name="min_depth" id="min_depth" class="form-control form-control-sm input-group-append d-flex">
							</div>
				</td>
			</tr>
			<tr>
				<td>
					<label for="MaxElevOper" class="mb-0">Maximum Elevation (only with units below)</label>
					<div class="input-group">
					<div class="input-group-prepend">
					<select name="MaxElevOper" id="MaxElevOper" size="1" class="form-control form-control-sm">
						<option value="=">is</option>
						<option value="<>">is not</option>
						<option value=">">more than</option>
						<option value="<">less than</option>
						</select></div>
					<input type="text" name="maximum_elevation" id="maximum_elevation" class="form-control mr-5 input-group-append form-control-sm d-flex">
					</div>
				</td>
				<td>
					<label for="MaxDepthOper" class="mb-0">Maximum Depth (only with units below)</label>
					<div class="input-group">
					<div class="input-group-prepend">
					<select name="MaxDepthOper" id="MaxDepthOper" size="1" class="form-control form-control-sm">
						<option value="=">is</option>
						<option value="<>">is not</option>
						<option value=">">more than</option>
						<option value="<">less than</option>
						</select></div>
					<input type="text" name="max_depth" id="max_depth" class="form-control form-control-sm input-group-append d-flex">
					</div>
				</td>
			</tr>
			<tr>
				<td>
					<label for="orig_elev_units">Elevation Units
					<select name="orig_elev_units" id="orig_elev_units" size="1" class="form-control w-75 form-control-sm">
						<option value=""></option>
						<cfloop query="ctElevUnit">
							<option value="#ctElevUnit.orig_elev_units#">#ctElevUnit.orig_elev_units#</option>
						</cfloop>
					</select></label>
				</td>
				<td>
					<label for="depth_units">Depth Units
					<select name="depth_units" id="depth_units" size="1" class="form-control form-control-sm">
						<option value=""></option>
						<cfloop query="ctDepthUnit">
							<option value="#ctDepthUnit.Depth_units#">#ctDepthUnit.Depth_units#</option>
						</cfloop>
					  	</select></label>
				</td>
			</tr>
			<tr>
				<td>
					<label for="MinElevOperM" class="mb-0">Minimum Elevation (in meters)</label>
					<div class="input-group">
					<div class="input-group-prepend">
					<select name="MinElevOperM" id="MinElevOperM" size="1" class="form-control form-control-sm">
						<option value="=">is</option>
						<option value="<>">is not</option>
						<option value=">">more than</option>
						<option value="<">less than</option>
						</select></div>
					<input type="text" name="minimum_elevation_m" id="minimum_elevation_m" class="form-control mr-5 form-control-sm input-group-append d-flex">
					</div>
				</td>
				<td>
					<label for="minDepthOperM" class="mb-0">Minimum Depth (in meters)</label>
						<div class="input-group">
					<div class="input-group-prepend">
					<select name="minDepthOperM" id="MinDepthOperM" size="1" class="form-control form-control-sm">
						<option value="=">is</option>
						<option value="<>">is not</option>
						<option value=">">more than</option>
						<option value="<">less than</option>
						</select></div>
					<input type="text" name="min_depth_m" id="min_depth_m" class="form-control form-control-sm input-group-append d-flex">
					</div>
				</td>
			</tr>
			<tr>
				<td>
					<label for="MaxElevOperM">Maximum Elevation (in meters)</label>
						<div class="input-group">
					<div class="input-group-prepend">
					<select name="MaxElevOperM" id="MaxElevOperM" size="1" class="form-control form-control-sm">
						<option value="=">is</option>
						<option value="<>">is not</option>
						<option value=">">more than</option>
						<option value="<">less than</option>
					</select></div>
					<input type="text" name="maximum_elevation_m" id="maximum_elevation_m" class="form-control form-control-sm input-group-append d-flex">
			</div>
				</td>
				<td class="pl-3">
					<label for="MaxDepthOperM">Maximum Depth (in meters)</label>
						<div class="input-group">
					<div class="input-group-prepend">
					<select name="MaxDepthOperM" id="MaxDepthOperM" size="1" class="form-control form-control-sm">
						<option value="=">is</option>
						<option value="<>">is not</option>
						<option value=">">more than</option>
						<option value="<">less than</option>
						</select></div>
					<input type="text" name="max_depth_m" id="max_depth_m" class="form-control form-control-sm input-group-append d-flex">
							</div>
				</td>
			</tr>
			<tr>
				<td colspan="2">
					<label for="locality_remarks">Locality Remarks
					<input type="text" name="locality_remarks" id="locality_remarks" class="form-control form-control-sm"></label>
				</td>
			</tr>
			<tr>
				<td>
					<table class="table table-responsive">
						<tr>
							<td>
								<label for="geology_attribute">Geology Attribute
								<select name="geology_attribute" id="geology_attribute" class="form-control form-control-sm">
									<option value="">Anything</option>
									<cfloop query="ctgeology_attribute">
										<option value = "#ctgeology_attribute.geology_attribute#">#ctgeology_attribute.geology_attribute#</option>
									</cfloop>
								</select></label>
							</td>
							<td>
								<label for="geo_att_value">Attribute Value
								<input type="text" name="geo_att_value" class="form-control form-control-sm"></label>
							</td>
							<td>
								<label for="geology_attribute_hier">Traverse Hierarchies?
								<select name="geology_attribute_hier" id="geology_attribute_hier" class="form-control form-control-sm">
									<option selected="selected" value="0">No</option>
									<option value="1">Yes</option>
								</select></label>
							</td>
						</tr>
					</table>
				</td>
				<td>
					<label for="sovereign_nation">Sovereign Nation
					<select name="sovereign_nation" id="sovereign_nation" size="1" class="form-control form-control-sm">
						<option value=""></option>
						<cfloop query="ctsovereign_nation">
							<option value="#ctsovereign_nation.sovereign_nation#">#ctsovereign_nation.sovereign_nation#(#ctsovereign_nation.ct#)</option>
						</cfloop>
						<cfloop query="ctsovereign_nation" startRow="1">
							<option value="!#ctsovereign_nation.sovereign_nation#">!#ctsovereign_nation.sovereign_nation#</option>
						</cfloop>
					</select></label>
				</td>
			</tr>
		</table>
		<span id="georefDetailCtl" class="infoLink" style="font-size: 12px;margin-bottom: 1em;display:block;" onclick="toggleGeorefDetail(1)";>Show Georeference Options</span>
		<div id="georefDetail" class="noShow">
		<table class="table table-responsive">
			<tr>
				<td>
					<label for="findNoGeoRef">No Georeferences
					<input type="checkbox" name="findNoGeoRef" id="findNoGeoRef" class="checkbox"></label>
				</td>
				<td>
					<label for="findHasGeoRef">Has Georeferences
					<input type="checkbox" name="findHasGeoRef" id="findHasGeoRef" class="checkbox"></label>
				<td>
					<label for="findNoAccGeoRef">No Accepted Georeferences
					<input type="checkbox" name="findNoAccGeoRef" id="findNoAccGeoRef" class="checkbox"></label>
				</td>
			</tr>
			<tr>
				<td colspan="2">
					<label for="NoGeorefBecause">NoGeorefBecause
					<input type="text" name="NoGeorefBecause" class="form-control form-control-sm" id="NoGeorefBecause"></label>
				</td>
				<td>
					<label for="isIncomplete">isIncomplete
					<input type="checkbox" name="isIncomplete" id="isIncomplete" class="checkbox"></label>
				</td>
				<td>
					<label for="nullNoGeorefBecause">NULL NoGeorefBecause
					<input type="checkbox" name="nullNoGeorefBecause" id="nullNoGeorefBecause" class="checkbox"></label>
				</td>
			</tr>
			<tr>
				<td>
					<label for="VerificationStatus">VerificationStatus
					<select name="VerificationStatus" id="VerificationStatus" size="1" class="form-control form-control-sm">
						<option value=""></option>
						<cfloop query="ctVerificationStatus">
							<option value="#VerificationStatus#">#VerificationStatus#</option>
						</cfloop>
					</select></label>
				</td>
				<td>
					<div class="geolocateScoreDiv">
						<label>Shared Localities Only
						<input type="checkbox" name="onlyShared" id="onlyShared" class="checkbox">
					</div>
				</td>
			</tr>
			<tr>
				<td colspan="2">
					<label for="GeorefMethod">GeorefMethod
					<select name="GeorefMethod" id="GeorefMethod" size="1" class="form-control form-control-sm">
						<option value=""></option>
						<cfloop query="ctGeorefMethod">
							<option value="#GeorefMethod#">#GeorefMethod#</option>
						</cfloop>
					</select></label>
				</td>
				<td>
						<div style="margin-left: 2em;" class="geolocateScoreDiv">
							<label>Geolocate Precision
							<select name="geolocate_precision" id="geolocate_precision" size="1" class="form-control form-control-sm">
								<option value="" SELECTED></option>
								<option value="high" >high</option>
								<option value="medium" >medium</option>
								<option value="low" >low</option>
							</select></label>

						</div>
				</td>
			</tr>
			<tr>
				<td colspan="2">
					<label for="coordinateDeterminer">Coordinate Determiner
					<input type="text" name="coordinateDeterminer" class="form-control form-control-sm" id="coordinateDeterminer"></label>
				</td>

				<td colspan="2">


							<div class="geolocateScoreDiv">
							<label>Geolocate Score</label>
							<select name="gs_comparator" id="gs_comparator" size="1" onchange="java_script_:show(this.options[this.selectedIndex].value)"  class="form-control form-control-sm">
								<option value="=" SELECTED>=</option>
								<option value="<" ><</option>
								<option value=">" >></option>
								<option value="between" >between</option>
							</select>

							<label id="hiddenDivlabel" style="display:none;">Min</label>
							<input type="text" name="geolocate_score" size="3" id="geolocate_score" class="form-control form-control-sm">

							<div id="hiddenDiv" style="display:none"><span style="font-size: 12px;">&amp;</span>
								<label style="display: inline;">Max</label>
								<input type="text" name="geolocate_score2" size="3" id="geolocate_score2" class="form-control form-control-sm">
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
				<label for="verbatim_locality">Verbatim Locality
				<input type="text" name="verbatim_locality" id="verbatim_locality"  class="form-control form-control-sm"></label>
			</td>
		</tr>
		<tr>
			<td>
				<label for="begDateOper">Began Date</label>
				<select name="begDateOper" id="begDateOper" size="1" class="form-control form-control-sm">
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
				<select name="endDateOper" id="endDateOper" size="1" class="form-control form-control-sm">
	            	<option value="=">is</option>
	                <option value="<">before</option>
	                <option value=">">after</option>
	            </select>
				<input type="text" name="ended_date" id="ended_date" class="form-control form-control-sm w-50">
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
				<label for="include_counts">Include Specimen Counts?
				<select name="include_counts" id="include_counts">
					<option selected="selected" value="0">No</option>
					<option value="1">Yes</option>
				</select></label>
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
