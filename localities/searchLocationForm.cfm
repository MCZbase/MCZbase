<cfinclude template="/shared/_header.cfm">
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

<cfif isdefined("session.locSrchPrefs") and len(session.locSrchPrefs) gt 0>
	<cfset searchPrefList = session.locSrchPrefs>
<cfelse>
	<cfset searchPrefList = "">
</cfif>

<cfoutput>
<section class="container-fluid mt-2 mb-3" title="Geography Search Form">
	<div class="row mx-0 mb-3"> 
		<div class="search-box">
			<div class="search-box-header">
			<h1 class="h3 text-white">Higher Geography</h1>
			<cfif listFind(searchPrefList,"GeogDetail") EQ 0>
			<cfset geogDetailStyle="display:none;">
			<cfset toggleTo = "1">
			<cfset geogButton = "More Fields">
		<cfelse>
			<cfset geogDetailStyle="">
			<cfset toggleTo = "0">
			<cfset geogButton = "Fewer Fields">
		</cfif> 
			<div class="form-row mb-0">
			<div class="col-12 col-md-8">
				<label for="higher_geog" class="data-entry-label">
					Higher Geog
					<span class="small90">
						(<button type="button" tabindex="-1" aria-hidden="true" class="btn-link p-0 border-0 bg-light" onclick="var e=document.getElementById('higher_geog');e.value='='+e.value;" >=<span class="sr-only">prefix with = for exact match</span></button>)
					</span>
				</label>
				<input type="text" name="higher_geog" id="higher_geog" class="data-entry-input">
			</div>
			<div class="col-12 col-md-2">
					<label for="geog_auth_rec_id" class="data-entry-label">Geog Auth Rec ID</label>
					<input type="text" name="geog_auth_rec_id" id="geog_auth_rec_id" class="data-entry-input">
			</div>
			<div class="col-12 col-md-2">
				<label for="geogDetailCtl" class="data-entry-label">Geography</label>
				<button type="button" id="geogDetailCtl" class="btn btn-xs btn-secondary" onclick="toggleGeogDetail(#toggleTo#);">#geogButton#</span>
			</div>
		</div>
			<div id="geogDetail" class="" style="#geogDetailStyle#">
			<div class="form-row mb-0">
				<div class="col-12 col-md-3">
					<label for="continent_ocean" class="data-entry-label">Continent or Ocean
						<span class="small90">
							(<button type="button" tabindex="-1" aria-hidden="true" class="btn-link p-0 border-0 bg-light" onclick="var e=document.getElementById('continent_ocean');e.value='='+e.value;" >=<span class="sr-only">prefix with = for exact match</span></button>)
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
					<input type="text" name="island_group" id="island_group" class="data-entry-input">
					<script>
						jQuery(document).ready(function() {
							makeGeogSearchAutocomplete('island_group','island_group');
						});
					</script>
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
		</div>
	</div> 

	<!--------------------------------------- Locality ----------------------------------------------------------->
	<cfif #showLocality# IS 1>
	<div class="col-12"> 
		<h2 class="h3">Locality</h2>
		<cfif listFind(searchPrefList,"LocDetail") EQ 0>
			<cfset locDetailStyle="display:none;">
			<cfset toggleTo = "1">
			<cfset locButton = "More Fields">
		<cfelse>
			<cfset locDetailStyle="">
			<cfset toggleTo = "0">
			<cfset locButton = "Fewer Fields">
		</cfif> 
		<div class="form-row mb-0">
			<div class="col-12 col-md-8">
				<label for="spec_locality" class="data-entry-label">Specific Locality</label>
				<input type="text" name="spec_locality" id="spec_locality" class="data-entry-input">
			</div>
			<div class="col-12 col-md-2">
				<label for="locality_id" class="data-entry-label">Locality_ID</label>
				<input type="text" name="locality_id" id="locality_id" class="data-entry-input">
			</div>
			<div class="col-12 col-md-2">
				<label for="locDetailCtl" class="data-entry-label">Locality</label>
				<button type="button" id="locDetailCtl" class="btn btn-xs btn-secondary" onclick="toggleLocDetail(#toggleTo#);">#locButton#</span>
			</div>
		</div>
		<div id="locDetail" class="" style="#locDetailStyle#">
			<div class="form-row mb-0">
				<div class="col-12 col-md-4">
					<label for="collnOper" class="data-entry-label">Use</label>
					<select name="collnOper" id="collnOper" size="1" class="data-entry-select">
						<option value=""></option>
						<option value="usedOnlyBy">used only by</option>
						<option value="usedBy">used by</option>
						<option value="notUsedBy">not used by</option>
					</select class="data-entry-label">
				</div>
				<div class="col-12 col-md-4">
					<label for="collection_id" class="data-entry-label">Collection</label>
					<select name="collection_id" id="collection_id" size="1" class="data-entry-select">
						<option value=""></option>
						<cfloop query="ctcollection">
							<option value="#ctcollection.collection_id#">#ctcollection.collection#</option>
						</cfloop>
					</select>
				</div>
				<div class="col-12 col-md-4">
					<label for="curated_fg" class="data-entry-label">Vetted</label>
					<select name="curated_fg" id="curated_fg" class="data-entry-select">
						<option value=""></option>
						<option value="0">No</option>
						<option value="1">Yes *</option>
					</select>
				</div>
			</div>
			<div class="form-row mb-0">
				<div class="col-12 col-md-8">
					<label for="locality_remarks" class="data-entry-label">Locality Remarks</label>
					<input type="text" name="locality_remarks" id="locality_remarks" class="data-entry-input">
				</div>
				<div class="col-12 col-md-4">
					<label for="sovereign_nation" class="data-entry-label">Sovereign Nation</label>
					<select name="sovereign_nation" id="sovereign_nation" size="1" class="data-entry-select">
						<option value=""></option>
						<cfloop query="ctsovereign_nation">
							<option value="#ctsovereign_nation.sovereign_nation#">#ctsovereign_nation.sovereign_nation#(#ctsovereign_nation.ct#)</option>
						</cfloop>
						<cfloop query="ctsovereign_nation" startRow="1">
							<option value="!#ctsovereign_nation.sovereign_nation#">!#ctsovereign_nation.sovereign_nation#</option>
						</cfloop>
					</select>
				</div>
			</div>
			<div class="form-row mb-0">
				<div class="col-12 col-md-2">
					<label class="data-entry-label">Elevation</label>
					<label class="data-entry-label">Original Units</label>
				</div>
				<div class="col-12 col-md-2">
					<label for="MinElevOper" class="data-entry-label">(</label>
					<select name="MinElevOper" id="MinElevOper" size="1" class="data-entry-select">
						<option value="=">is</option>
						<option value="<>">is not</option>
						<option value=">">more than</option>
						<option value="<">less than</option>
					</select>
				</div>
				<div class="col-12 col-md-2">
					<label for="minimum_elevation" class="data-entry-label">Minimum Elevation</label>
					<input type="text" name="minimum_elevation" id="minimum_elevation" class="data-entry-input">
				</div>
				<div class="col-12 col-md-2">
					<label for="orig_elev_units" class="data-entry-label">Elevation Units</label>
					<select name="orig_elev_units" id="orig_elev_units" size="1" class="data-entry-select">
						<option value=""></option>
						<cfloop query="ctElevUnit">
							<option value="#ctElevUnit.orig_elev_units#">#ctElevUnit.orig_elev_units#</option>
						</cfloop>
					</select>
				</div>
				<div class="col-12 col-md-2">
					<label for="MaxElevOper" class="data-entry-label">Elevation</label>
					<select name="MaxElevOper" id="MaxElevOper" size="1" class="data-entry-select">
						<option value="=">is</option>
						<option value="<>">is not</option>
						<option value=">">more than</option>
						<option value="<">less than</option>
					</select>
				</div>
				<div class="col-12 col-md-2">
					<label for="maximum_elevation" class="data-entry-label">Maximum Elevation</label>
					<input type="text" name="maximum_elevation" id="maximum_elevation" class="data-entry-input">
				</div>
			</div>
			<div class="form-row mb-0">
				<div class="col-12 col-md-2">
					<label class="data-entry-label">Depth</label>
					<label class="data-entry-label">Original Units</label>
				</div>
				<div class="col-12 col-md-2">
					<label for="minDepthOper" class="data-entry-label"></label>
					<select name="minDepthOper" id="MinDepthOper" size="1" class="data-entry-select">
						<option value="=">is</option>
						<option value="<>">is not</option>
						<option value=">">more than</option>
						<option value="<">less than</option>
					</select>
				</div>
				<div class="col-12 col-md-2">
					<label for="min_depth" class="data-entry-label">Minimum Depth</label>
					<input type="text" name="min_depth" id="min_depth" class="data-entry-input">
				</div>
				<div class="col-12 col-md-2">
					<label for="depth_units" class="data-entry-label">Depth Units</label>
					<select name="depth_units" id="depth_units" size="1" class="data-entry-select">
						<option value=""></option>
						<cfloop query="ctDepthUnit">
							<option value="#ctDepthUnit.Depth_units#">#ctDepthUnit.Depth_units#</option>
						</cfloop>
					</select>
				</div>
				<div class="col-12 col-md-2">
					<label for="MaxDepthOper" class="data-entry-label"></label>
					<select name="MaxDepthOper" id="MaxDepthOper" size="1" class="data-entry-select">
						<option value="=">is</option>
						<option value="<>">is not</option>
						<option value=">">more than</option>
						<option value="<">less than</option>
					</select>
				</div>
				<div class="col-12 col-md-2">
					<label for="max_depth" class="data-entry-label">Maximum Depth</label>
					<input type="text" name="max_depth" id="max_depth" class="data-entry-input">
				</div>
			</div>
			<div class="form-row mb-0">
				<div class="col-12 col-md-3">
					<label for="MinElevOperM" class="data-entry-label">Minimum Elevation In Meters</label>
					<select name="MinElevOperM" id="MinElevOperM" size="1" class="data-entry-select">
						<option value="=">is</option>
						<option value="<>">is not</option>
						<option value=">">more than</option>
						<option value="<">less than</option>
					</select>
				</div>
				<div class="col-12 col-md-3">
					<label for="minimum_elevation_m" class="data-entry-label">Minimum</label>
					<input type="text" name="minimum_elevation_m" id="minimum_elevation_m" class="data-entry-input">
				</div>
				<div class="col-12 col-md-3">
					<label for="MaxElevOperM" class="data-entry-label">Maximum Elevation (in meters)</label>
					<select name="MaxElevOperM" id="MaxElevOperM" size="1" class="data-entry-select">
						<option value="=">is</option>
						<option value="<>">is not</option>
						<option value=">">more than</option>
						<option value="<">less than</option>
					</select>
				</div>
				<div class="col-12 col-md-3">
					<label for="maximum_elevation_m" class="data-entry-label">Maximum</label>
					<input type="text" name="maximum_elevation_m" id="maximum_elevation_m" class="data-entry-input">
				</div>
			</div>
			<div class="form-row mb-0">
				<div class="col-12 col-md-3">
					<label for="minDepthOperM" class="data-entry-label">Minimum Depth (in meters)</label>
					<select name="minDepthOperM" id="MinDepthOperM" size="1" class="data-entry-select">
						<option value="=">is</option>
						<option value="<>">is not</option>
						<option value=">">more than</option>
						<option value="<">less than</option>
					</select>
				</div>
				<div class="col-12 col-md-3">
					<label for="min_depth_m" class="data-entry-label">Maximum</label>
					<input type="text" name="min_depth_m" id="min_depth_m" class="data-entry-input">
				</div>
				<div class="col-12 col-md-3">
					<label for="MaxDepthOperM" class="data-entry-label">Maximum Depth (in meters)</label>
					<select name="MaxDepthOperM" id="MaxDepthOperM" size="1" class="data-entry-label">
						<option value="=">is</option>
						<option value="<>">is not</option>
						<option value=">">more than</option>
						<option value="<">less than</option>
					</select>
				</div>
				<div class="col-12 col-md-3">
					<label for="max_depth_m" class="data-entry-label">Maximum</label>
					<input type="text" name="max_depth_m" id="max_depth_m" class="data-entry-input">
				</div>
			</div>
			<div class="form-row mb-0">
				<div class="col-12 col-md-4">
					<label for="geology_attribute" class="data-entry-label">Geology Attribute</label>
					<select name="geology_attribute" id="geology_attribute" class="data-entry-select">
						<option value=""></option>
						<cfloop query="ctgeology_attribute">
							<option value = "#ctgeology_attribute.geology_attribute#">#ctgeology_attribute.geology_attribute#</option>
						</cfloop>
					</select>
				</div>
				<div class="col-12 col-md-3">
					<label for="geo_att_value" class="data-entry-label">Attribute Value</label>
					<input type="text" name="geo_att_value" class="data-entry-input">
				</div>
				<div class="col-12 col-md-3">
					<label for="geology_attribute_hier" class="data-entry-label">Traverse Hierarchies?</label>
					<select name="geology_attribute_hier" id="geology_attribute_hier" class="data-entry-select">
						<option selected="selected" value="0">No</option>
						<option value="1">Yes</option>
					</select>
				</div>
				<cfif listFind(searchPrefList,"GeorefDetail") EQ 0>
					<cfset georefDetailStyle="display:none;">
					<cfset toggleTo = "1">
					<cfset georefButton = "Show Fields">
				<cfelse>
					<cfset georefDetailStyle="">
					<cfset toggleTo = "0">
					<cfset georefButton = "Hide Fields">
				</cfif> 
				<div class="col-12 col-md-2">
					<label for="georefDetailCtl" class="data-entry-label">Georeference</label>
					<button type="button" id="georefDetailCtl" class="btn btn-xs btn-secondary" onclick="toggleGeorefDetail(#toggleTo#);">#georefButton#</span>
				</div>
			</div>
			<div id="georefDetail" class="border rounded p-1" style="#georefDetailStyle#">
				<div class="form-row mb-0">
					<div class="col-12 col-md-2">
						<label for="findNoGeoRef" class="data-entry-label">No Georeferences</label>
						<input type="checkbox" name="findNoGeoRef" id="findNoGeoRef" class="data-entry-input">
					</div>
					<div class="col-12 col-md-2">
						<label for="findHasGeoRef" class="data-entry-label">Has Georeferences</label>
						<input type="checkbox" name="findHasGeoRef" id="findHasGeoRef" class="data-entry-input">
					</div>
					<div class="col-12 col-md-2">
						<label for="findNoAccGeoRef" class="data-entry-label">No Accepted Georeferences</label>
						<input type="checkbox" name="findNoAccGeoRef" id="findNoAccGeoRef" class="data-entry-input">
					</div>
					<div class="col-12 col-md-2">
						<label for="NoGeorefBecause" class="data-entry-label">NoGeorefBecause</label>
						<input type="text" name="NoGeorefBecause" id="NoGeorefBecause" class="data-entry-input">
					</div>
					<div class="col-12 col-md-2">
						<label for="isIncomplete" class="data-entry-label">isIncomplete</label>
						<input type="checkbox" name="isIncomplete" id="isIncomplete" class="data-entry-input">
					</div>
					<div class="col-12 col-md-2">
						<label for="nullNoGeorefBecause" class="data-entry-label">NULL NoGeorefBecause</label>
						<input type="checkbox" name="nullNoGeorefBecause" id="nullNoGeorefBecause" class="data-entry-input">
					</div>
				</div>
				<div class="form-row mb-0">
					<div class="col-12 col-md-3">
						<label for="VerificationStatus" class="data-entry-label">VerificationStatus</label>
						<select name="VerificationStatus" id="VerificationStatus" size="1" class="data-entry-select">
							<option value=""></option>
							<cfloop query="ctVerificationStatus">
								<option value="#VerificationStatus#">#VerificationStatus#</option>
							</cfloop>
						</select>
					</div>
					<div class="col-12 col-md-3">
						<label class="data-entry-label">Shared Localities Only</label>
						<input type="checkbox" name="onlyShared" id="onlyShared" class="data-entry-input">
					</div>
					<div class="col-12 col-md-3">
						<label for="GeorefMethod" class="data-entry-label">GeorefMethod</label>
						<select name="GeorefMethod" id="GeorefMethod" size="1" class="data-entry-select">
							<option value=""></option>
							<cfloop query="ctGeorefMethod">
								<option value="#GeorefMethod#">#GeorefMethod#</option>
							</cfloop>
						</select>
					</div>
					<div class="col-12 col-md-3">
						<label class="data-entry-label">Geolocate Precision</label>
						<select name="geolocate_precision" id="geolocate_precision" size="1" class="data-entry-select">
							<option value="" SELECTED></option>
							<option value="high" >high</option>
							<option value="medium" >medium</option>
							<option value="low" >low</option>
						</select>
					</div>
				</div>
				<div class="form-row mb-0">
					<div class="col-12 col-md-4">
						<label for="coordinateDeterminer" class="data-entry-label">Coordinate Determiner</label>
						<input type="text" name="coordinateDeterminer" id="coordinateDeterminer" class="data-entry-select">
					</div>
					<div class="col-12 col-md-4">
						<label class="data-entry-label">Geolocate Score</label>
						<select name="gs_comparator" id="gs_comparator" size="1" class="data-entry-select">
							<option value="=" SELECTED>=</option>
							<option value="<" ><</option>
							<option value=">" >></option>
							<option value="between" >between</option>
						</select>
					</div>
					<div class="col-12 col-md-2">
						<label class="data-entry-label">Min</label>
						<input type="text" name="geolocate_score" size="3" id="geolocate_score" class="data-entry-input">
					</div>
					<div class="col-12 col-md-2">
						<label class="data-entry-label">Max</label>
						<input type="text" name="geolocate_score2" size="3" id="geolocate_score2" class="data-entry-input">
					</div>
				</div>
			</div><!--- end georefDetail --->
		</div><!--- end locDetail --->
	</div>
	</cfif>

	<!----------------------------------- Collecting Event ----------------------------------------------------------->
	<cfif #showEvent# is 1>
	<div class="col-12"> 
		<h2 class="h3">Collecting Event<h2>
		<cfif listFind(searchPrefList,"EventDetail") EQ 0>
			<cfset eventDetailStyle="display:none;">
			<cfset toggleTo = "1">
			<cfset eventButton = "More Fields">
		<cfelse>
			<cfset eventDetailStyle="">
			<cfset toggleTo = "0">
			<cfset eventButton = "Fewer Fields">
		</cfif> 
		<div class="form-row mb-0">
			<div class="col-12 col-md-8">
				<label for="verbatim_locality" class="data-entry-label">Verbatim Locality</label>
				<input type="text" name="verbatim_locality" id="verbatim_locality" size="75" class="data-entry-input">
			</div>
			<div class="col-12 col-md-2">
				<label for="collecting_event_id">Collecting Event ID</label>
				<input type="text" name="collecting_event_id" id="collecting_event_id" >
			</div>
			<div class="col-12 col-md-2">
				<label for="eventDetailCtl" class="data-entry-label">Collecting Event</label>
				<button type="button" id="eventDetailCtl" class="btn btn-xs btn-secondary" onclick="toggleEventDetail(#toggleTo#);">#eventButton#</span>
			</div>
		</div>
		<div class="form-row mb-0">
			<div class="col-12 col-md-2">
				<label for="begDateOper" class="data-entry-label">Began Date(</label>
				<select name="begDateOper" id="begDateOper" size="1" class="data-entry-select">
	            	<option value="=">is</option>
	                <option value="<">before</option>
	                <option value=">">after</option>
	            </select>
			</div>
			<div class="col-12 col-md-3">
				<input type="text" name="began_date" id="began_date" class="data-entry-input">
			</div>
			<div class="col-12 col-md-2">
				<label for="endDateOper" class="data-entry-label">Ended Date</label>
				<select name="endDateOper" id="endDateOper" size="1" class="data-entry-select">
	            	<option value="=">is</option>
	                <option value="<">before</option>
	                <option value=">">after</option>
	            </select>
			</div>
			<div class="col-12 col-md-3">
				<input type="text" name="ended_date" id="ended_date" class="data-entry-input">
			</div>
			<div class="col-12 col-md-2">
				<label for="verbatim_date" class="data-entry-label">Verbatim Date</label>
				<input type="text" name="verbatim_date" id="verbatim_date" class="data-entry-input">
			</div>
		</div>
		<div id="eventDetail" style="#eventDetailStyle#" >
			<div class="form-row mb-0">
				<div class="col-12 col-md-3">
               <label for="verbatimCoordinates">Verbatim Coordinates</label>
					<input type="text" name="verbatimCoordinates" id="verbatimCoordinates" size="30">
				</div>
				<div class="col-12 col-md-3">
					<label for="collecting_method" class="data-entry-label">Collecting Method</label>
					<input type="text" name="collecting_method" id="collecting_method"  class="data-entry-input">
				</div>
				<div class="col-12 col-md-3">
					<label for="coll_event_remarks" class="data-entry-label">Collecting Event Remarks</label>
					<input type="text" name="coll_event_remarks" id="coll_event_remarks"  class="data-entry-input">
				</div>
				<div class="col-12 col-md-3">
               <label for="verbatimCoordinateSystem" class="data-entry-label">Verbatim Coordinate System</label>
					<input type="text" name="verbatimCoordinateSystem" id="verbatimCoordinateSystem"  class="data-entry-input">
				</div>
			</div>
			<div class="form-row mb-0">
				<div class="col-12 col-md-4">
					<label for="habitat_desc" class="data-entry-label">Habitat</label>
					<input type="text" name="habitat_desc" id="habitat_desc"  class="data-entry-input">
				</div>
				<div class="col-12 col-md-4">
					<label for="collecting_source">Collecting Source</label>
					<select name="collecting_source" id="collecting_source" size="1">
						<option value=""></option>
						<cfloop query="ctCollectingSource">
							<option value="#ctCollectingSource.collecting_source#">#ctCollectingSource.collecting_source#</option>
						</cfloop>
		        	</select>
				</div>
				<div class="col-12 col-md-4">
              	<label for="verbatimSRS">Verbatim SRS (e.g., datum)</label>
					<input type="text" name="verbatimSRS" id="verbatimSRS" size="30">
				</div>
			</div>
		</div>
	</div>
	</cfif>

	<!---------------   Buttons ------------------------------------------------>

	<div class="col-12"> 
		<div class="form-row mb-0">
			<div class="col-12 col-md-2">
				<label for="accentInsenstive" class="data-entry-label">Accent Insensitive Search?</label>
        		<input type="checkbox" name="accentInsensitive" id="accentInsensitive" value="1" class="data-entry-input">
			</div>
			<div class="col-12 col-md-2">
				<input type="submit"
					value="Search"
					class="schBtn"
					onmouseover="this.className='schBtn btnhov'"
					onmouseout="this.className='schBtn'">
			</div>
			<div class="col-12 col-md-2">
 	        <input type="reset"
					value="Clear Form"
					class="clrBtn"
					onmouseover="this.className='clrBtn btnhov'"
					onmouseout="this.className='clrBtn'">
			</div>
			<div class="col-12 col-md-2">
				<cfif showLocality is 1 AND showSpecimenCounts >
					<label for="include_counts">Include Specimen Counts?</label>
					<select name="include_counts" id="include_counts">
						<option selected="selected" value="0">No</option>
						<option value="1">Yes</option>
					</select>
				</cfif>
			</div>
		</div>
	</div>

	<script type="text/javascript" language="javascript">
		function toggleGeogDetail(onOff) {
			if (onOff==0) {
				$("##geogDetail").hide();
				$("##geogDetailCtl").attr('onCLick','toggleGeogDetail(1)').html('More Fields');
			} else {
				$("##geogDetail").show();
				$("##geogDetailCtl").attr('onCLick','toggleGeogDetail(0)').html('Fewer Fields');
			}
			<cfif isdefined("session.username") and len(#session.username#) gt 0>
				jQuery.getJSON("/localities/component/functions.cfc",
					{
						method : "saveLocSrchPref",
						id : 'GeogDetail',
						onOff : onOff,
						returnformat : "json",
						queryformat : 'column'
					}, 
					function (data) { 
						console.log(data);
					}
				).fail(function(jqXHR,textStatus,error){
					handleFail(jqXHR,textStatus,error,"persisting GeogDetail state");
				});
			</cfif>
		}
		function toggleLocDetail(onOff) {
			if (onOff==0) {
				$("##locDetail").hide();
				$("##locDetailCtl").attr('onCLick','toggleLocDetail(1)').html('More Fields');
			} else {
				$("##locDetail").show();
				$("##locDetailCtl").attr('onCLick','toggleLocDetail(0)').html('Fewer Fields');
			}
			<cfif isdefined("session.username") and len(#session.username#) gt 0>
				jQuery.getJSON("/localities/component/functions.cfc",
					{
						method : "saveLocSrchPref",
						id : 'LocDetail',
						onOff : onOff,
						returnformat : "json",
						queryformat : 'column'
					},
					function (data) { 
						console.log(data);
					}
				).fail(function(jqXHR,textStatus,error){
					handleFail(jqXHR,textStatus,error,"persisting LocDetail state");
				});
			</cfif>
		}
		function toggleGeorefDetail(onOff) {
			if (onOff==0) {
				$("##georefDetail").hide();
				$("##georefDetailCtl").attr('onCLick','toggleGeorefDetail(1)').html('Show Fields');
			} else {
				$("##georefDetail").show();
				$("##georefDetailCtl").attr('onCLick','toggleGeorefDetail(0)').html('Hide Fields');
			}
			<cfif isdefined("session.username") and len(#session.username#) gt 0>
				jQuery.getJSON("/localities/component/functions.cfc",
					{
						method : "saveLocSrchPref",
						id : 'GeorefDetail',
						onOff : onOff,
						returnformat : "json",
						queryformat : 'column'
					},
					function (data) { 
						console.log(data);
					}
				).fail(function(jqXHR,textStatus,error){
					handleFail(jqXHR,textStatus,error,"persisting GeorefDetail state");
				});
			</cfif>
		}
		function toggleEventDetail(onOff) {
			if (onOff==0) {
				$("##eventDetail").hide();
				$("##eventDetailCtl").attr('onCLick','toggleEventDetail(1)').html('More Fields');
			} else {
				$("##eventDetail").show();
				$("##eventDetailCtl").attr('onCLick','toggleEventDetail(0)').html('Fewer Fields');
			}
			<cfif isdefined("session.username") and len(#session.username#) gt 0>
				jQuery.getJSON("/localities/component/functions.cfc",
					{
						method : "saveLocSrchPref",
						id : 'EventDetail',
						onOff : onOff,
						returnformat : "json",
						queryformat : 'column'
					},
					function (data) { 
						console.log(data);
					}
				).fail(function(jqXHR,textStatus,error){
					handleFail(jqXHR,textStatus,error,"persisting EventDetail state");
				});
			</cfif>
		}
	</script>
</section>

</cfoutput>
