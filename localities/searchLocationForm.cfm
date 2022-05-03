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

<section class="row border rounded bg-light mt-2 mb-4 p-2" title="Geography Search Form">
	<div class="col-12"> 
		<div class="form-row mb-0">
			<div class="col-12 mb-1 mb-md-0">
				<label for="accentInsenstive" class="data-entry-label">Accent Insensitive Search?</label>
        		<input type="checkbox" name="accentInsensitive" id="accentInsensitive" value="1" class="data-entry-input">
			</div>
			<div class="col-12 col-md-6">
				<label for="higher_geog" class="data-entry-input">
					Higher Geog
					<span class="small90">
						(<button type="button" tabindex="-1" aria-hidden="true" class="btn-link p-0 border-0 bg-light" onclick="var e=document.getElementById('higher_geog');e.value='!'+e.value;" >!<span class="sr-only">prefix with = for exact match</span></button>)
					</span>
				</label>
				<input type="text" name="higher_geog" id="higher_geog" class="data-entry-input">
			</div>
			<div class="col-12 col-md-2">
					<label for="geog_auth_rec_id" class="data-entry-label">Geog Auth Rec ID</label>
					<input type="text" name="geog_auth_rec_id" id="geog_auth_rec_id" class="data-entry-input">
			</div>
			<div class="col-12 col-md-2">
				<button type="button" id="geogDetailCtl" class="btn btn-xs btn-secondary" onclick="toggleGeogDetail(1);">More Options</span>
			</div>
		</div>
		<div id="geogDetail" class="">
			<div class="form-row mb-0">
				<div class="col-12 col-md-3">
					<label for="continent_ocean" class="data-entry-label">Continent or Ocean
						<span class="small90">
							(<button type="button" tabindex="-1" aria-hidden="true" class="btn-link p-0 border-0 bg-light" onclick="var e=document.getElementById('continent_ocean');e.value='!'+e.value;" >!<span class="sr-only">prefix with = for exact match</span></button>)
						</span>
					</label>
					<input type="text" name="continent_ocean" id="continent_ocean" class="data-entry-input">
					<script>
						jQuery(document).ready(function() {
							makeGeogSearchAutocomplete('continent_ocean','continent_ocean');
						});
					</script>
				</div>
				<div class="col-12 col-md-3">
					<label for="ocean_region" class="data-entry-label" >Ocean Region</label>
					<input type="text" name="ocean_region" id="ocean_region" class="data-entry-input">
					<script>
						jQuery(document).ready(function() {
							makeGeogSearchAutocomplete('ocean_region','ocean_region');
						});
					</script>
				</div>
				<div class="col-12 col-md-3">
					<label for="ocean_subregion" class="data-entry-label">Ocean SubRegion</label>
					<input type="text" name="ocean_subregion" id="ocean_subregion" class="data-entry-input">
					<script>
						jQuery(document).ready(function() {
							makeGeogSearchAutocomplete('ocean_subregion','ocean_subregion');
						});
					</script>
				</div>
				<div class="col-12 col-md-3">
					<label for="sea" class="data-entry-label">Sea</label>
					<input type="text" name="sea" id="sea" class="data-entry-input">
					<script>
						jQuery(document).ready(function() {
							makeGeogSearchAutocomplete('sea','sea');
						});
					</script>
				</div>
			</div>
			<div class="form-row mb-0">
				<div class="col-12 col-md-3">
					<label for="island" class="data-entry-label">Island</label>
					<input type="text" name="island" id="island" class="data-entry-input">
					<script>
						jQuery(document).ready(function() {
							makeGeogSearchAutocomplete('island','island');
						});
					</script>
				</div>
				<div class="col-12 col-md-3">
					<label for="island_group" class="data-entry-label">Island Group</label>
					<select name="island_group" id="island_group" class="data-entry-select">
						<option value=""></option>
						<cfloop query="ctIslandGroup">
							<option value = "#ctIslandGroup.island_group#">#ctIslandGroup.island_group#</option>
						</cfloop>
					</select>
				</div>
				<div class="col-12 col-md-3">
					<label for="feature" class="data-entry-label">Land Feature</label>
					<input type="text" name="feature" id="feature" class="data-entry-input">
					<script>
						jQuery(document).ready(function() {
							makeGeogSearchAutocomplete('feature','feature');
						});
					</script>
				</div>
				<div class="col-12 col-md-3">
					<label for="water_feature" class="data-entry-label">Water Feature</label>
					<input type="text" name="water_feature" id="water_feature" class="data-entry-input">
					<script>
						jQuery(document).ready(function() {
							makeGeogSearchAutocomplete('water_feature','water_feature');
						});
					</script>
				</div>
			</div>
			<div class="form-row mb-0">
				<div class="col-12 col-md-3">
					<label for="country" class="data-entry-label">Country</label>
					<input type="text" name="country" id="country" class="data-entry-input">
					<span class="small90">
						(<button type="button" tabindex="-1" aria-hidden="true" class="btn-link p-0 border-0 bg-light" onclick="var e=document.getElementById('country');e.value='!'+e.value;" >!<span class="sr-only">prefix with = for exact match</span></button>)
					</span>
					<script>
						jQuery(document).ready(function() {
							makeGeogSearchAutocomplete('country','country');
						});
					</script>
				</div>
				<div class="col-12 col-md-3">
					<label for="state_prov" class="data-entry-label">State or Province</label>
					<input type="text" name="state_prov" id="state_prov" class="data-entry-input">
					<script>
						jQuery(document).ready(function() {
							makeGeogSearchAutocomplete('state_prov','state_prov');
						});
					</script>
				</div>
				<div class="col-12 col-md-3">
					<label for="county" class="data-entry-label">County</label>
					<input type="text" name="county" id="county" class="data-entry-input">
					<script>
						jQuery(document).ready(function() {
							makeGeogSearchAutocomplete('county','county');
						});
					</script>
				</div>
				<div class="col-12 col-md-3">
					<label for="quad" class="data-entry-label">Quad</label>
					<input type="text" name="quad" id="quad" class="data-entry-input">
					<script>
						jQuery(document).ready(function() {
							makeGeogSearchAutocomplete('quad','quad');
						});
					</script>
				</div>
			</div>
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
