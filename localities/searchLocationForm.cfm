<cfif not isdefined("showLocality")>
	<!--- display the form with the locality fields included --->
	<cfset showLocality=0>
</cfif>
<cfif not isdefined("showEvent")>
	<!--- display the form with the locality and event fields included --->
	<cfset showEvent=0>
</cfif>
<cfif not isdefined("showExtraFields")>
	<!--- support rendering form with fields not supported in findLocality custom tag. --->
	<cfset showExtraFields=0>
</cfif>
<cfif not isdefined("showSpecimenCounts")>
	<!--- show or hide the specimen counts control, show by default if locality section is included --->
	<cfset showSpecimenCounts = true>
</cfif>
<cfif not isdefined("newSearchTarget")>
	<!--- if newSearchTarget has a value, the New Search button will be shown with an onclick event that reloads to the specified newSearchTarget --->
	<cfset newSearchTarget="">
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
<div class="row mx-0">
<section class="col-12 px-0 mt-0 mb-0" title="Geography, Locality, Collecting Event Search Form">

	<!--------------------------------------- Higher Geography ----------------------------------------------------------->
	<div class="row mx-0 mb-0"> 
		<div class="col-12 px-0 mt-0">
			<div class="jqx-widget-header border-bottom px-4 py-1">
				<h2 class="h4 text-dark mb-0">Higher Geography</h2>
			</div>
			<cfif listFind(searchPrefList,"GeogDetail") EQ 0>
				<cfset geogDetailStyle="display:none;">
				<cfset toggleTo = "1">
				<cfset geogButton = "More Fields">
			<cfelse>
				<cfset geogDetailStyle="">
				<cfset toggleTo = "0">
				<cfset geogButton = "Fewer Fields">
			</cfif> 
			<div class="form-row mx-0 mb-0">
				<div class="col-12 col-md-8 px-3 mt-md-3 mb-md-3 mt-2 mb-0">
					<label for="higher_geog" class="data-entry-label">
						Higher Geog
						<span class="small90">
							(<button type="button" tabindex="-1" aria-hidden="true" class="btn-link p-0 border-0 bg-light" onclick="var e=document.getElementById('higher_geog');e.value='='+e.value;" >=<span class="sr-only">prefix with = for exact match</span></button>)
						</span>
					</label>
					<cfif not isDefined("higher_geog")><cfset higher_geog=""></cfif>
					<input type="text" name="higher_geog" id="higher_geog" class="data-entry-input" value="#encodeForHtml(higher_geog)#> 
				</div>
				<div class="col-12 col-md-2 px-3 px-md-0 mt-md-3 mb-md-3 mt-2 mb-0">
					<label for="geog_auth_rec_id" class="data-entry-label">Geog Auth Rec ID</label>
					<cfif not isDefined("geog_auth_rec_id")><cfset geog_auth_rec_id=""></cfif>
					<input type="text" name="geog_auth_rec_id" id="geog_auth_rec_id" class="data-entry-input" value="#encodeForHtml(geog_auth_rec_id)#>
				</div>
				<div class="col-12 col-md-2 px-3 mt-sm-3 mb-md-3 mt-0 mb-3">
					<label for="geogDetailCtl" class="data-entry-label d-sm-none d-md-inline float-left" style="color: transparent">Geography</label>
					<button type="button" id="geogDetailCtl" class="btn btn-xs btn-secondary" onclick="toggleGeogDetail(#toggleTo#);">#geogButton#</button>
				</div>
			</div>
			<div id="geogDetail" class="col-12 px-3" style="#geogDetailStyle#">
				<div class="form-row">
					<div class="col-12 col-md-3 my-1">
						<label for="continent_ocean" class="data-entry-label">Continent or Ocean
							<span class="small90">
								(<button type="button" tabindex="-1" aria-hidden="true" class="btn-link p-0 border-0 bg-light" onclick="var e=document.getElementById('continent_ocean');e.value='='+e.value;" >=<span class="sr-only">prefix with = for exact match</span></button>)
							</span>
						</label>
						<cfif not isDefined("continent_ocean")><cfset continent_ocean=""></cfif>
						<input type="text" name="continent_ocean" id="continent_ocean" class="data-entry-input" value="#encodeForHtml(continent_ocean)#>
						<script>
							jQuery(document).ready(function() {
								makeGeogSearchAutocomplete('continent_ocean','continent_ocean');
							});
						</script>
					</div>
					<div class="col-12 col-md-3 my-1">
						<cfif not isDefined("ocean_region")><cfset ocean_region=""></cfif>
						<label for="ocean_region" class="data-entry-label" >Ocean Region</label>
						<input type="text" name="ocean_region" id="ocean_region" class="data-entry-input" value="#encodeForHtml(ocean_region)#>
						<script>
							jQuery(document).ready(function() {
								makeGeogSearchAutocomplete('ocean_region','ocean_region');
							});
						</script>
					</div>
					<div class="col-12 col-md-3 my-1">
						<cfif not isDefined("ocean_subregion")><cfset ocean_subregion=""></cfif>
						<label for="ocean_subregion" class="data-entry-label">Ocean SubRegion</label>
						<input type="text" name="ocean_subregion" id="ocean_subregion" class="data-entry-input" value="#encodeForHtml(ocean_subregion)#>
						<script>
							jQuery(document).ready(function() {
								makeGeogSearchAutocomplete('ocean_subregion','ocean_subregion');
							});
						</script>
					</div>
					<div class="col-12 col-md-3 my-1">
						<cfif not isDefined("sea")><cfset sea=""></cfif>
						<label for="sea" class="data-entry-label">Sea</label>
						<input type="text" name="sea" id="sea" class="data-entry-input" value="#encodeForHtml(sea)#>
						<script>
							jQuery(document).ready(function() {
								makeGeogSearchAutocomplete('sea','sea');
							});
						</script>
					</div>
				</div>
				<div class="form-row mb-0">
					<div class="col-12 col-md-3 my-1">
						<cfif not isDefined("island")><cfset island=""></cfif>
						<label for="island" class="data-entry-label">Island</label>
						<input type="text" name="island" id="island" class="data-entry-input" value="#encodeForHtml(island)#>
						<script>
							jQuery(document).ready(function() {
								makeGeogSearchAutocomplete('island','island');
							});
						</script>
					</div>
					<div class="col-12 col-md-3 my-1">
						<cfif not isDefined("island_group")><cfset island_group=""></cfif>
						<label for="island_group" class="data-entry-label">Island Group</label>
						<input type="text" name="island_group" id="island_group" class="data-entry-input" value="#encodeForHtml(island_group)#>
						<script>
							jQuery(document).ready(function() {
								makeGeogSearchAutocomplete('island_group','island_group');
							});
						</script>
					</div>
					<div class="col-12 col-md-3 my-1">
						<cfif not isDefined("feature")><cfset feature=""></cfif>
						<label for="feature" class="data-entry-label">Land Feature</label>
						<input type="text" name="feature" id="feature" class="data-entry-input" value="#encodeForHtml(feature)#>
						<script>
							jQuery(document).ready(function() {
								makeGeogSearchAutocomplete('feature','feature');
							});
						</script>
					</div>
					<div class="col-12 col-md-3 my-1">
						<cfif not isDefined("water_feature")><cfset water_feature=""></cfif>
						<label for="water_feature" class="data-entry-label">Water Feature</label>
						<input type="text" name="water_feature" id="water_feature" class="data-entry-input" value="#encodeForHtml(water_feature)#>
						<script>
							jQuery(document).ready(function() {
								makeGeogSearchAutocomplete('water_feature','water_feature');
							});
						</script>
					</div>
				</div>
				<div class="form-row mb-3">
					<div class="col-12 col-md-3 my-1">
						<cfif not isDefined("country")><cfset country=""></cfif>
						<label for="country" class="data-entry-label">Country</label>
						<input type="text" name="country" id="country" class="data-entry-input" value="#encodeForHtml(country)#>
						<script>
							jQuery(document).ready(function() {
								makeGeogSearchAutocomplete('country','country');
							});
						</script>
					</div>
					<div class="col-12 col-md-3 my-1">
						<cfif not isDefined("state_prov")><cfset state_prov=""></cfif>
						<label for="state_prov" class="data-entry-label">State or Province</label>
						<input type="text" name="state_prov" id="state_prov" class="data-entry-input" value="#encodeForHtml(state_prov)#>
						<script>
							jQuery(document).ready(function() {
								makeGeogSearchAutocomplete('state_prov','state_prov');
							});
						</script>
					</div>
					<div class="col-12 col-md-3 my-1">
						<cfif not isDefined("county")><cfset county=""></cfif>
						<label for="county" class="data-entry-label">County</label>
						<input type="text" name="county" id="county" class="data-entry-input" value="#encodeForHtml(county)#>
						<script>
							jQuery(document).ready(function() {
								makeGeogSearchAutocomplete('county','county');
							});
						</script>
					</div>
					<div class="col-12 col-md-3 my-1">
						<cfif not isDefined("quad")><cfset quad=""></cfif>
						<label for="quad" class="data-entry-label">Quad</label>
						<input type="text" name="quad" id="quad" class="data-entry-input" value="#encodeForHtml(quad)#>
						<script>
							jQuery(document).ready(function() {
								makeGeogSearchAutocomplete('quad','quad');
							});
						</script>
					</div>
				</div>
				<cfif #showExtraFields# IS 1>
					<div class="form-row mb-0">
						<div class="col-12 col-md-3 my-1">
							<cfif not isDefined("wkt_polygon")><cfset wkt_polygon=""></cfif>
							<label for="wkt_polygon" class="data-entry-label">Polygon (WKT)</label>
							<select name="wkt_polygon" id="wkt_polygon" size="1" class="data-entry-select">
								<option value=""></option>
								<cfif ucase(wkt_polygon) EQ "NOT NULL"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option value="NOT NULL" #selected#>Has Shape</option>
								<cfif ucase(wkt_polygon) EQ "NULL"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option value="NULL" #selected#>No Shape</option>
							</select>
						</div>
						<div class="col-12 col-md-3 my-1">
							<cfif not isDefined("highergeographyid")><cfset highergeographyid=""></cfif>
							<label for="highergeographyid" class="data-entry-label">dwc:higherGeographyID</label>
							<input type="text" name="highergeographyid" id="highergeographyid" class="data-entry-input" value="#encodeForHtml(highergeographyid)#>
							<script>
								jQuery(document).ready(function() {
									makeGeogSearchAutocomplete('highergeographyid','highergeographyid');
								});
							</script>
						</div>
					</div>
				</cfif>
			</div>
		</div>
	</div>

	<!--------------------------------------- Locality ----------------------------------------------------------->
	<cfif #showLocality# IS 1>
		<div class="row mb-1"> 
			<div class="col-12 mt-0">
				<div class="jqx-widget-header border-bottom border-top px-4 py-1">
					<h2 class="h4 text-dark mb-0">Locality</h2>
				</div>
				<cfif listFind(searchPrefList,"LocDetail") EQ 0>
					<cfset locDetailStyle="display:none;">
					<cfset toggleTo = "1">
					<cfset locButton = "More Fields">
				<cfelse>
					<cfset locDetailStyle="">
					<cfset toggleTo = "0">
					<cfset locButton = "Fewer Fields">
				</cfif> 
				<div class="form-row mx-0 mb-0">
					<div class="col-12 col-md-8 px-3 mt-md-3 mb-md-3 mt-2 mb-3">
						<cfif not isDefined("spec_locality")><cfset spec_locality=""></cfif>
						<label for="spec_locality" class="data-entry-label">Specific Locality</label>
						<input type="text" name="spec_locality" id="spec_locality" class="data-entry-input" value="#encodeForHtml(encodeForHtml(spec_locality))#>
					</div>
					<div class="col-12 col-md-2 px-3 px-md-0 mt-md-3 mb-md-3 mt-2 mb-0">
						<cfif not isDefined("locality_id")><cfset locality_id=""></cfif>
						<label for="locality_id" class="data-entry-label">Locality ID</label>
						<input type="text" name="locality_id" id="locality_id" class="data-entry-input" value="#encodeForHtml(encodeForHtml(locality_id))#>
					</div>
					<div class="col-12 col-md-2 px-3 mt-sm-3 mb-md-3 mt-0 mb-3">
						<label for="locDetailCtl" class="data-entry-label d-sm-none d-md-inline float-left" style="color: transparent">Locality</label>
						<button type="button" id="locDetailCtl" class="btn btn-xs btn-secondary" onclick="toggleLocDetail(#toggleTo#);">#locButton#</button>
					</div>
				</div>
				<div id="locDetail" class="" style="#locDetailStyle#">
					<div class="form-row px-3 my-2">
						<div class="col-12 col-md-4">
							<cfif not isDefined("collnOper")><cfset collnOper=""></cfif>
							<label for="collnOper" class="data-entry-label">Use</label>
							<select name="collnOper" id="collnOper" size="1" class="data-entry-select">
								<cfif len(collnOper) EQ 0><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option value="" #selected#></option>
								<cfif collnOper EQ "usedOnlyBy"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option value="usedOnlyBy" #selected#>used only by</option>
								<cfif collnOper EQ "usedBy"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option value="usedBy" #selected#>used by</option>
								<cfif collnOper EQ "notUsedBy"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option value="notUsedBy" #selected#>not used by</option>
							</select>
						</div>
						<div class="col-12 col-md-4">
							<cfif not isDefined("collection_id")><cfset collection_id=""></cfif>
							<label for="collection_id" class="data-entry-label">Collection</label>
							<select name="collection_id" id="collection_id" size="1" class="data-entry-select">
								<option value=""></option>
								<cfloop query="ctcollection">
									<cfif collection_id EQ ctcollection.collection_id><cfset selected="selected"><cfelse><cfset selected=""></cfif>
									<option value="#ctcollection.collection_id#" #selected#>#ctcollection.collection#</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12 col-md-4">
							<cfif not isDefined("curated_fg")><cfset curated_fg=""></cfif>
							<label for="curated_fg" class="data-entry-label">Vetted</label>
							<select name="curated_fg" id="curated_fg" class="data-entry-select">
								<option value=""></option>
								<cfif curated_fg EQ 0><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option value="0" #selected#>No</option>
								<cfif curated_fg EQ 1><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option value="1" #selected#>Yes *</option>
							</select>
						</div>
					</div>
					<div class="form-row px-3 my-2">
						<div class="col-12 col-md-8">
							<cfif not isDefined("locality_remarks")><cfset locality_remarks=""></cfif>
							<label for="locality_remarks" class="data-entry-label">Locality Remarks</label>
							<input type="text" name="locality_remarks" id="locality_remarks" class="data-entry-input" value="#encodeForHtml(locality_remarks)#>
						</div>
						<div class="col-12 col-md-4">
							<cfif not isDefined("sovereign_nation")><cfset sovereign_nation_val=""><cfelse><cfset sovereign_nation_val="#sovereign_nation#"></cfif>
							<label for="sovereign_nation" class="data-entry-label">Sovereign Nation</label>
							<select name="sovereign_nation" id="sovereign_nation" size="1" class="data-entry-select">
								<option value=""></option>
								<cfloop query="ctsovereign_nation">
									<cfif sovereign_nation_val EQ ctsovereign_nation.sovereign_nation><cfset selected="selected"><cfelse><cfset selected=""></cfif>
									<option value="#ctsovereign_nation.sovereign_nation#" #selected# >#ctsovereign_nation.sovereign_nation#(#ctsovereign_nation.ct#)</option>
								</cfloop>
								<cfloop query="ctsovereign_nation" startRow="1">
									<cfif sovereign_nation_val EQ "!#ctsovereign_nation.sovereign_nation#"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
									<option value="!#ctsovereign_nation.sovereign_nation#" #sovereign_nation#>!#ctsovereign_nation.sovereign_nation#</option>
								</cfloop>
							</select>
						</div>
					</div>
				<div class="form-row px-3 my-2">
					<div class="col-12 col-md-2">
						<label class="data-entry-label">Elevation <span class="small">(Original Units)</span></label>
					</div>
					<div class="col-12 col-md-2">
						<cfif not isDefined("MinElevOper")><cfset MinElevOper="="></cfif>
						<cfif MinElevOper IS "!"><cfset MinElevOper="<>"></cfif>
						<label for="MinElevOper" class="data-entry-label" style="color: transparent">(operator)</label>
						<select name="MinElevOper" id="MinElevOper" size="1" class="data-entry-select">
							<cfif MinElevOper IS "="><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value="=" #selected#>is</option>
							<cfif MinElevOper IS "<>"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value="<>" #selected#>is not</option><!--- " --->
							<cfif MinElevOper IS ">"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value=">" #selected#>more than</option><!--- " --->
							<cfif MinElevOper IS "<"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value="<" #selected#>less than</option>
						</select>
					</div>
					<div class="col-12 col-md-2">
						<label for="minimum_elevation" class="data-entry-label">Minimum Elevation</label>
						<cfif not isDefined("minimum_elevation")><cfset minimum_elevation=""></cfif>
						<input type="text" name="minimum_elevation" id="minimum_elevation" class="data-entry-input" value="#encodeForHtml(minimum_elevation)#>
					</div>
					<div class="col-12 col-md-2">
						<cfif isDefined("orig_elev_units")><cfset orig_elev_units_val="#orig_elev_units#"><cfelse><cfset orig_elev_units_val=""></cfif>
						<label for="orig_elev_units" class="data-entry-label">Elevation Units</label>
						<select name="orig_elev_units" id="orig_elev_units" size="1" class="data-entry-select">
							<option value=""></option>
							<cfloop query="ctElevUnit">
								<cfif ctElevUnit.orig_elev_units EQ orig_elev_units_val><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option value="#ctElevUnit.orig_elev_units#" #selected#>#ctElevUnit.orig_elev_units#</option>
							</cfloop>
						</select>
					</div>
					<div class="col-12 col-md-2">
						<cfif not isDefined("MaxElevOper")><cfset MaxElevOper="="></cfif>
						<cfif MaxElevOper IS "!"><cfset MaxElevOper="<>"></cfif>
						<label for="MaxElevOper" class="data-entry-label" style="color:transparent">Elevation</label>
						<select name="MaxElevOper" id="MaxElevOper" size="1" class="data-entry-select">
							<cfif MaxElevOper IS "="><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value="=" #selected#>is</option>
							<cfif MaxElevOper IS "<>"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value="<>" #selected#>is not</option><!--- " --->
							<cfif MaxElevOper IS ">"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value=">" #selected#>more than</option><!--- " --->
							<cfif MaxElevOper IS "<"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value="<" #selected#>less than</option>
						</select>
					</div>
					<div class="col-12 col-md-2">
						<cfif not isDefined("maximum_elevation")><cfset maximum_elevation=""></cfif>
						<label for="maximum_elevation" class="data-entry-label">Maximum Elevation</label>
						<input type="text" name="maximum_elevation" id="maximum_elevation" class="data-entry-input" value="#encodeForHtml(maximum_elevation)#">
					</div>
				</div>
				<div class="form-row px-3 my-2">
					<div class="col-12 col-md-2">
						<label class="data-entry-label">Depth <span class="small">(Original Units)</span></label>
					</div>
					<div class="col-12 col-md-2">
						<label for="minDepthOper" class="data-entry-label" style="color: transparent">Operator</label>
						<select name="minDepthOper" id="MinDepthOper" size="1" class="data-entry-select">
							<option value="=">is</option>
							<option value="<>">is not</option><!--- " --->
							<option value=">">more than</option><!--- " --->
							<option value="<">less than</option>
						</select>
					</div>
					<div class="col-12 col-md-2">
						<cfif not isDefined("min_depth")><cfset min_depth=""></cfif>
						<label for="min_depth" class="data-entry-label">Minimum Depth</label>
						<input type="text" name="min_depth" id="min_depth" class="data-entry-input" value="#encodeForHtml(min_depth)#">
					</div>
					<div class="col-12 col-md-2">
						<cfif isDefined("depth_units")><cfset depth_units_val="#depth_units#"><cfelse><cfset depth_units_val=""></cfif>
						<label for="depth_units" class="data-entry-label">Depth Units</label>
						<select name="depth_units" id="depth_units" size="1" class="data-entry-select">
							<option value=""></option>
							<cfloop query="ctDepthUnit">
								<cfif ctDepthUnit.Depth_units EQ depth_units_val><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option value="#ctDepthUnit.Depth_units#" #selected#>#ctDepthUnit.Depth_units#</option>
							</cfloop>
						</select>
					</div>
					<div class="col-12 col-md-2">
						<cfif isDefined("MaxDepthOper")><cfset MaxDepthOper="#MaxDepthOper#"><cfelse><cfset MaxDepthOper=""></cfif>
						<label for="MaxDepthOper" class="data-entry-label" style="color:transparent">operator</label>
						<select name="MaxDepthOper" id="MaxDepthOper" size="1" class="data-entry-select">
							<cfif MaxDepthOper EQ "="><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value="=" #selected#>is</option>
							<cfif MaxDepthOper EQ "<>"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value="<>" #selected#>is not</option><!--- " --->
							<cfif MaxDepthOper EQ ">"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value=">" #selected#>more than</option><!--- " --->
							<cfif MaxDepthOper EQ "<"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value="<" #selected#>less than</option>
						</select>
					</div>
					<div class="col-12 col-md-2">
						<cfif not isDefined("max_depth")><cfset max_depth=""></cfif>
						<label for="max_depth" class="data-entry-label">Maximum Depth</label>
						<input type="text" name="max_depth" id="max_depth" class="data-entry-input" value="#encodeForHtml(max_depth)#">
					</div>
				</div>
				<div class="form-row px-3 my-2">
					<div class="col-12 col-md-3">
						<cfif not isDefined("MinElevOperM")><cfset MinElevOperM="="></cfif>
						<cfif MinElevOperM IS "!"><cfset MinElevOperM="<>"></cfif>
						<label for="MinElevOperM" class="data-entry-label">Minimum Elevation (in Meters)</label>
						<select name="MinElevOperM" id="MinElevOperM" size="1" class="data-entry-select">
							<cfif MinElevOperM IS "="><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value="=" #selected#>is</option>
							<cfif MinElevOperM IS "<>"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value="<>" #selected#>is not</option><!--- " --->
							<cfif MinElevOperM IS ">"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value=">" #selected#>more than</option><!--- " --->
							<cfif MinElevOperM IS "<"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value="<" #selected#>less than</option>
						</select>
					</div>
					<div class="col-12 col-md-3">
						<cfif not isDefined("minimum_elevation_m")><cfset minimum_elevation_m=""></cfif>
						<label for="minimum_elevation_m" class="data-entry-label">Minimum</label>
						<input type="text" name="minimum_elevation_m" id="minimum_elevation_m" class="data-entry-input" value="#encodeForHtml(minimum_elevation_m)#>
					</div>
					<div class="col-12 col-md-3">
						<cfif not isDefined("MaxElevOperM")><cfset MaxElevOperM="="></cfif>
						<cfif MaxElevOperM IS "!"><cfset MaxElevOperM="<>"></cfif>
						<label for="MaxElevOperM" class="data-entry-label">Maximum Elevation (in meters)</label>
						<select name="MaxElevOperM" id="MaxElevOperM" size="1" class="data-entry-select">
							<cfif MaxElevOperM IS "="><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value="=" #selected#>is</option>
							<cfif MaxElevOperM IS "<>"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value="<>" #selected#>is not</option><!--- " --->
							<cfif MaxElevOperM IS ">"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value=">" #selected#>more than</option><!--- " --->
							<cfif MaxElevOperM IS "<"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value="<" #selected#>less than</option>
						</select>
					</div>
					<div class="col-12 col-md-3">
						<cfif not isDefined("maximum_elevation_m")><cfset maximum_elevation_m=""></cfif>
						<label for="maximum_elevation_m" class="data-entry-label">Maximum</label>
						<input type="text" name="maximum_elevation_m" id="maximum_elevation_m" class="data-entry-input" value="#encodeForHtml(maximum_elevation_m)#>
					</div>
				</div>
				<div class="form-row px-3 my-2">
					<div class="col-12 col-md-3">
						<cfif not isDefined("minDepthOperM")><cfset minDepthOperM="="></cfif>
						<label for="minDepthOperM" class="data-entry-label">Minimum Depth (in meters)</label>
						<select name="minDepthOperM" id="MinDepthOperM" size="1" class="data-entry-select">
							<cfif minDepthOperM IS "="><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value="=" #selected#>is</option>
							<cfif minDepthOperM IS "<>"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value="<>" #selected#>is not</option><!--- " --->
							<cfif minDepthOperM IS ">"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value=">" #selected#>more than</option><!--- " --->
							<cfif minDepthOperM IS "<"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value="<" #selected#>less than</option>
						</select>
					</div>
					<div class="col-12 col-md-3">
						<cfif not isDefined("min_depth_m")><cfset min_depth_m=""></cfif>
						<label for="min_depth_m" class="data-entry-label">Maximum</label>
						<input type="text" name="min_depth_m" id="min_depth_m" class="data-entry-input" value="#encodeForHtml(min_depth_m)#">
					</div>
					<div class="col-12 col-md-3">
						<cfif not isDefined("MaxDepthOperM")><cfset MaxDepthOperM="="></cfif>
						<label for="MaxDepthOperM" class="data-entry-label">Maximum Depth (in meters)</label>
						<select name="MaxDepthOperM" id="MaxDepthOperM" size="1" class="data-entry-select">
							<cfif MaxDepthOperM IS "="><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value="=" #selected#>is</option>
							<cfif MaxDepthOperM IS "<>"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value="<>" #selected#>is not</option><!--- " --->
							<cfif MaxDepthOperM IS ">"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value=">" #selected#>more than</option><!--- " --->
							<cfif MaxDepthOperM IS "<"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value="<" #selected#>less than</option>
						</select>
					</div>
					<div class="col-12 col-md-3">
						<cfif not isDefined("max_depth_m")><cfset max_depth_m=""></cfif>
						<label for="max_depth_m" class="data-entry-label">Maximum</label>
						<input type="text" name="max_depth_m" id="max_depth_m" class="data-entry-input" value="#encodeForHtml(max_depth_m)#">
					</div>
				</div>
				<cfif #showExtraFields# IS 1>
					<div class="form-row px-3 mt-2 mb-3">
						<div class="col-12 col-md-2">
							<cfif not isDefined("section_part")><cfset section_part=""></cfif>
							<label for="section_part" class="data-entry-label">PLSS Section Part</label>
							<input type="text" name="section_part" id="section_part" class="data-entry-input" value="#encodeForHtml(section_part)#>
						</div>
						<div class="col-12 col-md-2">
							<cfif not isDefined("section")><cfset section=""></cfif>
							<label for="section" class="data-entry-label">PLSS Section</label>
							<input type="text" name="section" id="section" class="data-entry-input" value="#encodeForHtml(section)#>
						</div>
						<div class="col-12 col-md-2">
							<cfif not isDefined("township")><cfset township=""></cfif>
							<label for="township" class="data-entry-label">PLSS Township</label>
							<input type="text" name="township" id="township" class="data-entry-input" value="#encodeForHtml(township)#>
						</div>
						<div class="col-12 col-md-2">
							<cfif not isDefined("township_direction")><cfset township_direction=""></cfif>
							<label for="township_direction" class="data-entry-label">Township Direction</label>
							<select name="township_direction" id="" size="1" class="data-entry-select">
								<cfif len(township_direction) EQ 0><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option value="" #selected#></option>
								<cfif ucase(township_direction) EQ "N"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option value="N" #selected#>N</option>
								<cfif ucase(township_direction) EQ "S"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option value="S" #selected#>S</option>
							</select>
						</div>
						<div class="col-12 col-md-2">
							<cfif not isDefined("range")><cfset range=""></cfif>
							<label for="range" class="data-entry-label">PLSS Range</label>
							<input type="text" name="range" id="range" class="data-entry-input" value="#encodeForHtml(range)#>
						</div>
						<div class="col-12 col-md-2">
							<cfif not isDefined("range_direction")><cfset range_direction=""></cfif>
							<label for="range_direction" class="data-entry-label">Township Direction</label>
							<select name="range_direction" id="" size="1" class="data-entry-select">
								<cfif len(range_direction) EQ 0><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option value="" #selected#></option>
								<cfif ucase(range_direction) EQ "N"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option value="N" #selected#>N</option>
								<cfif ucase(range_direction) EQ "S"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option value="S" #selected#>S</option>
							</select>
						</div>
					</div>
				</cfif>
				<div class="form-row px-3 mt-2 mb-3">
					<div class="col-12 col-md-4">
						<cfif isDefined("geology_attribute")><cfset geology_attribute_val="#geology_attribute#"><cfelse><cfset geology_attribute_val=""></cfif>
						<label for="geology_attribute" class="data-entry-label">Geology Attribute</label>
						<select name="geology_attribute" id="geology_attribute" class="data-entry-select">
							<option value=""></option>
							<cfloop query="ctgeology_attribute">
								<cfif ctgeology_attribute.geology_attribute EQ geology_attribute_val><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option value = "#ctgeology_attribute.geology_attribute#" #selected#>#ctgeology_attribute.geology_attribute#</option>
							</cfloop>
						</select>
					</div>
					<div class="col-12 col-md-3">
						<cfif not isDefined("geo_att_value")><cfset geo_att_value=""></cfif>
						<label for="geo_att_value" class="data-entry-label">Attribute Value</label>
						<input type="text" name="geo_att_value" class="data-entry-input" value="#encodeForHtml(geo_att_value)#>
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
						<cfset georefButton = "Show Georef Fields">
					<cfelse>
						<cfset georefDetailStyle="">
						<cfset toggleTo = "0">
						<cfset georefButton = "Hide Georef Fields">
					</cfif> 
					<div class="col-12 col-md-2">
						<label for="georefDetailCtl" class="data-entry-label" style="color: transparent">Georeference</label>
						<button type="button" id="georefDetailCtl" class="btn btn-xs btn-secondary" onclick="toggleGeorefDetail(#toggleTo#);">#georefButton#</button>
					</div>
				</div>
				<div id="georefDetail" class="border my-2 mx-3 rounded p-1" style="#georefDetailStyle#">
					<div class="form-row mx-0 px-3 my-2">
						<div class="col-6 col-md-3 px-4 pt-2 float-left">
							<input type="checkbox" name="findNoGeoRef" id="findNoGeoRef" class="form-check-input">
							<label for="findNoGeoRef" class="form-check-label mt3px small95">No Georeferences</label>
							
						</div>
						<div class="col-6 col-md-3 px-4 float-left pt-2">
							<div class="form-check">
								<input class="form-check-input" name="findHasGeoRef" id="findHasGeoRef" value="1" type="checkbox">
								<label class="form-check-label mt3px small95" for="findHasGeoRef">Has Georeferences</label>
							</div>
						</div>
						<div class="col-8 col-md-6 px-4 pt-2 float-left">
							<input type="checkbox" name="findNoAccGeoRef" id="findNoAccGeoRef" class="form-check-input">
							<label for="findNoAccGeoRef" class="form-check-label mt3px small95">No Accepted Georeferences</label>
						</div>
					</div>
					<div class="form-row mx-0 px-3 my-2">
						<div class="col-12 col-md-6 px-0 pt-2 pb-0 pb-md-2">
							<label for="NoGeorefBecause" class="data-entry-label">No Georeferece Because</label>
							<input type="text" name="NoGeorefBecause" id="NoGeorefBecause" class="data-entry-input">
						</div>
						<div class="col-6 col-md-3 px-4 px-md-5 pt-4 float-left">
							<input type="checkbox" name="isIncomplete" id="isIncomplete" class="form-check-input">
							<label for="isIncomplete" class="form-check-label mt3px small95">Is Incomplete</label>
						</div>
						<div class="col-6 col-md-3 px-4 pb-3 pt-4 float-left">
							<input type="checkbox" name="nullNoGeorefBecause" id="nullNoGeorefBecause" class="form-check-input">
							<label for="nullNoGeorefBecause" class="form-check-label mt3px small95">NULL, No Georef. Because</label>
							
						</div>
					</div>
					<div class="form-row mx-0 px-3 my-2">
						<div class="col-12 col-md-3 px-0 mb-2">
							<label for="VerificationStatus" class="data-entry-label">VerificationStatus</label>
							<select name="VerificationStatus" id="VerificationStatus" size="1" class="data-entry-select">
								<option value=""></option>
								<cfloop query="ctVerificationStatus">
									<option value="#VerificationStatus#">#VerificationStatus#</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12 col-md-3 px-4 px-md-5 py-3">
							<input type="checkbox" name="onlyShared" id="onlyShared" class="form-check-input">
							<label for="onlyShared" class="form-check-label mt3px small95">Shared Localities Only</label>
						</div>
						<div class="col-12 col-md-3 my-1">
							<label for="GeorefMethod" class="data-entry-label">GeorefMethod</label>
							<select name="GeorefMethod" id="GeorefMethod" size="1" class="data-entry-select">
								<option value=""></option>
								<cfloop query="ctGeorefMethod">
									<option value="#GeorefMethod#">#GeorefMethod#</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12 col-md-3 my-1">
							<label class="data-entry-label">Geolocate Precision</label>
							<select name="geolocate_precision" id="geolocate_precision" size="1" class="data-entry-select">
								<option value="" SELECTED></option>
								<option value="high" >high</option>
								<option value="medium" >medium</option>
								<option value="low" >low</option>
							</select>
						</div>
					</div>
					<div class="form-row mx-0 px-3 my-2">
						<div class="col-12 col-md-4 pl-0 my-1">
							<label for="coordinateDeterminer" class="data-entry-label">Coordinate Determiner</label>
							<input type="text" name="coordinateDeterminer" id="coordinateDeterminer" class="data-entry-input">
						</div>
						<div class="col-12 col-md-4 my-1">
							<label class="data-entry-label">Geolocate Score</label>
							<select name="gs_comparator" id="gs_comparator" size="1" class="data-entry-select">
								<option value="=" SELECTED>=</option>
								<option value="<" ><</option>
								<option value=">" >></option>
								<option value="between" >between</option>
							</select>
						</div>
						<div class="col-12 col-md-2 my-1">
							<label class="data-entry-label">Min</label>
							<input type="text" name="geolocate_score" size="3" id="geolocate_score" class="data-entry-input">
						</div>
						<div class="col-12 col-md-2 my-1">
							<label class="data-entry-label">Max</label>
							<input type="text" name="geolocate_score2" size="3" id="geolocate_score2" class="data-entry-input">
						</div>
					</div>
				</div><!--- end georefDetail --->
			</div><!--- end locDetail --->
			</div>
		</div>
	</cfif>
			
	<!----------------------------------- Collecting Event ----------------------------------------------------------->
	<cfif #showEvent# is 1>
		<div class="row mx-0 mb-0"> 
			<div class="col-12 px-0 mt-0">
				<div class="jqx-widget-header border-bottom px-4 py-1">
					<h2 class="h4 text-dark mb-0">Collecting Event</h2>
				</div>
				<cfif listFind(searchPrefList,"EventDetail") EQ 0>
					<cfset eventDetailStyle="display:none;">
					<cfset toggleTo = "1">
					<cfset eventButton = "More Fields">
				<cfelse>
					<cfset eventDetailStyle="">
					<cfset toggleTo = "0">
					<cfset eventButton = "Fewer Fields">
				</cfif> 
				<div class="form-row px-3 my-2">
					<div class="col-12 col-md-8">
						<label for="verbatim_locality" class="data-entry-label">Verbatim Locality</label>
						<input type="text" name="verbatim_locality" id="verbatim_locality" size="75" class="data-entry-input">
					</div>
					<div class="col-12 col-md-2">
						<label for="collecting_event_id" class="data-entry-label">Collecting Event ID</label>
						<input type="text" name="collecting_event_id" id="collecting_event_id" class="data-entry-input" >
					</div>
					<div class="col-12 col-md-2">
						<label for="eventDetailCtl" class="data-entry-label d-sm-none d-md-inline float-left" style="color: transparent;">Collecting Event</label> 
						<button type="button" id="eventDetailCtl" class="btn btn-xs btn-secondary" onclick="toggleEventDetail(#toggleTo#);">#eventButton#</button>
					</div>
					<div class="col-12 col-md-6">
						<label for="verbatimdepth" class="data-entry-label">Verbatim Depth</label>
						<input type="text" name="verbatimdepth" id="verbatimdepth" size="75" class="data-entry-input">
					</div>
					<div class="col-12 col-md-6">
						<label for="verbatimelevation" class="data-entry-label">Verbatim Elevation</label>
						<input type="text" name="verbatimelevation" id="verbatimelevation" size="75" class="data-entry-input">
					</div>
				</div>
				<div class="form-row px-3 my-2">
					<div class="col-12 col-md-1">
						<label for="began_date" class="data-entry-label">Began Date</label>
						<select name="begDateOper" id="begDateOper" size="1" class="data-entry-select" aria-label="operator for began date">
							<option value="=">is</option>
							<option value="<">before</option>
							<option value=">">after</option>
						</select>
					</div>
					<div class="col-12 col-md-3 pr-1">
						<span class="data-entry-label">&nbsp</span>
						<input type="text" name="began_date" id="began_date" class="data-entry-input">
					</div>
					<div class="col-12 col-md-1">
						<label for="ended_date" class="data-entry-label">End Date</label>
						<select name="endDateOper" id="endDateOper" size="1" class="data-entry-select" aria-label="operator for end date">
							<option value="=">is</option>
							<option value="<">before</option>
							<option value=">">after</option>
						</select>
					</div>
					<div class="col-12 col-md-3">
						<span class="data-entry-label">&nbsp</span>
						<input type="text" name="ended_date" id="ended_date" class="data-entry-input">
					</div>
					<div class="col-12 col-md-4">
						<label for="verbatim_date" class="data-entry-label">Verbatim Date</label>
						<input type="text" name="verbatim_date" id="verbatim_date" class="data-entry-input">
					</div>
				</div>
				<div id="eventDetail" style="#eventDetailStyle#" >
					<div class="form-row px-3 my-2">
						<div class="col-12 col-md-3">
							<label for="verbatimCoordinates" class="data-entry-label">Verbatim Coordinates</label>
							<input type="text" name="verbatimCoordinates" id="verbatimCoordinates" class="data-entry-input">
						</div>
						<div class="col-12 col-md-3">
							<label for="verbatimCoordinateSystem" class="data-entry-label">Verbatim Coordinate System</label>
							<input type="text" name="verbatimCoordinateSystem" id="verbatimCoordinateSystem" class="data-entry-input">
						</div>
						<div class="col-12 col-md-3">
							<label for="verbatimSRS" class="data-entry-label">Verbatim SRS (datum)</label>
							<input type="text" name="verbatimSRS" id="verbatimSRS" class="data-entry-input">
						</div>
						<div class="col-12 col-md-3">
							<label for="collecting_method" class="data-entry-label">Collecting Method</label>
							<input type="text" name="collecting_method" id="collecting_method" class="data-entry-input">
						</div>
					</div>
					<div class="form-row px-3 my-2">
						<div class="col-12 col-md-4">
							<label for="habitat_desc" class="data-entry-label">Habitat</label>
							<input type="text" name="habitat_desc" id="habitat_desc" class="data-entry-input">
						</div>
						<div class="col-12 col-md-4">
							<label for="collecting_source" class="data-entry-label">Collecting Source</label>
							<select name="collecting_source" id="collecting_source" size="1" class="data-entry-select">
								<option value=""></option>
								<cfloop query="ctCollectingSource">
									<option value="#ctCollectingSource.collecting_source#">#ctCollectingSource.collecting_source#</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12 col-md-4">
							<label for="coll_event_remarks" class="data-entry-label">Collecting Event Remarks</label>
							<input type="text" name="coll_event_remarks" id="coll_event_remarks" class="data-entry-input">
						</div>
					</div>
				</div>
			</div>
		</div>
	</cfif>

	<!---------------   Buttons ------------------------------------------------>

	<div class="col-12"> 
		<div class="container-lg mt-0 mb-3">
			<div class="row mx-0 mb-3"> 
				<div class="col-12 col-md-2 px-0">
					<div class="form-check">
					  <input class="form-check-input" name="accentInsensitive" id="accentInsensitive" value="1" type="checkbox"/>
					  <label class="form-check-label mt3px small" for="accentInsenstive">Accent Insensitive?</label>
					</div>
				</div>

				<div class="col-12 col-md-6 px-0 pt-3 pt-md-0">
					<input type="submit" value="Search" aria-label="execute a search with the current search form parameters"
						class="btn btn-xs btn-primary px-2 px-xl-3">
					<input type="reset" value="Clear Form" aria-label="reset form values to those on initial page load"
						class="btn btn-xs btn-warning ml-2">
					<cfif len(newSearchTarget) GT 0>
						<button type="button" class="btn btn-xs btn-warning mr-2 my-1" aria-label="Start a new taxon search with a clear page" onclick="window.location.href='#Application.serverRootUrl##encodeForHTML(newSearchTarget)#';">New Search</button>
					</cfif>
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
				$("##georefDetailCtl").attr('onCLick','toggleGeorefDetail(1)').html('Show Georef Fields');
			} else {
				$("##georefDetail").show();
				$("##georefDetailCtl").attr('onCLick','toggleGeorefDetail(0)').html('Hide Georef Fields');
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
</div>
</cfoutput>
