<cfset jquery11=true>
<cfinclude template="includes/_header.cfm">
<cf_customizeIFrame>
<cfoutput>
<script language="javascript" type="text/javascript">
	jQuery(document).ready(function() {
		$("##began_date").datepicker({dateFormat: "yy-mm-dd",showOn: "button",
			buttonImage: "images/cal_icon.png",
			buttonImageOnly: true });
		$("##ended_date").datepicker({dateFormat: "yy-mm-dd",showOn: "button",
			buttonImage: "images/cal_icon.png",
			buttonImageOnly: true });
            $(".ui-datepicker-trigger").css("margin-bottom","-7px");
        $("input[id='wktFile'").change(function(){
	    	if ($("##wktPolygon").val().length > 1)
	    		{var r=confirm('This lat/long has an error polygon. Do you wish to overwrite?');}
	    	else
	    		{r=true;}

	    	if (r==true){

				    var url = $(this).val();
				    var ext = url.substring(url.lastIndexOf('.') + 1).toLowerCase();
				    var file = $(this).prop('files')[0];
				    console.log(file.filename);
				    if ($(this).prop('files') && $(this).prop('files')[0]&& (ext == "wkt"))
				     {
				        var reader = new FileReader();
				        reader.onload = function (e) {
				        	var myRE = new RegExp(/(MULTI)?POLYGON\s*\(\s*(\(\s*(?<X>\-?\d+(:?\.\d+)?)\s+(?<Y>\-?\d+(:?\.\d+)?)(?:\s*,\s*\-?\d+(:?\.\d+)?\s+\-?\d+(:?\.\d+)?)*\s*,\s*\k<X>\s+\k<Y>\s*\))(\s*,\s*\(\s*(?<XH>\-?\d+(:?\.\d+)?)\s+(?<YH>\-?\d+(:?\.\d+)?)(?:\s*,\s*\-?\d+(:?\.\d+)?\s+\-?\d+(:?\.\d+)?)*\s*,\s*\k<XH>\s+\k<YH>\s*\))*\s*\)/);
				           if (myRE.test(e.target.result) == true){
				           $("##wktPolygon").val(e.target.result);
				           	alert("Polygon loaded. This will not be saved to the database until you Save Changes");}
				           else
				           {alert("This file does not contain a valid WKT polygon.");
				           	$(this).val('');return false;}
				        }
				       reader.readAsText($(this).prop('files')[0]);

				    }
				    else
				    {
				      $(this).val('');return false;
				    }
	    		}
	    		else
	    		{$(this).val('');return false;}
		  });

	});
</script>
<script>
   /** getLowestGeography
    * find the lowest ranking geographic entity name on a geography form,
	 * note, does not include quad as one of the ranks
    * @return the value of the lowest rank filled in on the form.
    */
   function getLowestGeography() {
      var result = "";
      if ($('##island').val()!="") {
         result = $('##island').val();
      } else if ($('##island_group').val()!="") {
         result = $('##island_group').val();
      } else if ($('##feature').val()!="") {
         result = $('##feature').val();
      } else if ($('##county').val()!="") {
         result = $('##county').val();
      } else if ($('##state_prov').val()!="") {
         result = $('##state_prov').val();
      } else if ($('##country').val()!="") {
         result = $('##country').val();
      } else if ($('##water_feature').val()!="") {
         result = $('##water_feature').val();
      } else if ($('##sea').val()!="") {
         result = $('##sea').val();
      } else if ($('##ocean_subregion').val()!="") {
         result = $('##ocean_subregion').val();
      } else if ($('##ocean_region').val()!="") {
         result = $('##ocean_region').val();
      } else if ($('##continent_ocean').val()!="") {
         result = $('##continent_ocean').val();
      }
      return result;
   }
</script>
<!--- see if action is duplicated --->
<cfif action contains ",">
	<cfset i=1>
	<cfloop list="#action#" delimiters="," index="a">
		<cfif i is 1>
			<cfset firstAction = a>
		<cfelse>
			<cfif a neq firstAction>
				An error has occured! Multiple Action in Locality. Please submit a bug report.
				<cfabort>
			</cfif>
		</cfif>
	</cfloop>
	<cfset action = firstAction>
</cfif>
<cfif isdefined("collection_object_id") AND collection_object_id gt 0 AND action is "nothing">
	<!--- probably got here from SpecimenDetail, make sure we're in a frame --->
	<script>
		var thePar = parent.location.href;
		var isFrame = thePar.indexOf('Locality.cfm');
		if (isFrame == -1) {
			// we're in a frame, action is NOTHING, we have a collection_object_id; redirect to
			// get a collecting_event_id
			//alert('in a frame');
			document.location='Locality.cfm?action=findCollEventIdForSpecDetail&collection_object_id=#collection_object_id#';
		}
	</script>
</cfif>
<cfif action is "findCollEventIdForSpecDetail">
	<!--- get a collecting event ID and relocate to editCollEvnt --->
	<cfquery name="ceid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select collecting_event_id from cataloged_item where
		collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
	</cfquery>
	<cflocation url="Locality.cfm?action=editCollEvnt&collecting_event_id=#ceid.collecting_event_id#">
</cfif>
</cfoutput>
<cfif not isdefined("collection_object_id")>
	<cfset collection_object_id=-1>
</cfif>
<cfif not isdefined("anchor")>
	<cfset anchor="">
</cfif>
<cfif not isdefined("include_counts")>
	<cfset include_counts=0>
</cfif>
<!--------------------------- Code-table queries -------------------------------------------------->
<cfquery name="ctContinentOcean" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	select continent_ocean from ctcontinent order by continent_ocean
</cfquery>
<cfquery name="ctOceanRegion" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,0,30)#" >
	select ocean_region from ctoceanregion order by ocean_region
</cfquery>
<cfquery name="ctIslandGroup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,0,30)#">
	select island_group from ctisland_group order by island_group
</cfquery>
<cfquery name="ctElevUnit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	select orig_elev_units from ctorig_elev_units order by orig_elev_units
</cfquery>
<cfquery name="ctCollecting_Source" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	select collecting_source from ctCollecting_Source order by collecting_source
</cfquery>
<cfquery name="ctFeature" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,0,30)#">
	select distinct(feature) from ctfeature order by feature
</cfquery>
<cfquery name="ctWater_Feature" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,0,30)#">
	select distinct(water_feature) from ctwater_feature order by water_feature
</cfquery>
	<cfquery name="ctGeorefMethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	select georefMethod from ctgeorefmethod order by georefMethod
</cfquery>
<cfquery name="ctVerificationStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	select VerificationStatus from ctVerificationStatus order by VerificationStatus
</cfquery>
<cfquery name="ctSovereignNation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	select sovereign_nation from ctsovereign_nation order by sovereign_nation
</cfquery>
<cfquery name="ctguid_type_highergeography" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select guid_type, placeholder, pattern_regex, resolver_regex, resolver_replacement, search_uri
   from ctguid_type
   where applies_to like '%geog_auth_rec.highergeographyid%'
</cfquery>
<cfquery name="colEventNumSeries" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select coll_event_num_series_id, number_series, pattern, remarks, collector_agent_id,
		CASE collector_agent_id WHEN null THEN '[No Agent]' ELSE mczbase.get_agentnameoftype(collector_agent_id) END as collector_agent
	from coll_event_num_series
	order by number_series, mczbase.get_agentnameoftype(collector_agent_id)
</cfquery>

<!---------------------------------------------------------------------------------------------------->
<cfif action is "nothing">
<cfoutput>
<cfset title="Manage Localities">
<table border>
	<tr>
		<td>Higher Geography</td>
		<td>
			<form name="nothing" method="post" action="Locality.cfm">
				<input type="hidden" name="Action" value="findHG">
				<input type="submit" value="Find" class="lnkBtn">
			</form>
		</td>
		<td>
			<form name="nothing" method="post" action="Locality.cfm">
				<input type="hidden" name="Action" value="newHG">
				<input type="submit" value="New Higher Geog" class="insBtn">
			</form>
		</td>
		<td>
			<!---<a href="javascript:void(0);" onClick="getDocs('higher_geography')"><img src="/images/what.gif" border="0"></a>--->
			<span class="infoLink" onclick="getDocs('higher_geography');">Define</span>
		</td>
	</tr>
	<tr>
		<td>Localities</td>
		<td>
			<form name="nothing" method="post" action="Locality.cfm">
				<input type="hidden" name="Action" value="findLO">
				<input type="submit" value="Find" class="lnkBtn">
			</form>
		</td>
		<td>
			<form name="nothing" method="post" action="Locality.cfm">
				<input type="hidden" name="Action" value="newLocality">
				<input type="submit" value="New Locality" class="insBtn">
			</form>
		</td>
		<td>
			<span class="infoLink" onclick="getDocs('locality');">Define</span>
		</td>
	</tr>
	<tr>
		<td>Collecting Events</td>
		<td>
			<form name="nothing" method="post" action="Locality.cfm">
				<input type="hidden" name="Action" value="findCO">
				<input type="submit" value="Find" class="lnkBtn">
			</form>
		</td>
		<td>(Find and clone to create new)</td>
		<td>
			<span class="infoLink" onclick="getDocs('collecting_event');">Define</span>
		</td>
	</tr>
</table>
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "findHG">
	<cfoutput>
        <div style="width: 52em; margin:0 auto; padding: 1em 0 3em 0;">
            <cfset title="Find Geography">
		<h2 class="wikilink">Find Higher Geography:</h2>
		<form name="getCol" method="post" action="Locality.cfm">
		    <input type="hidden" name="Action" value="findGeog">
			<cfinclude template="/includes/frmFindLocation_guts.cfm">
		</form>
            </div>
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "newHG">
<cfoutput>
<cfif len(session.roles) gt 0 and FindNoCase("manage_geography",session.roles) NEQ 0>
       <div style="width: 40em; margin:0 auto; padding: 1em 0 3em 0;">
	<cfset title="Create Higher Geography">
        <h2 class="wikilink">Create Higher Geography:</h2>
	<cfform name="getHG" method="post" action="Locality.cfm">
		<input type="hidden" name="Action" value="makeGeog">
		<table>
			<tr>
				<td align="right">Continent or Ocean:</td>
				<td>
				<cfif isdefined("continent_ocean")>
					<cfset thisContinentOcean = continent_ocean>
				<cfelse>
					<cfset thisContinentOcean = "">
				</cfif>
				<select name="continent_ocean" id="continent_ocean" class="geoginput">
					<option value=""></option>
						<cfloop query="ctContinentOcean">
							<cfif thisContinentOcean is ctContinentOcean.continent_ocean><cfset sel='selected="selected"'><cfelse><cfset sel=""></cfif>
							<option #sel# value="#ctContinentOcean.continent_ocean#">#ctContinentOcean.continent_ocean#</option>
						</cfloop>
				</select>
				</td>
			</tr>
			<tr>
				<td align="right">Ocean Region:</td>
				<td>
				<cfif isdefined("ocean_region")>
					<cfset thisOceanRegion = ocean_region>
				<cfelse>
					<cfset thisOceanRegion = "">
				</cfif>
				<select name="ocean_region" id="ocean_region" class="geoginput" >
					<option value=""></option>
						<cfloop query="ctOceanRegion">
							<cfif thisOceanRegion is ctOceanRegion.ocean_region><cfset sel='selected="selected"'><cfelse><cfset sel=""></cfif>
							<option #sel# value = "#ctOceanRegion.ocean_region#">#ctOceanRegion.ocean_region#</option>
						</cfloop>
				</select>
				</td>
				</td>
			</tr>
			<tr>
				<td align="right">Ocean Subregion:</td>
				<td>
					<cfif isdefined("ocean_subregion")><cfset val= ocean_subregion><cfelse><cfset val=""></cfif>
					<input type="text" name="ocean_subregion" id="ocean_subregion" value="#val#" class="geoginput" >
				</td>
			</tr>
			<tr>
				<td align="right">Sea:</td>
				<td>
					<cfif isdefined("sea")><cfset val=sea><cfelse><cfset val=""></cfif>
					<input type="text" name="sea" id="sea" value="#val#" class="geoginput">
				</td>
			</tr>
			<tr>
				<td align="right">Water Feature:</td>
				<td>
				<cfif isdefined("water_feature")>
					<cfset thisWater_Feature = water_feature>
				<cfelse>
					<cfset thisWater_Feature = "">
				</cfif>
				<select name="water_feature" id="water_feature" class="geoginput">
					<option value=""></option>
						<cfloop query="ctWater_Feature">
							<option
								<cfif thisWater_Feature is ctWater_Feature.water_feature> selected="selected" </cfif>
								value = "#ctWater_Feature.water_feature#">#ctWater_Feature.water_feature#</option>
						</cfloop>
				</select>
			</td>
			</tr>
			<tr>
				<td align="right">Country:</td>
				<td>
					<cfif isdefined("country")><cfset val=country><cfelse><cfset val=""></cfif>
					<input type="text" name="country" value = "#val#" id="country" class="geoginput" >
				</td>
			</tr>
			<tr>
				<td align="right">State:</td>
				<td>
					<cfif isdefined("state_prov")><cfset val=state_prov><cfelse><cfset val=""></cfif>
					<input type="text" name="state_prov" value = "#val#" id="state_prov" class="geoginput" >
				</td>
			</tr>
			<tr>
				<td align="right">County:</td>
				<td>
					<cfif isdefined("county")><cfset val=county><cfelse><cfset val=""></cfif>
					<input type="text" name="county" value="#val#" id="county" class="geoginput">
				</td>
			</tr>
			<tr>
				<td align="right">Quad:</td>
				<td>
					<cfif isdefined("quad")><cfset val=quad><cfelse><cfset val=""></cfif>
					<input type="text" name="quad" value="#val#" id="quad" class="geoginput" >
				</td>
			</tr>
			<tr>
				<td align="right">Land Feature:</td>
				<td>
				<cfif isdefined("feature")>
					<cfset thisFeature = feature>
				<cfelse>
					<cfset thisFeature = "">
				</cfif>
				<select name="feature" id="feature" class="geoginput" >
					<option value=""></option>
						<cfloop query="ctFeature">
							<option
								<cfif thisFeature is ctFeature.feature> selected="selected" </cfif>
								value = "#ctFeature.feature#">#ctFeature.feature#</option>
						</cfloop>
				</select>
			</td>
			</tr>
			<tr>
				<td align="right">Island Group:</td>
				<td><select name="island_group" size="1" id="island_group" class="geoginput">
				<option value=""></option>
				<cfloop query="ctIslandGroup">
					<option
						<cfif isdefined("islandgroup")>
							<cfif ctIslandGroup.island_group is islandgroup> selected="selected" </cfif>
					</cfif>value="#ctIslandGroup.island_group#">#ctIslandGroup.island_group#
					</option>
				</cfloop>
			</select></td>
			</tr>
			<tr>
				<td align="right">Island:</td>
				<td>
					<cfif isdefined("island")><cfset val=island><cfelse><cfset val=""></cfif>
					<input type="text" name="island" value="#val#" size="50" id="island" class="geoginput">
				</td>
			</tr>
			<tr>
				<td align="right">Valid?</td>
				<td>
					<select name="valid_catalog_term_fg" class="reqdClr">
						<option value=""></option>
						<option value="1">yes</option>
						<option value="0">no</option>
					</select>
				</td>
			</tr>
			<tr>
				<td align="right">Source Authority:</td>
				<td>
					<input name="source_authority" id="source_authority" class="reqdClr">
				</td>
			</tr>
			<tr>
				<td colspan="2" class="detailCell">
					<cfset highergeographyid_guid_type="">
					<cfset highergeographyid="">
					<label for="highergeographyid">GUID for Higher Geography (dwc:highergeographyID)</label>
					<cfset pattern = "">
					<cfset placeholder = "">
					<cfset regex = "">
					<cfset replacement = "">
					<cfset searchlink = "" >
					<cfset searchtext = "" >
					<cfset searchclass = "" >
					<cfloop query="ctguid_type_highergeography">
	 					<cfif ctguid_type_highergeography.recordcount EQ 1 >
							<cfset searchtext = "Find GUID" >
							<cfset searchclass = 'class="smallBtn findGuidButton external"' >
						</cfif>
					</cfloop>
					<select name="highergeographyid_guid_type" id="highergeographyid_guid_type" size="1">
						<cfif searchtext EQ "">
							<option value=""></option>
						</cfif>
						<cfloop query="ctguid_type_highergeography">
							<cfset sel="">
	 							<cfif ctguid_type_highergeography.recordcount EQ 1 >
									<cfset sel="selected='selected'">
									<cfset placeholder = "#ctguid_type_highergeography.placeholder#">
									<cfset pattern = "#ctguid_type_highergeography.pattern_regex#">
									<cfset regex = "#ctguid_type_highergeography.resolver_regex#">
									<cfset replacement = "#ctguid_type_highergeography.resolver_replacement#">
								</cfif>
							<option #sel# value="#ctguid_type_highergeography.guid_type#">#ctguid_type_highergeography.guid_type#</option>
						</cfloop>
					</select>
					<a href="#searchlink#" id="highergeographyid_search" target="_blank" #searchclass# >#searchtext#</a>
					<input size="56" name="highergeographyid" id="highergeographyid" value="" placeholder="#placeholder#" pattern="#pattern#" title="Enter a guid in the form #placeholder#">
					<cfset link = highergeographyid>
					<a id="highergeographyid_link" href="#link#" target="_blank" class="hints">#highergeographyid#</a>
					<script>
						$(document).ready(function () {
							if ($('##highergeographyid').val().length > 0) {
								$('##highergeographyid').hide();
							}
							$('##highergeographyid_search').click(function (evt) {
								switchGuidEditToFind('highergeographyid','highergeographyid_search','highergeographyid_link',evt);
							});
							$('##highergeographyid_guid_type').change(function () {
								// On selecting a guid_type, remove an existing guid value.
								$('##highergeographyid').val("");
								$('##highergeographyid').show();
								// On selecting a guid_type, change the pattern.
								getGuidTypeInfo($('##highergeographyid_guid_type').val(), 'highergeographyid', 'highergeographyid_link','highergeographyid_search',getLowestGeography());
							});
							$('##highergeographyid').blur( function () {
								// On loss of focus for input, validate against the regex, update link
								getGuidTypeInfo($('##highergeographyid_guid_type').val(), 'highergeographyid', 'highergeographyid_link','highergeographyid_search',getLowestGeography());
							});
							$('.geoginput').change(function () {
								// On changing any geography input field name, update search.
								getGuidTypeInfo($('##highergeographyid_guid_type').val(), 'highergeographyid', 'highergeographyid_link','highergeographyid_search',getLowestGeography());
							});
						});
					</script>
				</td>
			</tr>
			<tr>
			<td colspan="2" style="padding: 1em 0 2em 150px;">
				<input type="submit" value="Create" class="insBtn">
				<input type="button" value="Quit" class="qutBtn" onclick="document.location='Locality.cfm';">
			</td>
		</tr>
	</table>
	</cfform>
</div>
<cfelse>
You do not have permission to create Higher Geographies
</cfif>
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "findLO">
	<cfoutput>
           <div style="width: 52em; margin:0 auto; padding: 1em 0 3em 0;">
		<cfset title="Find Locality">
		<cfset showLocality=1>
		  <h2 class="wikilink">Search Locality <img src="/images/info_i_2.gif" onClick="getMCZDocs('Searching_for_Localities')" class="likeLink" alt="[help]"/></h2>
	    <form name="getCol" method="post" action="Locality.cfm">
			<input type="hidden" name="Action" value="findLocality">
			<cfinclude template="/includes/frmFindLocation_guts.cfm">
	     </form>
            </div>
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "findCO">
<cfoutput>
	<cfset title="Find Collecting Events">
	<cfset showLocality=1>
	<cfset showEvent=1>
        <div style="width: 52em; margin:0 auto; padding: 1em 0 3em 0;">
	<h2 class="wikilink">Search Collecting Events:</h2>
    <form name="getCol" method="post" action="Locality.cfm">
		<input type="hidden" name="Action" value="findCollEvent">
		<cfinclude template="/includes/frmFindLocation_guts.cfm">
     </form>
         </div>
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "editGeog">
<cfset title = "Edit Geography">
	<cfoutput>
   <div style="margin:0 auto; padding: 1em 1em 3em 1em;">
	<h2 class="wikilink">Edit Higher Geography:</h2>
		<cfquery name="geogDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select * from geog_auth_rec
			where geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
		</cfquery>

		<cfquery name="localities" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select count(*) c from locality
			where geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
		</cfquery>
		<cfquery name="collecting_events" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select count(*) c from locality,collecting_event
			where
			locality.locality_id = collecting_event.locality_id AND
			geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
		</cfquery>
		<cfquery name="specimen" datasource="uam_god">
			select
				collection.collection_id,
				collection.collection,
				count(*) c
			from
				locality,
				collecting_event,
				cataloged_item,
				collection
			where
				locality.locality_id = collecting_event.locality_id AND
				collecting_event.collecting_event_id = cataloged_item.collecting_event_id AND
			 	cataloged_item.collection_id=collection.collection_id AND
				geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
			 group by
			 	collection.collection_id,
				collection.collection
			order by
				collection.collection
		</cfquery>
		<div style="border:2px solid blue; background-color:red;padding: 10px 20px;">
			Altering this record will update:
			<ul class="bulletlist">
				<li>#localities.c# localities</li>
				<li>#collecting_events.c# collecting events</li>
				<cfloop query="specimen">
					<li>
						<a href="/SpecimenResults.cfm?geog_auth_rec_id=#geog_auth_rec_id#&collection_id=#specimen.collection_id#">
							#specimen.c# #collection# specimens
						</a>
					</li>
				</cfloop>
			</ul>
		</div>
    </cfoutput>
	<cfoutput query="geogDetails">
		<h3 class="wikilink"><em>#higher_geog#</h3>
        <cfform name="getHG" method="post" action="Locality.cfm">
	        <input name="Action" type="hidden" value="saveGeogEdits">
            <input type="hidden" name="geog_auth_rec_id" value="#geog_auth_rec_id#">
            <table>
				<tr>
	                <td>
						<label for="continent_ocean" class="likeLink" onClick="getDocs('higher_geography','continent_ocean')">
							Continent or Ocean
						</label>
				<select name="continent_ocean" style="width: 15em;" id="continent_ocean" class="geoginput" >
				<cfif isdefined("continent_ocean")>
                                     <cfif continent_ocean is not ''>
					<option value="#continent_ocean#" selected="selected">#continent_ocean#</option>
                                     </cfif>
				</cfif>
					<option value=""></option>
						<cfloop query="ctContinentOcean">
							<option value = "#ctContinentOcean.continent_ocean#">#ctContinentOcean.continent_ocean#</option>
						</cfloop>
				</select>
                                        </td>
					<td>
						<label for="ocean_region" class="likeLink"  onClick="getMCZbaseDocs('Ocean_Regions_%26_Subregions','')" >
                                                       Ocean Region:
						</label>
				<select name="ocean_region" style="width: 15em;" id="ocean_region" class="geoginput">
				<cfif isdefined("ocean_region")>
                                     <cfif ocean_region is not ''>
					<option value="#ocean_region#" selected="selected">#ocean_region#</option>
                                     </cfif>
				</cfif>
					<option value=""></option>
						<cfloop query="ctOceanRegion">
							<option value = "#ctOceanRegion.ocean_region#">#ctOceanRegion.ocean_region#</option>
						</cfloop>
				</select>
                                        </td>
					<td>
						<label for="ocean_subregion">
							Ocean Subregion
						</label>
						<input type="text" name="ocean_subregion" id="ocean_subregion" value="#ocean_subregion#" class="geoginput">
					</td>
					<td>
						<label for="sea" class="likeLink" onClick="getDocs('higher_geography','sea')">
							Sea
						</label>
						<input type="text" name="sea" id="sea" value="#sea#" class="geoginput">
					</td>
					<td>
						<cfif isdefined("water_feature")>
							<cfset thisWater_Feature = water_feature>
						<cfelse>
							<cfset thisWater_Feature = "">
						</cfif>
						<label for="water_feature" class="likeLink" onClick="getDocs('higher_geography','water_feature')">
							Water Feature
						</label>
						<select name="water_feature" id="water_feature" style="width: 15em;" class="geoginput">
							<option value=""></option>
							<cfloop query="ctWater_Feature">
								<option	<cfif thisWater_Feature is ctWater_Feature.water_feature> selected="selected" </cfif>
									value = "#ctWater_Feature.water_feature#">#ctWater_Feature.water_feature#</option>
							</cfloop>
						</select>
					</td>
				</tr>
				<tr>
					<td>
						<label for="country" class="likeLink" onClick="getDocs('higher_geography','country')">
							Country
						</label>
						<input type="text" name="country" id="country" value="#country#" class="geoginput">
					</td>
					<td>
						<label for="state_prov" class="likeLink" onClick="getDocs('higher_geography','state_province')">
							State/Province
						</label>
						<input type="text" name="state_prov" id="state_prov" value="#state_prov#" class="geoginput">
					</td>
					<td>
						<label for="county" class="likeLink" onClick="getDocs('higher_geography','county')">
							County
						</label>
						<input type="text" name="county" id="county" value="#county#" class="geoginput">
					</td>
                	<td>
						<label for="quad" class="likeLink" onClick="getDocs('higher_geography','map_name')">
							Quad
						</label>
						<input type="text" name="quad" id="quad" value="#quad#" class="geoginput">
					</td>
					<td>
						<cfif isdefined("feature")>
							<cfset thisFeature = feature>
						<cfelse>
							<cfset thisFeature = "">
						</cfif>
						<label for="feature" class="likeLink" onClick="getDocs('higher_geography','feature')">
						Land Feature
						</label>
						<select name="feature" id="feature" class="geoginput">
							<option value=""></option>
							<cfloop query="ctFeature">
								<option	<cfif thisFeature is ctFeature.feature> selected="selected" </cfif>
									value = "#ctFeature.feature#">#ctFeature.feature#</option>
							</cfloop>
						</select>
					</td>
				</tr>
				<tr>
					<td colspan="2">
						<label for="island_group" class="likeLink" onClick="getDocs('higher_geography','island_group')">
							Island Group
						</label>
						<select name="island_group" id="island_group" size="1" style="width: 28em;" class="geoginput">
		                	<option value=""></option>
		                    <cfloop query="ctIslandGroup">
		                      <option
							<cfif geogdetails.island_group is ctislandgroup.island_group> selected="selected" </cfif>value="#ctIslandGroup.island_group#">#ctIslandGroup.island_group#</option>
		                    </cfloop>
		                  </select>
					</td>
					<td colspan="2">
						<label for="island" class="likeLink" onClick="getDocs('higher_geography','island')">
							Island
						</label>
						<input type="text" name="island" id="island" value="#island#" size="50" class="geoginput">
					</td>
	            <td>
					</td>
				</tr>
				<tr>
					<td colspan="3">
						<label for = "wktPolygon">Polygon<label>
						<input type="text" name="wktPolygon" value="#WKT_POLYGON#" id = "wktPolygon" size="100" readonly>
					</td>
					<td colspan="1">
						<label for="wktFile">Load Polygon from WKT file</label>
						<input type="file"
								id="wktFile"
								name="wktFile"
								accept=".wkt"
								>
					</td>
				</tr>
				<tr>
	                <td colspan="2">
						<label for="source_authority">
							Authority
						</label>
						<input name="source_authority" id="source_authority" class="reqdClr" size="45" style="margin-right: 10px;" value="#source_authority#">
					</td>
	                <td>
						<label for="valid_catalog_term_fg">
							Valid?
						</label>
						<select name="valid_catalog_term_fg" id="valid_catalog_term_fg" class="reqdClr">
		                    <option value=""></option>
		                    <option <cfif geogdetails.valid_catalog_term_fg is "1"> selected="selected" </cfif>value="1">yes</option>
		                    <option <cfif geogdetails.valid_catalog_term_fg is "0"> selected="selected" </cfif>value="0">no</option>
		                  </select>
					</td>
					<td colspan="2" class="detailCell">
						<label for="highergeographyid">GUID for Higher Geography(dwc:highergeographyID)</label>
						<cfset pattern = "">
						<cfset placeholder = "">
						<cfset regex = "">
						<cfset replacement = "">
						<cfset searchlink = "" >
						<cfset searchtext = "" >
						<cfset searchclass = "" >
						<cfloop query="ctguid_type_highergeography">
		 					<cfif geogDetails.highergeographyid_guid_type is ctguid_type_highergeography.guid_type OR ctguid_type_highergeography.recordcount EQ 1 >
								<cfset searchlink = ctguid_type_highergeography.search_uri & geogDetails.higher_geog >
								<cfif len(geogDetails.highergeographyid) GT 0>
									<cfset searchtext = "Edit" >
									<cfset searchclass = 'class="smallBtn editGuidButton"' >
								<cfelse>
									<cfset searchtext = "Find GUID" >
									<cfset searchclass = 'class="smallBtn findGuidButton external"' >
								</cfif>
							</cfif>
						</cfloop>
						<select name="highergeographyid_guid_type" id="highergeographyid_guid_type" size="1">
							<cfif searchtext EQ "">
								<option value=""></option>
							</cfif>
							<cfloop query="ctguid_type_highergeography">
								<cfset sel="">
		 							<cfif geogDetails.highergeographyid_guid_type is ctguid_type_highergeography.guid_type OR ctguid_type_highergeography.recordcount EQ 1 >
										<cfset sel="selected='selected'">
										<cfset placeholder = "#ctguid_type_highergeography.placeholder#">
										<cfset pattern = "#ctguid_type_highergeography.pattern_regex#">
										<cfset regex = "#ctguid_type_highergeography.resolver_regex#">
										<cfset replacement = "#ctguid_type_highergeography.resolver_replacement#">
									</cfif>
								<option #sel# value="#ctguid_type_highergeography.guid_type#">#ctguid_type_highergeography.guid_type#</option>
							</cfloop>
						</select>
						<a href="#searchlink#" id="highergeographyid_search" target="_blank" #searchclass# >#searchtext#</a>
						<input size="48" name="highergeographyid" id="highergeographyid" value="#geogDetails.highergeographyid#" placeholder="#placeholder#" pattern="#pattern#" title="Enter a guid in the form #placeholder#">
						<cfif len(regex) GT 0 >
							<cfset link = REReplace(geogDetails.highergeographyid,regex,replacement)>
						<cfelse>
							<cfset link = geogDetails.highergeographyid>
						</cfif>
						<a id="highergeographyid_link" href="#link#" target="_blank" class="hints">#geogDetails.highergeographyid#</a>
						<script>
							$(document).ready(function () {
								if ($('##highergeographyid').val().length > 0) {
									$('##highergeographyid').hide();
								}
								$('##highergeographyid_search').click(function (evt) {
									switchGuidEditToFind('highergeographyid','highergeographyid_search','highergeographyid_link',evt);
								});
								$('##highergeographyid_guid_type').change(function () {
									// On selecting a guid_type, remove an existing guid value.
									$('##highergeographyid').val("");
									$('##highergeographyid').show();
									// On selecting a guid_type, change the pattern.
									getGuidTypeInfo($('##highergeographyid_guid_type').val(), 'highergeographyid', 'highergeographyid_link','highergeographyid_search',getLowestGeography());
								});
								$('##highergeographyid').blur( function () {
									// On loss of focus for input, validate against the regex, update link
									getGuidTypeInfo($('##highergeographyid_guid_type').val(), 'highergeographyid', 'highergeographyid_link','highergeographyid_search',getLowestGeography());
								});
								$('.geoginput').change(function () {
									// On changing any geography inptu field name, update search.
									getGuidTypeInfo($('##highergeographyid_guid_type').val(), 'highergeographyid', 'highergeographyid_link','highergeographyid_search',getLowestGeography());
								});
							});
						</script>
					</td>
				</tr>
				<tr>
	                <td colspan="4" nowrap style="padding-top: 1em;">
						<cfif len(session.roles) gt 0 and FindNoCase("manage_geography",session.roles) NEQ 0>
						<input type="submit" value="Save Edits"	class="savBtn">&nbsp;
						<input type="button" value="Delete" class="delBtn"
							onClick="document.location='Locality.cfm?Action=deleteGeog&geog_auth_rec_id=#geog_auth_rec_id#';">&nbsp;
						</cfif>
						<input type="button" value="See Localities" class="lnkBtn"
							onClick="document.location='Locality.cfm?Action=findLocality&geog_auth_rec_id=#geog_auth_rec_id#';">&nbsp;
						<cfset dloc="Locality.cfm?action=newHG&continent_ocean=#continent_ocean#&ocean_region=#ocean_region#&ocean_subregion=#ocean_subregion#&country=#country#&state_prov=#state_prov#&county=#county#&quad=#quad#&feature=#feature#&water_feature=#water_feature#&island_group=#island_group#&island=#island#&sea=#sea#">
						<cfif len(session.roles) gt 0 and FindNoCase("manage_geography",session.roles) NEQ 0>
						<input type="button" value="Create Clone" class="insBtn" onclick="document.location='#dloc#';">
						</cfif>
					</td>
				</tr>
			</table>
		</cfform>
        </div>
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "editCollEvnt">
               <div class="basic_box">
<cfset title="Edit Collecting Event">
<cfoutput>

	<h2 class="wikilink">Edit Collecting Events:</h2>
      <cfquery name="locDet" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
    	select
			higher_geog,
			spec_locality,
			sovereign_nation,
			collecting_event.collecting_event_id,
			locality.locality_id,
			verbatim_locality,
			BEGAN_DATE,
			ENDED_DATE,
			VERBATIM_DATE,
			COLL_EVENT_REMARKS,
			COLLECTING_SOURCE,
			COLLECTING_METHOD,
			HABITAT_DESC,
			CASE orig_lat_long_units
					WHEN 'decimal degrees' THEN dec_lat || 'd'
					WHEN 'deg. min. sec.' THEN lat_deg || 'd ' || lat_min || 'm ' || lat_sec || 's ' || lat_dir
					WHEN 'degrees dec. minutes' THEN lat_deg || 'd ' || dec_lat_min || 'm ' || lat_dir
				END as LatitudeString,
				CASE orig_lat_long_units
					WHEN 'decimal degrees' THEN dec_long || 'd'
					WHEN'degrees dec. minutes' THEN long_deg || 'd ' || dec_long_min || 'm ' || long_dir
					WHEN 'deg. min. sec.' THEN long_deg || 'd ' || long_min || 'm ' || long_sec || 's ' || long_dir
				END as LongitudeString,
			max_error_distance,
			max_error_units,
			collecting_time,
			fish_field_number,
			VERBATIMCOORDINATES,
		    VERBATIMLATITUDE,
		    VERBATIMLONGITUDE,
		    VERBATIMCOORDINATESYSTEM,
		    VERBATIMSRS,
		    STARTDAYOFYEAR,
		    ENDDAYOFYEAR
		from
			locality
			inner join geog_auth_rec on (locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id)
			inner join collecting_event on ( locality.locality_id=collecting_event.locality_id )
			left outer join accepted_lat_long on (locality.locality_id=accepted_lat_long.locality_id)
			left outer join preferred_agent_name on (accepted_lat_long.determined_by_agent_id = preferred_agent_name.agent_id)
		where collecting_event.collecting_event_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
    </cfquery>
	<cfquery name="colEventNumbers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT number_series,
			MCZBASE.get_agentnameoftype(collector_agent_id) as collector_agent,
			coll_event_number,
			coll_event_number_id
		FROM
			coll_event_number
			left join coll_event_num_series on coll_event_number.coll_event_num_series_id = coll_event_num_series.coll_event_num_series_id
		WHERE
			coll_event_number.collecting_event_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
	</cfquery>
	<cfquery name="whatSpecs" datasource="uam_god">
	  	SELECT
	  		count(cat_num) as numOfSpecs,
	  		collection,
	  		collection.collection_id
		from
			cataloged_item,
			collection
		WHERE
			cataloged_item.collection_id=collection.collection_id and
			collecting_event_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
		GROUP BY
			collection,
	  		collection.collection_id
	</cfquery>

	<div style="border:2px solid red; font-weight:bold;padding: 1em;">
		This Collecting Event (#collecting_event_id#)
		 contains
		<cfif whatSpecs.recordcount is 0>
			no specimens. Please delete it if you don't have plans for it.
		<cfelse>
			<ul class="geol_hier" style="padding-bottom:1em;">
				<cfloop query="whatSpecs">
					<li>
						<a href="SpecimenResults.cfm?collecting_event_id=#collecting_event_id#&collection_id=#collection_id#">
							#whatSpecs.numOfSpecs# #whatSpecs.collection# specimens
						</a>
					</li>
				</cfloop>
			</ul>
		</cfif>
	</div>
	<form name="localitypick" action="Locality.cfm" method="post">
		<input type="hidden" name="Action" value="changeLocality">
    		<input type="hidden" name="locality_id" value="#locDet.locality_id#">
	 	<input type="hidden" name="collecting_event_id" value="#locDet.collecting_event_id#">
		 <cfif not isdefined("collection_object_id")>
		 	<cfset collection_object_id=-1>
		 </cfif>
	 	<input type="hidden" name="collection_object_id" value="#collection_object_id#">
		<input type="button" value="Change Locality for this Collecting Event" class="picBtn"
			onclick="document.getElementById('locDesc').style.background='red';
				document.getElementById('hiddenButton').style.visibility='visible';
				LocalityPick('locality_id','spec_locality','localitypick'); return false;" >
		<h4>Current Locality:</h4>
		<div id="locDesc" style="border:1px solid green;padding: .5em;">
            <p><span style="font-weight: 600;color: ##ff0000;width: 210px;display:inline-block;text-align:right;">HIGHER GEOGRAPHY: </span> #locDet.higher_geog#</p>
			<cfif len(locDet.LatitudeString) gt 0>
                <p><span style="font-weight: 600;color: ##ff0000; width: 210px;display:inline-block;text-align:right;">COORDINATES:</span> #locDet.LatitudeString# &nbsp;&nbsp; #locDet.LongitudeString#</p>
                <p><span style="font-weight: 600;color: ##ff0000; width: 210px;display:inline-block;text-align:right;">MAX ERROR:</span> <cfif len(locDet.max_error_distance) gt 0>
					&##177; #locDet.max_error_distance# #locDet.max_error_units#
                    </cfif></p>
			</cfif>
            <p><span style="font-weight: 600;color: ##ff0000; width: 210px; display: inline-block;text-align:right;">SPECIFIC LOCALITY:</span> #locDet.spec_locality#</p>
		</div>

		<div id="hiddenButton" style="visibility:hidden;margin-bottom: 0; padding-bottom:0;height: 18px; ">
			Picked Locality:
			<input type="text" name="spec_locality" size="50">
			<input type="submit" value="Save Change" class="savBtn">
		</div>
	</form>

	OR<br>

	<input type="button" value="Edit the current Locality" class="lnkBtn" style="margin: 1em 0;"
		onClick="document.location='editLocality.cfm?locality_id=#locDet.locality_id#'">

	<br>OR<br>

	<h3 class="wikilink">Edit this Collecting Event:</h3>
	<cfform name="locality" method="post" action="Locality.cfm">
    	<input type="hidden" name="Action" value="saveCollEventEdit">
	    <input type="hidden" name="collecting_event_id" value="#locDet.collecting_event_id#">
		<input type="hidden" name="collection_object_id" value="#collection_object_id#">
		<div style="border: 1px solid green;padding: .5em;">
        <label for="verbatim_locality">
			Verbatim Locality
		</label>
		<input type="text" name="verbatim_locality" id="verbatim_locality" value="#encodeForHTML(locDet.verbatim_locality)#" size="115">
		<table>
			<tr>
				<td><label for="verbatimCoordinates">Verbatim Coordinates (summary)<label>
						<input type="text" name="verbatimCoordinates" value="#encodeForHTML(locDet.verbatimCoordinates)#" id="verbatimCoordinates" size="115">
				</td>
            </tr>
           </table>
           <table>
           <tr>
				<td style="padding-right: 1.5em;"><label for="verbatimLatitude">Verbatim Latitude<label>
						<input type="text" name="verbatimLatitude" value="#encodeForHTML(locDet.verbatimLatitude)#" id="verbatimLatitude" size="30">
				</td>
				<td><label for="verbatimLongitude">Verbatim Longitude<label>
						<input type="text" name="verbatimLongitude" value="#encodeForHTML(locDet.verbatimLongitude)#" id="verbatimLongitude" size="30">
				</td>
			</tr>
           </table>
           <table>
			<tr>
				<td style="padding-right: 1.5em;"><label for="verbatimCoordinateSystem">Verbatim Coordinate System (e.g., decimal degrees)<label>
						<input type="text" name="verbatimCoordinateSystem" value="#encodeForHTML(locDet.verbatimCoordinateSystem)#" id="verbatimCoordinateSystem" size="50">
				</td>
				<td ><label for="verbatimSRS">Verbatim SRS (includes ellipsoid model/Datum)<label>
						<input type="text" name="verbatimSRS" value="#encodeForHTML(locDet.verbatimSRS)#" id="verbatimSRS" size="50">
				</td>
			</tr>
		</table>

		<label for="specific_locality">
			Specific Locality
		</label>
		<div id="specific_locality" style="padding: .25em 0 .5em 0;">
			#locDet.spec_locality#
		</div>
		<table>
			<tr>
				<td>
					<label for="verbatim_date">Verbatim Date</label>
					<input type="text" name="VERBATIM_DATE" id="verbatim_date" value="#encodeForHTML(locDet.VERBATIM_DATE)#" class="reqdClr">
             	</td>
			</tr>
		</table>
		<table>
			<tr>
				<td style="padding-right: 1.5em;">
					<label for="collecting_time">Collecting Time</label>
					<input type="text" name="collecting_time" id="collecting_time" value="#encodeForHTML(locDet.collecting_time)#" size="20">
				</td>
				<td>
					<label for="ich_field_number">Ich. Field Number</label>
					<input type="text" name="ich_field_number" id="ich_field_number" value="#encodeForHTML(locDet.fish_field_number)#" size="20">
				</td>
			</tr>
		</table>
		<table>
			<tr>
				<td style="padding-right: 1.5em;">
					<label for="startDayOfYear">Start Day of Year</label>
					<input type="text" name="startDayOfYear" id="startDayOfYear" value="#encodeForHTML(locDet.startDayOfYear)#" size="20">
				</td>
				<td>
					<label for="endDayOfYear">End Day of Year</label>
					<input type="text" name="endDayOfYear" id="endDayOfYear" value="#encodeForHTML(locDet.endDayOfYear)#" size="20">
				</td>
			</tr>
		</table>
		<table>
			<tr>
				<td>
					<label for="began_date">
						Began Date/Time
					</label>
					<input type="text" name="began_date" id="began_date" value="#locDet.began_date#" size="20" placeholder="YYYY-MM-DD">
				</td>
				<td>
					<label for="ended_date">
						Ended Date/Time
					</label>
					<input type="text" name="ended_date" id="ended_date" value="#locDet.ended_date#" size="20" placeholder="YYYY-MM-DD">
				</td>
			</tr>
		</table>
		<div style="border:1px solid LightGray;">
			<h3>Collector/Field Numbers (identifying collecting events)</h3>
			<!--- Current --->
			<script>
				function deleteCollEventNumber(id) {
					$('##collEventNumber_' + id ).append('Deleting...');
					$.ajax({
						url : "/localities/component/functions.cfc",
						type : "post",
						dataType : "json",
						data : {
							method: "deleteCollEventNumber",
							returnformat: "json",
							coll_event_number_id: id
						},
						success : function (data) {
							$('##collEventNumber_' + id ).html('Deleted.');
						},
						error: function(jqXHR,textStatus,error){
							$('##collEventNumber_' + id ).append('Error.');
							var message = "";
							if (error == 'timeout') {
								message = ' Server took too long to respond.';
							} else {
								message = jqXHR.responseText;
							}
							messageDialog('Error deleting collecting event number: '+message, 'Error: '+error);
						}
					});
				};
			</script>
			<ul>
			<cfloop query="colEventNumbers">
				<li><span id="collEventNumber_#coll_event_number_id#">#coll_event_number# (#number_series#, #collector_agent#) <input type="button" value="Delete" class="delBtn" onclick=" deleteCollEventNumber(#coll_event_number_id#); "></span></li>
			</cfloop>
			</ul>
			<!--- Add new --->
			<!--- TODO: Rework into dialog, along with edit dialog --->
			<cfset patternvalue = "">
			<div>
				<h3>Add</h3>
				<label for="coll_event_number_series">Collecting Event Number Series</label>
				<span>
					<select id="coll_event_number_series" name="coll_event_number_series">
						<option value=""></option>
						<cfset ifbit = "">
						<cfloop query="colEventNumSeries">
							<option value="#colEventNumSeries.coll_event_num_series_id#">#colEventNumSeries.number_series# (#colEventNumSeries.collector_agent#)</option>
							<cfset ifbit = ifbit & "if (selectedid=#colEventNumSeries.coll_event_num_series_id#) { $('##pattern_span').html('#colEventNumSeries.pattern#'); }; ">
						</cfloop>
					</select>
					<a href="/vocabularies/CollEventNumberSeries.cfm?action=new" target="_blank">Add new number series</a>
				</span>
				<!---  On change of picklist, look up the expected pattern for the collecting event number series --->
				<script>
					$( document ).ready(function() {
						$('##coll_event_number_series').change( function() { selectedid = $('##coll_event_number_series').val(); #ifbit# } );
					});
				</script>
				<label for="coll_event_number">Collector/Field Number <span id="pattern_span" style="color: Gray;">#patternvalue#</span></label>
				<input type="text" name="coll_event_number" id="coll_event_number" size=50>
			</div>
		</div>
		<label for="coll_event_remarks">Remarks</label>
		<input type="text" name="coll_event_remarks" id="coll_event_remarks" value="#encodeForHTML(locDet.COLL_EVENT_REMARKS)#" size="115">
		<table>
        <tr>
        <td style="padding-right: 2em;"><label for="collecting_source">
			Collecting Source
		</label>
		<select name="collecting_source" id="collecting_source" size="1" required="required">
			<cfloop query="ctCollecting_Source">
				<option <cfif ctCollecting_Source.Collecting_Source is locDet.collecting_source> selected="selected" </cfif>
					value="#ctCollecting_Source.Collecting_Source#">#ctCollecting_Source.Collecting_Source#</option>
			</cfloop>
		</select></td>
        <td>
		<label for="collecting_method">
			Collecting Method
		</label>
		<input type="text" name="collecting_method" id="collecting_method" value="#encodeForHTML(locDet.collecting_method)#" size="92"></td>
        </tr></table>
		<label for="habitat_desc">
			Habitat
		</label>
		<input type="text" name="habitat_desc" id="habitat_desc" value="#encodeForHTML(locDet.habitat_desc)#"  size="115">
        <br><br><input type="submit" value="Save" class="savBtn">
			<input type="button" value="Quit" class="qutBtn" onClick="document.location='Locality.cfm';">
		<input type="button" value="Delete" class="delBtn"
			onClick="document.location='Locality.cfm?Action=deleteCollEvent&collecting_event_id=#encodeForURL(locDet.collecting_event_id)#';">
		<cfset dLoc="Locality.cfm?action=newCollEvent&locality_id=#locDet.locality_id#&verbatim_locality=#encodeForURL(locDet.verbatim_locality)#&began_date=#encodeForURL(locDet.began_date)#&ended_date=#encodeForURL(locDet.ended_date)#&verbatim_date=#encodeForURL(locDet.verbatim_date)#&coll_event_remarks=#encodeForURL(locDet.coll_event_remarks)#&collecting_source=#encodeForURL(locDet.collecting_source)#&collecting_method=#encodeForURL(locDet.collecting_method)#&habitat_desc=#encodeForURL(locDet.habitat_desc)#">
		<input type="button" value="Create Clone" class="insBtn" onClick="document.location='#replace(dLoc,"'", "\'","all")#';">
	</cfform>

<cfif isdefined("session.roles") and listfindnocase(session.roles,"collops")>
	<!---  For a small set of collections operations users, include the TDWG BDQ TG2 test integration --->
	<script type='text/javascript' language="javascript" src='/dataquality/js/bdq_quality_control.js'></script>
	<script>
		function runTests() {
			loadSpaceQC("", #locDet.locality_id#, "SpatialDQDiv");
			loadEventQC("", #locDet.collecting_event_id#, "EventDQDiv");
		}
	</script>
	<input type="button" value="QC" class="savBtn" onClick=" runTests(); ">
	<!---  Spatial tests --->
	<div id="SpatialDQDiv"></div>
	<!---  Temporal tests --->
	<div id="EventDQDiv"></div>
</cfif>

  </cfoutput>
             </div>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "newCollEvent">
	<cfset title="Create Collecting Event">
	<cfoutput>
            <div class="basic_box">
	<h2 class="wikilink">Create Collecting Events:</h2>
	  	<cfquery name="getLoc"	 datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select  spec_locality, geog_auth_rec_id from locality
			where locality_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
		</cfquery>
		<cfquery name="getGeo" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select higher_geog from geog_auth_rec where
			geog_auth_rec_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getLoc.geog_auth_rec_id#">
		</cfquery>
		<h3>Create Collecting Event</h3>
                <br>Higher Geography: #getGeo.higher_geog#
                <br>Spec Locality: #getLoc.spec_locality#
	    <form name="newCollEvnt" action="Locality.cfm" method="post">
	    	<input type="hidden" name="Action" value="newColl">
	     	<input type="hidden" name="locality_id" value="#locality_id#">
	     	<label for="verbatim_locality">Verbatim Locality</label>
	     	<input type="text" name="verbatim_locality" id="verbatim_locality" size="115"
			  	<cfif isdefined("verbatim_locality")>
					value="#encodeForHTML(verbatim_locality)#"
				<cfelseif isdefined("getLoc.spec_locality")>
					value="#encodeForHTML(getLoc.spec_locality)#"
				</cfif>>
			<table>
				<tr>
					<td><label for="verbatimCoordinates">Verbatim Coordinates (Summary)<label>
							<input type="text" name="verbatimCoordinates" <cfif isdefined("verbatimCoordinates")> value="#encodeForHTML(verbatimCoordinates)#"</cfif> id="verbatimCoordinates"  size="115">
					</td>
				</tr>
			</table>
			<table>
				<tr>
					<td style="padding-right: 1.5em;"><label for="verbatimLatitude">Verbatim Latitude<label>
							<input type="text" name="verbatimLatitude" <cfif isdefined("verbatimLatitude")> value="#encodeForHTML(verbatimLatitude)#"</cfif> id="verbatimLatitude" size="30">
					</td>
					<td ><label for="verbatimLongitude">Verbatim Longitude<label>
							<input type="text" name="verbatimLongitude" <cfif isdefined("verbatimLongitude")>value="#encodeForHTML(verbatimLongitude)#"</cfif> id="verbatimLongitude" size="30">
					</td>
				</tr>
			</table>
			<table>
				<tr>
					<td style="padding-right: 1.5em;"><label for="verbatimCoordinateSystem">Verbatim Coordinate System (e.g., decimal degrees)<label>
							<input type="text" name="verbatimCoordinateSystem" <cfif isdefined("verbatimCoordinateSystem")>value="#encodeForHTML(verbatimCoordinateSystem)#"</cfif> id="verbatimCoordinateSystem" size="50">
					</td>
					<td ><label for="verbatimSRS">Verbatim SRS (includes ellipsoid model/Datum)<label>
							<input type="text" name="verbatimSRS" <cfif isdefined("verbatimSRS")>value="#encodeForHTML(verbatimSRS)#"</cfif> id="verbatimSRS" size="50">
					</td>
				</tr>
			</table>
		<table>
			<tr>
				<td>
				<label for="verbatim_date">Verbatim Date</label>
				<input type="text" name="verbatim_date" id="verbatim_date" class="reqdClr" required="required"
				  	<cfif isdefined("verbatim_date")>value="#encodeForHTML(verbatim_date)#"</cfif>>
				</td>
			</tr>
		</table>
		<table>
			<tr>
				<td style="padding-right: 1.5em;">
				<span class="infoLink"onClick="newCollEvnt.began_date.value=newCollEvnt.verbatim_date.value;
					newCollEvnt.ended_date.value=newCollEvnt.verbatim_date.value;">[ copy ]</span>
				<label for="collecting_time">Collecting Time</label>
				<input type="text" name="collecting_time" id="collecting_time"
				  	<cfif isdefined("collecting_time")>
						value="#encodeForHTML(collecting_time)#"
					</cfif>
				>
				</td>
			</tr>
		</table>
		<table>
			<tr>
				<td style="padding-right: 1.5em;">
					<label for="startDayOfYear">Start Day of Year</label>
					<input type="text" name="startDayOfYear" id="startDayOfYear"
					<cfif isdefined("startDayOfYear")>
						value="#encodeForHTML(locDet.startDayOfYear)#"
					</cfif>
					size="20">
				</td>
				<td>
					<label for="endDayOfYear">End Day of Year</label>
					<input type="text" name="endDayOfYear" id="endDayOfYear"
					<cfif isdefined("endDayOfYear")>
						value="#encodeForHTML(locDet.endDayOfYear)#"
					</cfif>
					size="20">
				</td>
			</tr>
		</table>
		<table>
			<tr>
				<td style="padding-right: 1.5em;">

						<label for="began_date">Began Date</label>
				      	<input type="text" name="began_date" id="began_date"
						  	<cfif isdefined("began_date")>
								value="#encodeForHTML(began_date)#"
							</cfif>
						>
			       </td>
				<td>

				        <label for="ended_date">Ended Date</label>
				        <input type="text" name="ended_date" id="ended_date"
							<cfif isdefined("ended_date")>
								value="#encodeForHTML(ended_date)#"
							</cfif>
						>

				</td>
			</tr>
		</table>
		<table>
		   <tr>
			<td>
			<label for="coll_event_remarks">Remarks</label>
			<input type="text" name="coll_event_remarks" id="coll_event_remarks"
			  	<cfif isdefined("coll_event_remarks")>
					value="#encodeForHTML(coll_event_remarks)#"
				</cfif>
			size="115">
			</td>
		   </tr>
		<table>
			<tr>
				<td style="padding-right: 2em;">
					<label for="collecting_source">Collecting Source</label>
					<cfif isdefined("collecting_source")>
						<cfset collsrc = collecting_source>
					<cfelse>
						<cfset collsrc = "">
					</cfif>
					<select name="collecting_source" id="collecting_source" size="1" class="reqdClr" required="required" >
					<option value="">Choose...</option>
						<cfloop query="ctCollecting_Source">
							<option
								<cfif ctCollecting_Source.Collecting_Source is collsrc> selected="selected" </cfif>
								value="#ctCollecting_Source.Collecting_Source#">#ctCollecting_Source.Collecting_Source#</option>
						</cfloop>
					</select>
				</td>
				<td>
					<label for="collecting_method">Collecting Method</label>
					<input type="text" name="collecting_method" id="collecting_method"
					  	<cfif isdefined("collecting_method")>
							value="#encodeForHTML(collecting_method)#"
						</cfif>
					size="92">
				</td>
			</tr></table>
		<table><tr><td>
			<label for="habitat_desc">Habitat</label>
			<input type="text" name="habitat_desc" id="habitat_desc"
				<cfif isdefined("HABITAT_DESC")>
					value="#encodeForHTML(HABITAT_DESC)#"
				</cfif>
			size="115">
			</td></tr></table>
			<input type="submit" value="Save" class="savBtn">
			<input type="button" value="Quit" class="qutBtn" onClick="document.location='Locality.cfm';">
		</form>
</div>
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------->
<cfif action is "newLocality">
	<cfif isdefined('geog_auth_rec_id')>
		<cfquery name="getHG" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select higher_geog from geog_auth_rec
			where geog_auth_rec_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
		</cfquery>
	</cfif>
	<cfoutput>
             <div style="width: 40em; margin:0 auto; padding: 1em 0 3em 0;">
	<h2 class="wikilink">Create Locality:</h2>

		<label>Higher Geography:</label>
		<form name="geog" action="Locality.cfm" method="post">
            <input type="hidden" name="Action" value="makenewLocality">
            <input type="hidden" name="geog_auth_rec_id"
				<cfif isdefined("geog_auth_rec_id")>
					value = "#geog_auth_rec_id#"
				</cfif>>
			<input type="text" name="higher_geog" class="readClr"
				<cfif isdefined("getHG.higher_geog")>
					value = "#encodeForHTML(getHG.higher_geog)#"
				</cfif>
			size="50"  readonly="yes" >
			<input type="button" value="Pick" class="picBtn"
				onclick="GeogPick('geog_auth_rec_id','higher_geog','geog'); return false;">
   			<cfif isdefined("geog_auth_rec_id")>
				<input type="button" value="Details" class="lnkBtn"
					onclick="document.location='Locality.cfm?Action=editGeog&geog_auth_rec_id=#geog_auth_rec_id#'">
         	</cfif>
           <label for="sovereign_nation">Sovereign Nation</label>
		   <select name="sovereign_nation" id="sovereign_nation" size="1">
                <cfloop query="ctSovereignNation">
            	    <option <cfif isdefined("sovereign_nation") AND ctsovereignnation.sovereign_nation is sovereign_nation> selected="selected" </cfif>value="#ctSovereignNation.sovereign_nation#">#ctSovereignNation.sovereign_nation#</option>
                </cfloop>
		   </select>
           <label for="spec_locality">Specific Locality</label>
           <input type="text" name="spec_locality" id="spec_locality"
				<cfif isdefined("spec_locality")>
					value= "#encodeForHTML(spec_locality)#"
				</cfif>
			>
			<label for="minimum_elevation">Minimum Elevation</label>
            <input type="text" name="minimum_elevation" id="minimum_elevation"
				<cfif isdefined("minimum_elevation")>
					value = "#encodeForHTML(minimum_elevation)#"
				</cfif>
			>
			<label for="maximum_elevation">Maximum Elevation</label>
			<input type="text" name="maximum_elevation" id="maximum_elevation"
				<cfif isdefined("maximum_elevation")>
					value = "#encodeForHTML(maximum_elevation)#"
				</cfif>
			>
			<label for="orig_elev_units">Elevation Units</label>
			<select name="orig_elev_units" id="orig_elev_units" size="1">
				<option value=""></option>
                <cfloop query="ctElevUnit">
            	    <option <cfif isdefined("origelevunits") AND ctelevunit.orig_elev_units is origelevunits> selected="selected" </cfif>value="#ctElevUnit.orig_elev_units#">#ctElevUnit.orig_elev_units#</option>
                </cfloop>
			</select>
			<label for="locality_remarks">Locality Remarks</label>
			<input type="text" name="locality_remarks" id="locality_remarks">
			<cfif isdefined("locality_id") and len(locality_id) gt 0>
				<input type="hidden" name="locality_id" value="locality_id" />
				<label for="">Include coordinates from <a href="/editLocality.cfm?locality_id=#locality_id#">#locality_id#</a>?</label>
				Y<input type="radio" name="cloneCoords" value="yes" />
				<br>N<input type="radio" name="cloneCoords" value="no" checked="checked" />
		 	</cfif>
            <br><input type="submit" value="Save" class="savBtn">
  			<input type="button" value="Quit" class="qutBtn" onClick="document.location='Locality.cfm';">
		</form>
</div>
	</cfoutput>
</cfif>

<!---------------------------------------------------------------------------------------------------->
<cfif action is "deleteGeog">
<cfoutput>
	<cfquery name="isLocality" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select geog_auth_rec_id from locality
		where geog_auth_rec_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
	</cfquery>
<cfif len(#isLocality.geog_auth_rec_id#) gt 0>
	There are active localities for this Geog. It cannot be deleted.
	<br><a href="Locality.cfm?Action=editGeog&geog_auth_rec_id=#geog_auth_rec_id#">Return</a> to editing.
	<cfabort>
<cfelseif len(#isLocality.geog_auth_rec_id#) is 0>
	<cfquery name="deleGeog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		delete from geog_auth_rec
		where geog_auth_rec_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
	</cfquery>
</cfif>
<cflocation addtoken="no" url="#cgi.HTTP_REFERER#">
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<!---------------------------------------------------------------------------------------------------->
<cfif action is "deleteCollEvent">
<cfoutput>
	<cfquery name="isSpec" datasource="uam_god">
		select collection_object_id from cataloged_item
		where collecting_event_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
	</cfquery>
<cfif len(#isSpec.collection_object_id#) gt 0>
	There are specimens for this collecting event. It cannot be deleted. If you can't see them, perhaps they aren't in
	the collection list you've set in your preferences.
	<br><a href="Locality.cfm?Action=editCollEvent&collecting_event_id=#collecting_event_id#">Return</a> to editing.
	<cfabort>
<cfelseif len(#isSpec.collection_object_id#) is 0>
	<cfquery name="deleCollEv" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		delete from collecting_event
		where collecting_event_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
	</cfquery>
</cfif>
You deleted a collecting event.
<br>Go back to <a href="Locality.cfm">localities</a>.
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<!---------------------------------------------------------------------------------------------------->
<cfif action is "changeLocality">
<cfoutput>
	<cfquery name="upColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		UPDATE collecting_event
		SET locality_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
		where collecting_event_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
	</cfquery>
		 <cfif not isdefined("collection_object_id")>
		 	<cfset collection_object_id=-1>
		 </cfif>
	<cflocation addtoken="no" url="Locality.cfm?collection_object_id=#collection_object_id#&action=editCollEvnt&collecting_event_id=#collecting_event_id#">
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "saveCollEventEdit">
	<cfoutput>
	<cftransaction>
	<cfquery name="upColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		UPDATE collecting_event SET
		BEGAN_DATE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#BEGAN_DATE#">
		,ENDED_DATE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ENDED_DATE#">
		,VERBATIM_DATE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VERBATIM_DATE#">
		,COLLECTING_SOURCE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#COLLECTING_SOURCE#">
	<cfif len(#verbatim_locality#) gt 0>
		,verbatim_locality = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#verbatim_locality#">
	<cfelse>
		,verbatim_locality = null
	</cfif>
	<cfif len(#COLL_EVENT_REMARKS#) gt 0>
		,COLL_EVENT_REMARKS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#COLL_EVENT_REMARKS#">
	<cfelse>
		,COLL_EVENT_REMARKS = null
	</cfif>
	<cfif len(#COLLECTING_METHOD#) gt 0>
		,COLLECTING_METHOD = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#COLLECTING_METHOD#">
	<cfelse>
		,COLLECTING_METHOD = null
	</cfif>
	<cfif len(#HABITAT_DESC#) gt 0>
		,HABITAT_DESC = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#HABITAT_DESC#">
	<cfelse>
		,HABITAT_DESC = null
	</cfif>
	<cfif len(#COLLECTING_TIME#) gt 0>
		,COLLECTING_TIME = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#COLLECTING_TIME#">
	<cfelse>
		,COLLECTING_TIME = null
	</cfif>
	<cfif len(#ICH_FIELD_NUMBER#) gt 0>
		,FISH_FIELD_NUMBER = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ICH_FIELD_NUMBER#">
	<cfelse>
		,FISH_FIELD_NUMBER = null
	</cfif>
	<cfif len(#verbatimCoordinates#) gt 0>
		,verbatimCoordinates = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#verbatimCoordinates#">
	<cfelse>
		,verbatimCoordinates = null
	</cfif>
	<cfif len(#verbatimLatitude#) gt 0>
		,verbatimLatitude = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#verbatimLatitude#">
	<cfelse>
		,verbatimLatitude = null
	</cfif>
	<cfif len(#verbatimLongitude#) gt 0>
		,verbatimLongitude = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#verbatimLongitude#">
	<cfelse>
		,verbatimLongitude = null
	</cfif>
	<cfif len(#verbatimCoordinateSystem#) gt 0>
		,verbatimCoordinateSystem = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#verbatimCoordinateSystem#">
	<cfelse>
		,verbatimCoordinateSystem = null
	</cfif>
	<cfif len(#verbatimSRS#) gt 0>
		,verbatimSRS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#verbatimSRS#">
	<cfelse>
		,verbatimSRS = null
	</cfif>
	<cfif len(#startDayOfYear#) gt 0>
		,startDayOfYear = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#startDayOfYear#">
	<cfelse>
		,startDayOfYear = null
	</cfif>
	<cfif len(#endDayOfYear#) gt 0>
		,endDayOfYear = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDayOfYear#">
	<cfelse>
		,endDayOfYear = null
	</cfif>
	 where collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#collecting_event_id#">
	</cfquery>
	<cfif isdefined("coll_event_number_series") and isdefined("coll_event_number") and len(trim(coll_event_number_series)) GT 0 and len(trim(coll_event_number)) GT 0 >
		<cfquery name="addCollEvNum" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			insert into coll_event_number
			(coll_event_number, coll_event_num_series_id, collecting_event_id)
			values (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#coll_event_number#">,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#coll_event_number_series#">,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
			)
		</cfquery>
	</cfif>
	</cftransaction>
	<cfif #cgi.HTTP_REFERER# contains "editCollEvnt">
		<cfset refURL = "#cgi.HTTP_REFERER#">
	<cfelse>
		<cfset refURL = "#cgi.HTTP_REFERER#?collection_object_id=#collection_object_id#&action=editCollEvnt&collecting_event_id=#collecting_event_id#">
	</cfif>
	<cflocation addtoken="no" url="#refURL#">
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<!---------------------------------------------------------------------------------------------------->
<cfif action is "saveGeogEdits">
	<cfoutput>
	<cfquery name="edGe" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		UPDATE geog_auth_rec
		SET
		source_authority = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#source_authority#">
		,valid_catalog_term_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#valid_catalog_term_fg#">
	<cfif len(#continent_ocean#) gt 0>
		,continent_ocean = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#continent_ocean#">
	<cfelse>
		,continent_ocean = null
	</cfif>

	<cfif len(#ocean_region#) gt 0>
		,ocean_region = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ocean_region#">
	<cfelse>
		,ocean_region = null
	</cfif>

	<cfif len(#ocean_subregion#) gt 0>
		,ocean_subregion = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ocean_subregion#">
	<cfelse>
		,ocean_subregion = null
	</cfif>

	<cfif len(#country#) gt 0>
		,country = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#country#">
	<cfelse>
		,country = null
	</cfif>

	<cfif len(#state_prov#) gt 0>
		,state_prov = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#state_prov#">
	<cfelse>
		,state_prov = null
	</cfif>

	<cfif len(#county#) gt 0>
		,county = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#county#">
	<cfelse>
		,county = null
	</cfif>

	<cfif len(#quad#) gt 0>
		,quad = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#quad#">
	<cfelse>
		,quad = null
	</cfif>
	<cfif len(#feature#) gt 0>
		,feature = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#feature#">
	<cfelse>
		,feature = null
	</cfif>
	<cfif len(#water_feature#) gt 0>
		,water_feature = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#water_feature#">
	<cfelse>
		,water_feature = null
	</cfif>
	<cfif len(#island_group#) gt 0>
		,island_group = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#island_group#">
	<cfelse>
		,island_group = null
	</cfif>
	<cfif len(#island#) gt 0>
		,island = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#island#">
	<cfelse>
		,island = null
	</cfif>
	<cfif len(#sea#) gt 0>
		,sea = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#sea#">
	<cfelse>
		,sea = null
	</cfif>
	<cfif len(#wktpolygon#) gt 0>
		,wkt_polygon = <cfqueryparam cfsqltype="CF_SQL_CLOB" value="#wktpolygon#">
	<cfelse>
		,wkt_polygon = null
	</cfif>
	<cfif len(#highergeographyid_guid_type#) gt 0>
		,highergeographyid_guid_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#highergeographyid_guid_type#">
	<cfelse>
		,highergeographyid_guid_type = null
	</cfif>
	<cfif len(#highergeographyid#) gt 0>
		,highergeographyid = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#highergeographyid#">
	<cfelse>
		,highergeographyid = null
	</cfif>
		where geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
	</cfquery>
	<cflocation addtoken="no" url="Locality.cfm?Action=editGeog&geog_auth_rec_id=#geog_auth_rec_id#">
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "makeGeog">
<cfoutput>
<cftransaction>
	<cfquery name="nextGEO" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select sq_geog_auth_rec_id.nextval nextid from dual
	</cfquery>
	<cfquery name="newGeog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		INSERT INTO geog_auth_rec
		(
			geog_auth_rec_id
			<cfif len(#continent_ocean#) gt 0>
				,continent_ocean
			</cfif>
			<cfif len(#ocean_region#) gt 0>
				,ocean_region
			</cfif>
			<cfif len(#ocean_subregion#) gt 0>
				,ocean_subregion
			</cfif>
			<cfif len(#country#) gt 0>
				,country
			</cfif>
			<cfif len(#state_prov#) gt 0>
				,state_prov
			</cfif>
			<cfif len(#county#) gt 0>
				,county
			</cfif>
			<cfif len(#quad#) gt 0>
				,quad
			</cfif>
			<cfif len(#feature#) gt 0>
				,feature
			</cfif>
			<cfif len(#water_feature#) gt 0>
				,water_feature
			</cfif>
			<cfif len(#island_group#) gt 0>
				,island_group
			</cfif>
			<cfif len(#island#) gt 0>
				,island
			</cfif>
			<cfif len(#sea#) gt 0>
				,sea
			</cfif>
			<cfif len(#highergeographyid_guid_type#) gt 0>
				,highergeographyid_guid_type
			</cfif>
			<cfif len(#highergeographyid#) gt 0>
				,highergeographyid
			</cfif>
			,valid_catalog_term_fg
			,source_authority
		)
		VALUES
		(
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#nextGEO.nextid#">
				<cfif len(#continent_ocean#) gt 0>
				, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#continent_ocean#">
			</cfif>
			<cfif len(#ocean_region#) gt 0>
				, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ocean_region#">
			</cfif>
			<cfif len(#ocean_subregion#) gt 0>
				, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ocean_subregion#">
			</cfif>
			<cfif len(#country#) gt 0>
				, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#country#">
			</cfif>
			<cfif len(#state_prov#) gt 0>
				, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#state_prov#">
			</cfif>
			<cfif len(#county#) gt 0>
				, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#county#">
			</cfif>
			<cfif len(#quad#) gt 0>
				, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#quad#">
			</cfif>
			<cfif len(#feature#) gt 0>
				, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#feature#">
			</cfif>
			<cfif len(#water_feature#) gt 0>
				, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#water_feature#">
			</cfif>
			<cfif len(#island_group#) gt 0>
				, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#island_group#">
			</cfif>
			<cfif len(#island#) gt 0>
				, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#island#">
			</cfif>
			<cfif len(#sea#) gt 0>
				, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#sea#">
			</cfif>
			<cfif len(#highergeographyid_guid_type#) gt 0>
				, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#highergeographyid_guid_type#">
			</cfif>
			<cfif len(#highergeographyid#) gt 0>
				, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#highergeographyid#">
			</cfif>
			,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#valid_catalog_term_fg#">
			,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#source_authority#">
		)
	</cfquery>
</cftransaction>
<cfif FIND("?", #cgi.HTTP_REFERER#) EQ 0>
<cflocation addtoken="no" url="#cgi.HTTP_REFERER#?Action=editGeog&geog_auth_rec_id=#nextGEO.nextid#">
<cfelse>
<cflocation addtoken="no" url="#cgi.HTTP_REFERER#&Action=editGeog&geog_auth_rec_id=#nextGEO.nextid#">
</cfif>
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<!---------------------------------------------------------------------------------------------------->
<cfif Action is "newColl">
<cfoutput>
	<cftransaction>
		<cfquery name="nextColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select sq_collecting_event_id.nextval nextColl from dual
		</cfquery>
		<cfquery name="newCollEvent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			INSERT INTO collecting_event (
			collecting_event_id,
			LOCALITY_ID
			,BEGAN_DATE
			,ENDED_DATE
			,VERBATIM_DATE
			,COLLECTING_SOURCE
			,VERBATIM_LOCALITY
			,COLL_EVENT_REMARKS
			,COLLECTING_METHOD
			,HABITAT_DESC
			,collecting_time
			,VERBATIMCOORDINATES
			,VERBATIMLATITUDE
			,VERBATIMLONGITUDE
			,VERBATIMCOORDINATESYSTEM
			,VERBATIMSRS
			,STARTDAYOFYEAR
			,ENDDAYOFYEAR
			)
		VALUES (
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#nextColl.nextColl#">
			,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LOCALITY_ID#">
			,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#BEGAN_DATE#">
			,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ENDED_DATE#">
			,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VERBATIM_DATE#">
			,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#COLLECTING_SOURCE#">
			<cfif len(#VERBATIM_LOCALITY#) gt 0>
				,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VERBATIM_LOCALITY#">
			<cfelse>
				,NULL
			</cfif>
			<cfif len(#COLL_EVENT_REMARKS#) gt 0>
				,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#COLL_EVENT_REMARKS#">
			<cfelse>
				,NULL
			</cfif>
			<cfif len(#COLLECTING_METHOD#) gt 0>
				,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#COLLECTING_METHOD#">
			<cfelse>
				,NULL
			</cfif>
			<cfif len(#HABITAT_DESC#) gt 0>
				,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#HABITAT_DESC#">
			<cfelse>
				,NULL
			</cfif>
			<cfif len(#collecting_time#) gt 0>
				,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collecting_time#">
			<cfelse>
				,NULL
			</cfif>
			<cfif len(#VERBATIMCOORDINATES#) gt 0>
				,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VERBATIMCOORDINATES#">
			<cfelse>
				,NULL
			</cfif>
			<cfif len(#VERBATIMLATITUDE#) gt 0>
				,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VERBATIMLATITUDE#">
			<cfelse>
				,NULL
			</cfif>
			<cfif len(#VERBATIMLONGITUDE#) gt 0>
				,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VERBATIMLONGITUDE#">
			<cfelse>
				,NULL
			</cfif>
			<cfif len(#VERBATIMCOORDINATESYSTEM#) gt 0>
				,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VERBATIMCOORDINATESYSTEM#">
			<cfelse>
				,NULL
			</cfif>
			<cfif len(#VERBATIMSRS#) gt 0>
				,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VERBATIMSRS#">
			<cfelse>
				,NULL
			</cfif>
			<cfif len(#STARTDAYOFYEAR#) gt 0>
				,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#STARTDAYOFYEAR#">
			<cfelse>
				,NULL
			</cfif>
			<cfif len(#ENDDAYOFYEAR#) gt 0>
				,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ENDDAYOFYEAR#">
			<cfelse>
				,NULL
			</cfif>
			)
		</cfquery>
	<cftransaction>
	<cflocation addtoken="no" url="/Locality.cfm?Action=editCollEvnt&collecting_event_id=#nextColl.nextColl#">
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->

<!---------------------------------------------------------------------------------------------------->
<cfif action is "makenewLocality">
	<cfoutput>
		<cfif not isdefined("cloneCoords") or #cloneCoords# is not "yes">
			<cfset cloneCoords = "no">
		</cfif>
		<cftransaction>
			<cfquery name="nextLoc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select sq_locality_id.nextval nextLoc from dual
			</cfquery>
			<cfquery name="newLocality" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO locality (
					LOCALITY_ID,
					GEOG_AUTH_REC_ID
					,MAXIMUM_ELEVATION
					,MINIMUM_ELEVATION
					,ORIG_ELEV_UNITS
					,SPEC_LOCALITY
					,SOVEREIGN_NATION
					,LOCALITY_REMARKS
					,LEGACY_SPEC_LOCALITY_FG )
				VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#nextLoc.nextLoc#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#GEOG_AUTH_REC_ID#">,
					<cfif len(#MAXIMUM_ELEVATION#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#MAXIMUM_ELEVATION#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#MINIMUM_ELEVATION#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#MINIMUM_ELEVATION#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#orig_elev_units#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#orig_elev_units#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#SPEC_LOCALITY#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#SPEC_LOCALITY#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#SOVEREIGN_NATION#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#SOVEREIGN_NATION#">,
					<cfelse>
						'[unknown]',
					</cfif>
					<cfif len(#LOCALITY_REMARKS#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LOCALITY_REMARKS#">,
					<cfelse>
						NULL,
					</cfif>
					0 )
			</cfquery>
			<cfif #cloneCoords# is "yes">
				<cfquery name="cloneCoordinates" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select * from lat_long
					where locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
				</cfquery>
				<cfloop query="cloneCoordinates">
					<cfset thisLatLongId = #llID.mLatLongId# + 1>
					<cfquery name="newLL" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						INSERT INTO lat_long (
							LAT_LONG_ID,
							LOCALITY_ID
							,LAT_DEG
							,DEC_LAT_MIN
							,LAT_MIN
							,LAT_SEC
							,LAT_DIR
							,LONG_DEG
							,DEC_LONG_MIN
							,LONG_MIN
							,LONG_SEC
							,LONG_DIR
							,DEC_LAT
							,DEC_LONG
							,DATUM
							,UTM_ZONE
							,UTM_EW
							,UTM_NS
							,ORIG_LAT_LONG_UNITS
							,DETERMINED_BY_AGENT_ID
							,DETERMINED_DATE
							,LAT_LONG_REF_SOURCE
							,LAT_LONG_REMARKS
							,MAX_ERROR_DISTANCE
							,MAX_ERROR_UNITS
							,NEAREST_NAMED_PLACE
							,LAT_LONG_FOR_NNP_FG
							,FIELD_VERIFIED_FG
							,ACCEPTED_LAT_LONG_FG
							,EXTENT
							,GPSACCURACY
							,GEOREFMETHOD
							,VERIFICATIONSTATUS)
						VALUES (
							sq_lat_long_id.nextval,
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#nextLoc.nextLoc#">
							<cfif len(#LAT_DEG#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LAT_DEG#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#DEC_LAT_MIN#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#DEC_LAT_MIN#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LAT_MIN#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LAT_MIN#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LAT_SEC#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LAT_SEC#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LAT_DIR#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LAT_DIR#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LONG_DEG#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LONG_DEG#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#DEC_LONG_MIN#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#DEC_LONG_MIN#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LONG_MIN#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LONG_MIN#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LONG_SEC#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LONG_SEC#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LONG_DIR#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LONG_DIR#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#DEC_LAT#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#DEC_LAT#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#DEC_LONG#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#DEC_LONG#">
							<cfelse>
								,NULL
							</cfif>
							,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#DATUM#">
							<cfif len(#UTM_ZONE#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#UTM_ZONE#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#UTM_EW#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#UTM_EW#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#UTM_NS#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#UTM_NS#">
							<cfelse>
								,NULL
							</cfif>
							,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ORIG_LAT_LONG_UNITS#">
							,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#DETERMINED_BY_AGENT_ID#">
							,<cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#dateformat(DETERMINED_DATE,"yyyy-mm-dd")#">
							,<cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#LAT_LONG_REF_SOURCE#">
							<cfif len(#LAT_LONG_REMARKS#) gt 0>
							    ,<cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#LAT_LONG_REMARKS#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#MAX_ERROR_DISTANCE#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#MAX_ERROR_DISTANCE#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#MAX_ERROR_UNITS#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#MAX_ERROR_UNITS#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#NEAREST_NAMED_PLACE#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#NEAREST_NAMED_PLACE#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LAT_LONG_FOR_NNP_FG#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LAT_LONG_FOR_NNP_FG#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#FIELD_VERIFIED_FG#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#FIELD_VERIFIED_FG#">
							<cfelse>
								,NULL
							</cfif>
							,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#ACCEPTED_LAT_LONG_FG#">
							<cfif len(#EXTENT#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#EXTENT#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#GPSACCURACY#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#GPSACCURACY#">
							<cfelse>
								,NULL
							</cfif>
							,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#GEOREFMETHOD#">
							,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VERIFICATIONSTATUS#">
						)
					</cfquery>
				</cfloop>
			</cfif><!---  end cloneCoordinates  --->
		</cftransaction>
		<cflocation addtoken="no" url="editLocality.cfm?locality_id=#nextLoc.nextLoc#">
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->

<!--------------------------- End Queries -------------------------------------------------->

<!--------------------------- Results -------------------------------------------------->
<!---------------------------------------------------------------------------------------------------->
<cfif action is "findCollEvent">
	<div style="padding-bottom:5em;">
	<cfoutput>
		<form name="tools" method="post" action="Locality.cfm">
			<input type="hidden" name="action" value="massMoveCollEvent" />

			<cf_findLocality>

			<cfquery name="localityResults" dbtype="query">
				select distinct
					collecting_event_id,
					higher_geog,
					geog_auth_rec_id,
					spec_locality,
					locality_remarks,
					geolAtts,
					LatitudeString,
					LongitudeString,
					nogeorefbecause,
					locality_id,
					verbatim_locality,
					began_date,
					ended_date,
					verbatim_date,
					collecting_source,
					collecting_method,
					min_depth,
					max_depth,
					depth_units,
					minimum_elevation,
					maximum_elevation,
					orig_elev_units,
					collcountlocality,
					collcountcollevent,
					curated_fg
				from localityResults
				order by
					higher_geog, spec_locality, verbatim_locality
			</cfquery>
	
		<cfset include_ce_counts = false>
		<cfif include_counts EQ 1>
			<cfif len(localityResults.collcountcollevent) GT 0>
				<cfset include_ce_counts = true>
			</cfif>
		</cfif>

<table border>
	<tr>
		<td><b>Geog</b></td>
		<td><b>Locality</b></td>
		<cfif include_counts EQ 1><td>Specimens (for locality)</td></cfif>
		<td><b>Verbatim&nbsp;Locality</b></td>
		<td><b>Began&nbsp;Date</b></td>
		<td><b>End&nbsp;Date</b></td>
		<td><b>Verb.&nbsp;Date</b></td>
		<td><b>Source</b></td>
		<td><b>Method</b></td>
		<cfif include_ce_counts><td>Specimens (for coll event)</td></cfif>
	</tr>
	<cfloop query="localityResults">
		<input type="hidden" name="collecting_event_id" value="#collecting_event_id#" />
		<tr>
			<td> <div class="smaller">#higher_geog#
				(<a href="Locality.cfm?Action=editGeog&geog_auth_rec_id=#geog_auth_rec_id#">#geog_auth_rec_id#</a>)
				</div>
			</td>
			<td>
				 <div class="smaller">
					#spec_locality#
					<cfif len(geolAtts) gt 0>[#geolAtts#]</cfif>
					<cfif len(min_depth) gt 0> (min-depth: #min_depth##depth_units#,</cfif>
					<cfif len(max_depth) gt 0> max-depth: #max_depth##depth_units#)</cfif>
					<cfif len(minimum_elevation) gt 0> (min-elevation: #minimum_elevation##orig_elev_units#,</cfif>
					<cfif len(maximum_elevation) gt 0> max-elevation: #maximum_elevation##orig_elev_units#)</cfif>
					<cfif len(#LatitudeString#) gt 0>
						<br>#LatitudeString#/#LongitudeString#
					<cfelse>
						<br>#nogeorefbecause#
					</cfif>
					<cfif len(locality_remarks) gt 0> remarks: #locality_remarks#</cfif>
					(<a href="editLocality.cfm?locality_id=#locality_id#">#locality_id#</a><cfif curated_fg EQ 1>*</cfif>)
				</div>
				<!---&nbsp;<a href="/fix/DupLocs.cfm?action=killDups&locid=#locality_id#" target="_blank"><font size="-2"><i>kill dups</i></font></a>--->
			</td>
			<cfif include_counts EQ 1>
				<td>
					#collcountlocality#
				</td>
			</cfif>
			<td>
				<div class="smaller">
				 	#verbatim_locality#
					(<a href="Locality.cfm?Action=editCollEvnt&collecting_event_id=#collecting_event_id#">#collecting_event_id#</a>)
				</div>
			</td>
			<td>#began_date#</td>
			<td>#ended_date#</td>
			<td>#verbatim_date#</td>
			<td>#collecting_source#</td>
			<td>#collecting_method#</td>
			<cfif include_ce_counts>
				<td>
					#collcountcollevent#
				</td>
			</cfif>
		</tr>
	</cfloop>
</table>
			<input type="submit"
                   style="float:left"
				value="Move These Collecting Events to New Locality"
				class="savBtn"
				onmouseover="this.className='savBtn btnhov'"
				onmouseout="this.className='savBtn'" />
		</form>
	</cfoutput>
        </div>
</cfif>
<!---------------------------------------------------------------------------------------------------->

<!---------------------------------------------------------------------------------------------------->
<cfif action is "massMoveCollEvent">
	<cfoutput>
		<cfset numCollEvents = listlen(collecting_event_id)>

	<cfquery name="whatSpecs" datasource="uam_god">
		SELECT count(cat_num) as numOfSpecs,
			collection.collection_cde,
			collection.institution_acronym
		FROM cataloged_item,collection
		WHERE
			cataloged_item.collection_id = collection.collection_id AND
			collecting_event_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#" list="yes">)
		GROUP BY collection.collection_cde,collection.institution_acronym
	</cfquery>
  <table>
  <tr>
  	<td>
  <cfif #whatSpecs.recordcount# is 0>
  		<font color="##FF0000"><strong>These #numCollEvents# Collecting Events</strong></font>
		<span style="font-size:small;">
		(#collecting_event_id#)
		</span>
		<font color="##FF0000"><strong>
		<a href="javascript:void(0);" onClick="getDocs('collecting_event')"><img src="/images/info.gif" border="0"></a>
		contains no specimens. Please delete it if you don't have plans for it!</strong></font>
  	<cfelseif #whatSpecs.recordcount# is 1>
		<font color="##FF0000"><strong>These #numCollEvents# Collecting Events </strong></font>
		<span style="font-size:small;">
		(#collecting_event_id#)
		</span>
		<font color="##FF0000"><strong>
		<a href="javascript:void(0);" onClick="getDocs('collecting_event')"><img src="/images/info.gif" border="0"></a>
		contains #whatSpecs.numOfSpecs# #whatSpecs.collection_cde#
		<a href="SpecimenResults.cfm?collecting_event_id=#collecting_event_id#">specimens</a>.</strong></font>
	<cfelse>
		<font color="##FF0000"><strong>These #numCollEvents# Collecting Events
		 </strong></font>
		<span style="font-size:small;">
		(#collecting_event_id#)
		</span>
		<font color="##FF0000"><strong>
		<a href="javascript:void(0);" onClick="getDocs('collecting_event')"><img src="/images/info.gif" border="0"></a>
		contains the following <a href="SpecimenResults.cfm?collecting_event_id=#collecting_event_id#">specimens</a>:</strong></font>
		<ul>
			<cfloop query="whatSpecs">
				<li><font color="##FF0000"><strong>#numOfSpecs# #collection_cde#</strong></font></li>
			</cfloop>
		</ul>
  </cfif>

  <cfquery name="cd" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
  	select *
	from collecting_event
	inner join locality on (collecting_event.locality_id = locality.locality_id)
	inner join geog_auth_rec on (locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id)
	left outer join accepted_lat_long on (locality.locality_id = accepted_lat_long.locality_id)
	where collecting_event.collecting_event_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#" list="yes">)
  </cfquery>
  <p></p>Current Data:
  <table border>
  	<tr>
		<td>Spec Loc</td>
		<td>Geog</td>
		<td>Lat/Long</td>
	</tr>
	<cfloop query="cd">
		<tr>
			<td><a href="editLocality.cfm?locality_id=#locality_id#">#spec_locality#</a></td>
			<td>#higher_geog#</td>
			<td>#dec_lat# #dec_long#</td>
		</tr>
	</cfloop>
  </table>
  <p>
	<form name="mlc" method="post" action="Locality.cfm">
		<input type="hidden" name="action" value="mmCollEvnt2" />
		<input type="hidden" name="collecting_event_id" value="#collecting_event_id#" />
		<input type="hidden" name="locality_id" />

		<input type="button"
			value="Pick New Locality"
			class="picBtn"
			onmouseover="this.className='picBtn btnhov'"
			onmouseout="this.className='picBtn'"
			onclick="document.getElementById('theSpanSaveThingy').style.display='';LocalityPick('locality_id','spec_locality','mlc'); return false;" >
			<input type="text" name="spec_locality" readonly border="0" size="60"/>
			<span id="theSpanSaveThingy" style="display:none;">
				<input type="submit" value="Save" />
			</span>

		</form>
  </p>
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "mmCollEvnt2">
	<cfoutput>
		<cftransaction>
		<cfloop list="#collecting_event_id#" index="ceid">
			<cfquery name="upCollLoc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update collecting_event set locality_id = <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#locality_id#">
			where collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#ceid#">
			</cfquery>
		</cfloop>
		</cftransaction>
		<cflocation url="Locality.cfm?Action=findCollEvent&locality_id=#locality_id#">
	</cfoutput>
</cfif>


<!---------------------------------------------------------------------------------------------------->
<cfif action is "findLocality">
	<div style="width: 98%; margin:0 auto; padding: 1em 0 3em 0;">
	<cfoutput>

	<cf_findLocality>

	<!--- obtain distinct localities from cf_findLocality localityResults --->
	<cfquery name="localityResults" dbtype="query">
		select distinct
			locality_id,
			geog_auth_rec_id,
			spec_locality,
			sovereign_nation,
			locality_remarks,
			higher_geog,
			LatitudeString,
			LongitudeString,
			NoGeorefBecause,
			coordinateDeterminer,
			lat_long_ref_source,
			determined_date,
			geolAtts,
			min_depth,
			max_depth,
			depth_units,
			minimum_elevation,
			maximum_elevation,
			orig_elev_units,
			collcountlocality,
			curated_fg
		from localityResults
		order by
			higher_geog, spec_locality
	</cfquery>

<cfif #localityResults.recordcount# lt 1001>
	<cfset thisLocId="">
	<cfloop query="localityResults">
		<cfif len(#thisLocId#) is 0>
			<cfset thisLocId="#locality_id#">
		<cfelse>
			<cfset thisLocId="#thisLocId#,#locality_id#">
		</cfif>
	</cfloop>
	<a href="/bnhmMaps/bnhmPointMapper.cfm?locality_id=#thisLocId#" target="_blank">BerkeleyMapper</a>
<cfelse>
	1000 record limit on mapping, sorry...
</cfif>
<br /><strong>Your query found #localityResults.recordcount# localities.</strong>


<table border>
	<tr>
		<td><b>Geog ID</b></td>
		<td><b>Locality ID</b></td>
		<td><b>Spec Locality</b></td>
		<td>Sovereign Nation</td>
		<td>Locality Remarks</td>
		<cfif include_counts EQ 1><td>Specimens</td></cfif>
		<td><b>Geog</b></td>
	</tr>
	<cfset i=1>
	<cfloop query="localityResults">
		<tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
			<td rowspan="2">
				<a href="Locality.cfm?Action=editGeog&geog_auth_rec_id=#geog_auth_rec_id#">#geog_auth_rec_id#</a>
			</td>
			<td rowspan="2">
				<span><a href="editLocality.cfm?locality_id=#locality_id#">#locality_id#</a><cfif curated_fg EQ 1>*</cfif></span>
			</td>
			<td style="min-width: 500px;">
				<b>#spec_locality#</b>
				<cfif len(geolAtts) gt 0>[#geolAtts#]</cfif>
			</td>
			<td rowspan="2">
				#sovereign_nation#
			</td>
			<td rowspan="2">
				#locality_remarks#
			</td>
			<cfif include_counts EQ 1>
				<td rowspan=2>
					#collcountlocality#
				</td>
			</cfif>
			<td rowspan="2">
				#higher_geog#
			</td>
		</tr>
		<tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
			<td>
				<font size="-1">
				&nbsp;
				<cfif len(LatitudeString) gt 0>
					#LatitudeString# / #LongitudeString#
				<cfelse>
					<b>NoGeorefBecause: #NoGeorefBecause#</b>
				</cfif>
				<cfif len(minimum_elevation) gt 0> (min-elevation: #minimum_elevation##orig_elev_units#,</cfif>
				<cfif len(maximum_elevation) gt 0> max-elevation: #maximum_elevation##orig_elev_units#)</cfif>
				<cfif len(min_depth) gt 0> (min-depth: #min_depth##depth_units#,</cfif>
				<cfif len(max_depth) gt 0> max-depth: #max_depth##depth_units#)</cfif>
				Determined by #coordinateDeterminer# on #dateformat(determined_date,"yyyy-mm-dd")# using #lat_long_ref_source#
				</font>
			</td>
		</tr>
		<cfset i=#i#+1>
	</cfloop>
</table>
</div>
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<!---------------------------------------------------------------------------------------------------->
<cfif action is "findGeog">
	<div style="width: 49em; margin:0 auto; padding: 2em 0 3em 0;">
	<cfoutput>

		<cf_findLocality>

		<!--- obtain distinct geographies from cf_findLocality localityResults --->
		<cfquery name="localityResults2" dbtype="query">
			select count(locality_id) as ct, geog_auth_rec_id,higher_geog
			from localityResults
			group by geog_auth_rec_id, higher_geog
			order by higher_geog
		</cfquery>
		<table border>
		<tr>
			<td><b>Geog ID</b></td><td><b>Higher Geog</b></td><td><b>Localities</b></td>
		</tr>
		<cfloop query="localityResults2">
			<tr>
				<td><a href="Locality.cfm?Action=editGeog&geog_auth_rec_id=#geog_auth_rec_id#">#geog_auth_rec_id#</a></td>
				<td>
					<input style="border:none;" value="#higher_geog#" size="80" readonly/>
				</td>
				<td>#ct#</td>
			</tr>
		</cfloop>
		</table>
	</cfoutput>
	</div>
</cfif>

<!---------------------------------------------------------------------------------------------------->
<cfinclude template="includes/_footer.cfm">
