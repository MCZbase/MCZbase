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
			<form name="nothing" method="get" action="/localities/HigherGeographies.cfm">
				<input type="submit" value="Find" class="lnkBtn">
			</form>
		</td>
		<td>
			<cfif len(session.roles) gt 0 and FindNoCase("manage_geography",session.roles) NEQ 0>
				<form name="nothing" method="get" action="/localities/HigherGeography.cfm">
					<input type="hidden" name="action" value="new">
					<input type="submit" value="New Higher Geog" class="insBtn">
				</form>
			</cfif>
		</td>
		<td>
			<span class="infoLink" onclick="getDocs('higher_geography');">Define</span>
		</td>
	</tr>
	<tr>
		<td>Localities</td>
		<td>
			<form name="nothing" method="get" action="/localities/Localities.cfm">
				<input type="submit" value="Find" class="lnkBtn">
			</form>
		</td>
		<td>
			<cfif len(session.roles) gt 0 and FindNoCase("manage_locality",session.roles) NEQ 0>
				<form name="nothing" method="get" action="/localities/Locality.cfm">
					<input type="hidden" name="action" value="new">
					<input type="submit" value="New Locality" class="insBtn">
				</form>
			</cfif>
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
	<cflocation url="/localities/HigherGeographies.cfm">
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "newHG">
	<cflocation url="/localities/HigherGeography.cfm?action=new">
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "findLO">
	<cflocation url="/localities/Localities.cfm">
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
	<cflocation url="/localities/viewHigherGeography.cfm?geog_auth_rec_id=#geog_auth_rec_id#">
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
			locality.minimum_elevation,
			locality.maximum_elevation,
			locality.orig_elev_units,
			locality.min_depth,
			locality.max_depth,
			locality.depth_units,
			locality.township,
			locality.township_direction,
			locality.range,
			locality.range_direction,
			locality.section,
			locality.section_part,
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
		    ENDDAYOFYEAR,
			verbatimelevation,
			verbatimdepth
		from
			locality
			inner join geog_auth_rec on (locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id)
			inner join collecting_event on ( locality.locality_id=collecting_event.locality_id )
			left outer join accepted_lat_long on (locality.locality_id=accepted_lat_long.locality_id)
			left outer join preferred_agent_name on (accepted_lat_long.determined_by_agent_id = preferred_agent_name.agent_id)
		where collecting_event.collecting_event_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
    </cfquery>
	<cfquery name="geology" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="geology_result">
		SELECT geology_attributes.geology_attribute, geo_att_value
		FROM
			geology_attributes
			left join ctgeology_attributes on geology_attributes.geology_attribute = ctgeology_attributes.geology_attribute
		WHERE
			locality_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locDet.locality_id#">
		ORDER BY
			ordinal
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
            <p><span style="font-weight: 600;color: ##ff0000; width: 210px; display: inline-block;text-align:right;">Sovereign Nation:</span> #locDet.sovereign_nation#</p>
				<cfif len(locDet.minimum_elevation) GT 0>
            	<p>
						<span style="font-weight: 600;color: ##ff0000; width: 210px; display: inline-block;text-align:right;">Elevation:</span> 
						#locDet.minimum_elevation#
						<cfif len(locDet.maximum_elevation) GT 0 AND locDet.maximum_elevation NEQ locDet.minimum_elevation>- #locDet.maximum_elevation#</cfif>
						#locDet.orig_elev_units#
					</p>
				</cfif>
				<cfif len(locDet.min_depth) GT 0>
            	<p>
						<span style="font-weight: 600;color: ##ff0000; width: 210px; display: inline-block;text-align:right;">Depth:</span> 
						#locDet.min_depth#
						<cfif len(locDet.max_depth) GT 0 AND locDet.max_depth NEQ locDet.min_depth>- #locDet.max_depth#</cfif>
						#locDet.depth_units#
					</p>
				</cfif>
				<cfif len(locDet.township) GT 0>
            	<p>
						<span style="font-weight: 600;color: ##ff0000; width: 210px; display: inline-block;text-align:right;">PLSS:</span> 
						T #locDet.township# #locDet.township_direction# R #locDet.range# #locDet.range_direction# #locDet.section_part# Sec #locDet.section# 
					</p>
				</cfif>
				<cfif geology.recordcount GT 0>
					<cfset geologicalAttributes = "">
					<cfset gSeparator = "">
					<cfloop query="geology">
						<cfset geologicalAttributes="#geologicalAttributes##gSeparator##geology.geology_attribute#=#geology.geo_att_value#">
						<cfset gSeparator = "; ">
					</cfloop>
            	<p>
						<span style="font-weight: 600;color: ##ff0000; width: 210px; display: inline-block;text-align:right;">Geology:</span> 
						#geologicalAttributes#
					</p>
				</cfif>
		</div>

		<div id="hiddenButton" style="visibility:hidden;margin-bottom: 0; padding-bottom:0;height: 18px; ">
			Picked Locality:
			<input type="text" name="spec_locality" size="50">
			<input type="submit" value="Save Change" class="savBtn">
		</div>
	</form>

	OR<br>

	<input type="button" value="Edit the current Locality" class="lnkBtn" style="margin: 1em 0;"
		onClick="document.location='/localities/Locality.cfm?locality_id=#locDet.locality_id#'">

	<br>OR<br>

	<h3 class="wikilink">Edit this Collecting Event:</h3>
	<cfform name="locality" method="post" action="Locality.cfm">
		<input type="hidden" name="Action" value="saveCollEventEdit">
		<input type="hidden" name="collecting_event_id" value="#locDet.collecting_event_id#">
		<input type="hidden" name="collection_object_id" value="#collection_object_id#">
		<div style="border: 1px solid green;padding: .5em;">
			<label for="verbatim_locality">Verbatim Locality</label>
			<input type="text" name="verbatim_locality" id="verbatim_locality" value="#encodeForHTML(locDet.verbatim_locality)#" size="115">
			<table>
				<tr>
					<td>
						<label for="verbatimDepth">Verbatim Depth<label>
						<input type="text" name="verbatimDepth" value="#encodeForHTML(locDet.verbatimDepth)#" id="verbatimDepth" size="30">
					</td>
					<td>
						<label for="verbatimElevation">Verbatim Elevation<label>
						<input type="text" name="verbatimElevation" value="#encodeForHTML(locDet.verbatimElevation)#" id="verbatimElevation" size="30">
					</td>
				</tr>
			</table>
			<table>
				<tr>
					<td>
						<label for="verbatimCoordinates">Verbatim Coordinates (summary)<label>
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
		<cfset dLoc="Locality.cfm?action=newCollEvent&locality_id=#locDet.locality_id#&verbatim_locality=#encodeForURL(locDet.verbatim_locality)#&began_date=#encodeForURL(locDet.began_date)#&ended_date=#encodeForURL(locDet.ended_date)#&verbatim_date=#encodeForURL(locDet.verbatim_date)#&coll_event_remarks=#encodeForURL(locDet.coll_event_remarks)#&collecting_source=#encodeForURL(locDet.collecting_source)#&collecting_method=#encodeForURL(locDet.collecting_method)#&habitat_desc=#encodeForURL(locDet.habitat_desc)#&verbatimDepth=#encodeForURL(locDet.verbatimDepth)#&verbatimElevation=#encodeForURL(locDet.verbatimElevation)#">
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
			<br>Spec Locality: <a href="/localities/Locality.cfm?locality_id=#locality_id#">#getLoc.spec_locality#</a>
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
					<td>
						<label for="verbatimDepth">Verbatim Depth<label>
						<cfif not isDefined("verbatimDepth")><cfset verbatimDepth = ""></cfif>
						<input type="text" name="verbatimDepth" value="#encodeForHTML(verbatimDepth)#" id="verbatimDepth" size="30">
					</td>
					<td>
						<label for="verbatimElevation">Verbatim Elevation<label>
						<cfif not isDefined("verbatimElevation")><cfset verbatimElevation = ""></cfif>
						<input type="text" name="verbatimElevation" value="#encodeForHTML(verbatimElevation)#" id="verbatimElevation" size="30">
					</td>
				</tr>
			</table>
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
				      	<input type="text" name="began_date" id="began_date"  class="reqdClr" required="required"
						  	<cfif isdefined("began_date")>
								value="#encodeForHTML(began_date)#"
							</cfif>
						>
			       </td>
				<td>

				        <label for="ended_date">Ended Date</label>
				        <input type="text" name="ended_date" id="ended_date" class="reqdClr" required="required"
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
	<cflocation url="/localities/Locality.cfm?action=new">
</cfif>

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
	<cfif len(#verbatimdepth#) gt 0>
		,verbatimdepth = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#verbatimdepth#">
	<cfelse>
		,verbatimdepth = null
	</cfif>
	<cfif len(#verbatimelevation#) gt 0>
		,verbatimelevation = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#verbatimelevation#">
	<cfelse>
		,verbatimelevation = null
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
	 where collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
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
			,verbatimdepth
			,verbatimelevation
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
			<cfif len(#VERBATIMDEPTH#) gt 0>
				,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VERBATIMDEPTH#">
			<cfelse>
				,NULL
			</cfif>
			<cfif len(#VERBATIMELEVATION#) gt 0>
				,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VERBATIMELEVATION#">
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
	<cflocation addtoken="no" url="/localities/CollectingEvent.cfm?collecting_event_id=#nextColl.nextColl#">
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "makenewLocality">
	<cfthrow message="Unsupported action, functionality has moved to new page">
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
				(<a href="/localities/viewHigherGeography.cfm?geog_auth_rec_id=#geog_auth_rec_id#">#geog_auth_rec_id#</a>)
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
					(<a href="/localities/Locality.cfm?locality_id=#locality_id#">#locality_id#</a><cfif curated_fg EQ 1>*</cfif>)
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
			<td><a href="/localiteis/Locality.cfm?locality_id=#locality_id#">#spec_locality#</a></td>
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
			update collecting_event set locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
			where collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#ceid#">
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
				<a href="/localities/viewHigherGeography.cfm?geog_auth_rec_id=#geog_auth_rec_id#">#geog_auth_rec_id#</a>
			</td>
			<td rowspan="2">
				<span><a href="/localities/viewLocality.cfm?locality_id=#locality_id#">#locality_id#</a><cfif curated_fg EQ 1>*</cfif></span>
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
				<td>
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_geography")>
						<a href="/localities/HigherGeography.cfm?geog_auth_rec_id=#geog_auth_rec_id#">#geog_auth_rec_id#</a>
					<cfelse>
						<a href="/localities/viewHigherGeography.cfm?geog_auth_rec_id=#geog_auth_rec_id#">#geog_auth_rec_id#</a>
					</cfif>
				</td>
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
