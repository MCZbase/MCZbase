<cfinclude template="/includes/alwaysInclude.cfm">
<script language="javascript" type="text/javascript">
	jQuery(document).ready(function() {
		$("#determined_date").datepicker();
		$("#began_date").datepicker({
			showOn: "button",
			buttonImage: "images/cal_icon.png",
			buttonImageOnly: true});
		$("#ended_date").datepicker({showOn: "button",
			buttonImage: "images/cal_icon.png",
			buttonImageOnly: true});
		$(":input[id^='geo_att_determined_date']").each(function(e){
			$("#" + this.id).datepicker();
		});
		$("select[id^='geology_attribute_']").each(function(e){
			populateGeology(this.id);
		});
	});
	function populateGeology(id) {
		if (id.indexOf('__') > -1) {
			var idNum=id.replace('geology_attribute__','');
			var thisValue=$("#geology_attribute__" + idNum).val();;
			var dataValue=$("#geo_att_value__" + idNum).val();
			var theSelect="geo_att_value__";
			if (thisValue == ''){
				return false;
			}
		} else {
			// new geol attribute
			var idNum='';
			var thisValue=$("#geology_attribute").val();
			var dataValue=$("#geo_att_value").val();
			var theSelect="geo_att_value";
		}
		jQuery.getJSON("/component/functions.cfc",
			{
				method : "getGeologyValues",
				attribute : thisValue,
				returnformat : "json",
				queryformat : 'column'
			},
			function (r) {
				var s='';
				var exists = false;

				if (dataValue !==null)
				{for (i=0; i<r.ROWCOUNT; ++i) {

					if (r.DATA.ATTRIBUTE_VALUE[i]==dataValue){exists=true;}
					}
				if (exists==false){s='<option value="' + dataValue + '" selected="selected" style="color:red;">' + dataValue + '</option>';}
					}
				for (i=0; i<r.ROWCOUNT; ++i) {
					s+='<option value="' + r.DATA.ATTRIBUTE_VALUE[i] + '"';
					if (r.DATA.ATTRIBUTE_VALUE[i]==dataValue) {
						s+=' selected="selected"';
					}
					s+='>' + r.DATA.ATTRIBUTE_VALUE[i] + '</option>';
				}
				$("select#" + theSelect + idNum).html(s);
			}
		);
	}
</script>
<script>
	function showLLFormat(orig_units) {
		//alert(orig_units);
		var llMeta = document.getElementById('llMeta');
		var decdeg = document.getElementById('decdeg');
		var utm = document.getElementById('utm');
		var ddm = document.getElementById('ddm');
		var dms = document.getElementById('dms');
		llMeta.style.display='none';
		decdeg.style.display='none';
		utm.style.display='none';
		ddm.style.display='none';
		dms.style.display='none';
		//alert('everything off');
		if (orig_units.length > 0) {
			//alert('got soemthing');
			llMeta.style.display='';
			if (orig_units == 'decimal degrees') {
				decdeg.style.display='';
			}
			else if (orig_units == 'UTM') {
				//alert(utm.style.display);
				utm.style.display='';
				//alert(utm.style.display);
			}
			else if (orig_units == 'degrees dec. minutes') {
				ddm.style.display='';
			}
			else if (orig_units == 'deg. min. sec.') {
				dms.style.display='';
			}
			else {
				alert('I have no idea what to do with ' + orig_units);
			}
		}
	}
</script>

<cfif action is "nothing">

   <!--- Provide a probably sane value for sovereign_nation if none is currently provided. --->
   <cfquery name="getLID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
    	select distinct
			locality_id
		from
			spec_with_loc
		where
			collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
   </cfquery>
   <cfquery name="getSov" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
        select
            sovereign_nation, mczbase.suggest_sovereign_nation(locality_id) suggest
        from
            locality
        where
            locality.locality_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getLID.locality_id#">
   </cfquery>
   <cfif len(getSov.sovereign_nation) eq 0>
      <cfquery name="getSov" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
      update locality
            set sovereign_nation =  <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getSov.suggest#">
      where sovereign_nation is null and
            locality.locality_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getLID.locality_id#">
      </cfquery>
   </cfif>


  <div class="basic_wide_box" style="width:75em;">
    <h3 class="wikilink">Locality</h3>
    <cfoutput>
      <cfquery name="l" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
    	select distinct
			collection_object_id,
			collecting_event_id,
			LOCALITY_ID,
            nvl(sovereign_nation,'[unknown]') as sovereign_nation,
			geog_auth_rec_id,
			MAXIMUM_ELEVATION,
			MINIMUM_ELEVATION,
			ORIG_ELEV_UNITS,
			SPEC_LOCALITY,
			LOCALITY_REMARKS,
			DEPTH_UNITS,
			MIN_DEPTH,
			MAX_DEPTH,
			NOGEOREFBECAUSE,
			LAT_LONG_ID,
			LAT_DEG,
			DEC_LAT_MIN,
			LAT_MIN,
			trim(LAT_SEC) LAT_SEC,
			LAT_DIR,
			LONG_DEG,
			DEC_LONG_MIN,
			LONG_MIN,
			trim(LONG_SEC) LONG_SEC,
			LONG_DIR,
			trim(DEC_LAT) DEC_LAT,
			trim(DEC_LONG) DEC_LONG,
			UTM_ZONE,
			UTM_EW,
			UTM_NS,
			DATUM,
			ORIG_LAT_LONG_UNITS,
			DETERMINED_BY_AGENT_ID,
			coordinate_determiner,
			DETERMINED_DATE,
			LAT_LONG_REMARKS,
			MAX_ERROR_DISTANCE,
			MAX_ERROR_UNITS,
			ACCEPTED_LAT_LONG_FG,
			EXTENT,
			GPSACCURACY,
			GEOREFMETHOD,
			VERIFICATIONSTATUS,
			LAT_LONG_REF_SOURCE,
			HIGHER_GEOG,
			BEGAN_DATE,
			ENDED_DATE,
			VERBATIM_DATE,
			VERBATIM_LOCALITY,
			COLL_EVENT_REMARKS,
			COLLECTING_SOURCE,
			COLLECTING_METHOD,
			HABITAT_DESC,
			COLLECTING_TIME,
			FISH_FIELD_NUMBER,
			VERBATIMCOORDINATES,
		    VERBATIMLATITUDE,
		    VERBATIMLONGITUDE,
		    VERBATIMCOORDINATESYSTEM,
		    VERBATIMSRS,
		    STARTDAYOFYEAR,
		    ENDDAYOFYEAR,
		    VERIFIED_BY_AGENT_ID,
		    VERIFIEDBY
		from
			spec_with_loc
		where
			collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
	</cfquery>
      <cfquery name="g" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select
			GEOLOGY_ATTRIBUTE_ID,
			GEOLOGY_ATTRIBUTE,
			GEO_ATT_VALUE,
			GEO_ATT_DETERMINER_ID,
			geo_att_determiner,
			GEO_ATT_DETERMINED_DATE,
			GEO_ATT_DETERMINED_METHOD,
			GEO_ATT_REMARK
		from
			spec_with_loc
		where
			collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#"> and
			GEOLOGY_ATTRIBUTE is not null
		group by
			GEOLOGY_ATTRIBUTE_ID,
			GEOLOGY_ATTRIBUTE,
			GEO_ATT_VALUE,
			GEO_ATT_DETERMINER_ID,
			geo_att_determiner,
			GEO_ATT_DETERMINED_DATE,
			GEO_ATT_DETERMINED_METHOD,
			GEO_ATT_REMARK
	</cfquery>
      <cfquery name="ctElevUnit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select orig_elev_units from ctorig_elev_units
	</cfquery>
      <cfquery name="ctdepthUnit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select depth_units from ctdepth_units
	</cfquery>
      <cfquery name="ctdatum" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
        select datum from ctdatum
     </cfquery>
      <cfquery name="ctGeorefMethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select georefMethod from ctgeorefmethod
	</cfquery>
      <cfquery name="ctVerificationStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select VerificationStatus from ctVerificationStatus order by VerificationStatus
	</cfquery>
      <cfquery name="cterror" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
        select LAT_LONG_ERROR_UNITS from ctLAT_LONG_ERROR_UNITS
     </cfquery>
      <cfquery name="ctew" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
        select e_or_w from ctew
     </cfquery>
      <cfquery name="ctns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
        select n_or_s from ctns
     </cfquery>
      <cfquery name="ctunits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
        select ORIG_LAT_LONG_UNITS from ctLAT_LONG_UNITS
      </cfquery>
      <cfquery name="ctcollecting_source" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
        select COLLECTING_SOURCE from ctcollecting_source
      </cfquery>
      <cfquery name="ctgeology_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select geology_attribute from ctgeology_attribute order by ordinal
	  </cfquery>
      <cfquery name="ctSovereignNation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	    select sovereign_nation from ctsovereign_nation order by sovereign_nation
      </cfquery>

      <cfquery name="cecount" datasource="uam_god">
         select count(collection_object_id) ct from cataloged_item
         where collecting_event_id = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value = "#l.collecting_event_id#">
      </cfquery>
      <cfquery name="loccount" datasource="uam_god">
         select count(ci.collection_object_id) ct from cataloged_item ci
             left join collecting_event on ci.collecting_event_id = collecting_event.collecting_event_id
         where collecting_event.locality_id = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value = "#l.locality_id#">
      </cfquery>
      <cfform name="loc" method="post" action="specLocality.cfm">
        <input type="hidden" name="action" value="saveChange">
        <input type="hidden" name="nothing" id="nothing">
        <input type="hidden" name="collection_object_id" value="#collection_object_id#">
        <table>
        <tr>
        <td valign="top"><!--- left half of page --->

          <table>
            <tr>
          		<td>
						<label for="higher_geog"> Higher Geography
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_geography")>
								<a href="/localities/HigherGeography.cfm?geog_auth_rec_id=#l.geog_auth_rec_id#" target="_blank">Edit</a>
							<cfelse>
								<a href="/localities/viewHigherGeography.cfm?geog_auth_rec_id=#l.geog_auth_rec_id#" target="_blank">View</a>
							</cfif>
               	 </label>
                	<input type="text" id="higher_geog" name="higher_geog" size="75" value="#l.higher_geog#" class="reqdClr"
							onchange="getGeog('nothing','higher_geog','loc',this.value); return false;">
					</td>
            </tr>
            <tr>
              <td><label for="spec_locality"> Specific Locality
                  &nbsp;&nbsp; <a href="/localities/Locality.cfm?locality_id=#l.locality_id#" target="_blank"> Edit Locality</a>
                  <cfif loccount.ct eq 1>(unique to this specimen)<cfelse>(shared with #loccount.ct# specimens)</cfif>
                  </label>
                <cfinput type="text"
					name="spec_locality"
					id="spec_locality"
					value="#stripQuotes(l.spec_locality)#"
					size="75"
					required="true"
					message="Specific Locality is required."></td>
            </tr>
            <tr>
               <td>
               <label for="sovereign_nation">Sovereign Nation</label>
   		       <select name="sovereign_nation" id="sovereign_nation" size="1">
                   <cfloop query="ctSovereignNation">
               	    <option <cfif isdefined("l.sovereign_nation") AND ctsovereignnation.sovereign_nation is l.sovereign_nation> selected="selected" </cfif>value="#ctSovereignNation.sovereign_nation#">#ctSovereignNation.sovereign_nation#</option>
                   </cfloop>
               </td>
            </tr>
            <tr>
              <td><label for="verbatim_locality"> Verbatim Locality
                  &nbsp;&nbsp; <a href="/localities/CollectingEvent.cfm?collecting_event_id=#l.collecting_event_id#" target="_blank"> Edit Collecting Event</a>
                  <cfif cecount.ct eq 1>(unique to this specimen)<cfelse>(shared with #cecount.ct# specimens)</cfif>
 </label>
                <cfinput type="text"
					name="verbatim_locality"
					id="verbatim_locality"
					value="#stripQuotes(l.verbatim_locality)#"
					size="75"
					required="true"
					message="Verbatim Locality is required."></td>
            </tr>
   </table>
          <table>
            <tr>
              <td><label for="verbatim_date"> Verbatim Date </label>
                <cfinput type="text"
					name="verbatim_date"
					id="verbatim_date"
					value="#stripQuotes(l.verbatim_date)#"
					size="75"
					required="true"
					message="Verbatim Date is a required text field."></td>
            </tr>
            <tr>
              <td><table>

                    <td><label for="collecting time"> Collecting Time </label>
                      <cfinput type="text"
					name="collecting_time"
					id="collecting_time"
					value="#stripQuotes(l.collecting_time)#"
					size="20"></td>
                    <td><label for="ich field number"> Ich. Field Number </label>
                      <cfinput type="text"
					name="ich_field_number"
					id="ich_field_number"
					value="#stripQuotes(l.fish_field_number)#"
					size="20"></td>
                </table>
            </tr>
            <tr>
              <td><table>

                    <td><label for="startDayofYear"> Start Day of Year</label>
                      <cfinput type="text"
					name="startDayofYear"
					id="startDayofYear"
					value="#l.startdayofyear#"
					size="20"></td>
                    <td><label for="endDayofYear"> End Day of Year </label>
                      <cfinput type="text"
					name="endDayofYear"
					id="endDayofYear"
					value="#l.enddayofyear#"
					size="20"></td>
                </table>
            </tr>
            <tr>
              <td><table>

                    <td><label for="began_date"> Began Date/Time</a></label>
                      <input type="text"
								name="began_date"
								id="began_date"
								value="#l.began_date#"
								class="reqdClr"
                                style="vertical-align:top;"></td>
                    <td><label for="ended_date"> Ended Date/Time </label>
                      <input type="text"
								name="ended_date"
								id="ended_date"
								value="#l.ended_date#"
								class="reqdClr"
                                style="vertical-align:top;"></td>
                  </tr>
                </table></td>
            </tr>
            <tr>
              <td><label for="coll_event_remarks"> Collecting Event Remarks </label>
                <input type="text"
					name="coll_event_remarks"
						id="coll_event_remarks"
					value="#stripQuotes(l.COLL_EVENT_REMARKS)#"
					size="75"></td>
            </tr>
            <tr>
              <td><label for="collecting_source"> Collecting Source </label>
                <select name="collecting_source" id="collecting_source" size="1" class="reqdClr">
                  <option value=""></option>
                  <cfloop query="ctcollecting_source">
                    <option <cfif #ctcollecting_source.COLLECTING_SOURCE# is "#l.COLLECTING_SOURCE#"> selected </cfif>
						value="#ctcollecting_source.COLLECTING_SOURCE#">#ctcollecting_source.COLLECTING_SOURCE#</option>
                  </cfloop>
                </select></td>
            </tr>

              <td><label for="collecting_method"> Collecting Method </label>
                <input type="text"
					name="collecting_method"
					id="collecting_method"
					value="#stripQuotes(l.COLLECTING_METHOD)#"
					size="75"></td>
            </tr>
            <tr>
              <td><label for="habitat_desc"> Habitat </label>
                <input type="text"
					name="habitat_desc"
					id="habitat_desc"
					value="#stripQuotes(l.habitat_desc)#"
					size="75"></td>
            </tr>
            <tr>
              <td><table>
                  <tr>
                    <td style="width: 110px;"><label for="minimum_elevation"> Min. Elevation </label>
                      <cfinput
								type="text"
								name="minimum_elevation"
								id="minimum_elevation"
								value="#l.MINIMUM_ELEVATION#"
								size="10"
								validate="numeric"
								message="Minimum Elevation is a number."></td>
                    <td style="width: 110px;"><label for="maximum_elevation"> Max. Elevation </label>
                      <cfinput type="text"
								id="maximum_elevation"
								name="maximum_elevation"
								value="#l.MAXIMUM_ELEVATION#"
								size="10"
								validate="numeric"
								message="Maximum Elevation is a number."></td>
                    <td style="width: 100px;"><label for="orig_elev_units"> Elevation Units </label>
                      <select name="orig_elev_units" id="orig_elev_units" size="1">
                        <option value=""></option>
                        <cfloop query="ctElevUnit">
                          <option <cfif #ctelevunit.orig_elev_units# is "#l.orig_elev_units#"> selected </cfif>
									value="#ctElevUnit.orig_elev_units#">#ctElevUnit.orig_elev_units#</option>
                        </cfloop>
                      </select></td>
                  </tr>
                </table></td>
            </tr>
            <tr>
              <td><table>
                  <tr>
                    <td style="width:110px;"><label for="min_depth"> Min. Depth </label>
                      <cfinput type="text" name="min_depth" id="min_depth" value="#l.min_depth#" size="10"
								validate="numeric"
								message="Minimum Depth is a number."></td>
                    <td style="width:110px;"><label for="max_depth"  > Max. Depth </label>
                      <cfinput type="text" id="max_depth" name="max_depth"
								value="#l.max_depth#" size="10"
								validate="numeric"
								message="Maximum Depth is a number."></td>
                    <td style="width:100px;"><label for="depth_units" > Depth Units </label>
                      <select name="depth_units" id="depth_units" size="1">
                        <option value=""></option>
                        <cfloop query="ctdepthUnit">
                          <option <cfif #ctdepthUnit.depth_units# is "#l.depth_units#"> selected </cfif>
									value="#ctdepthUnit.depth_units#">#ctdepthUnit.depth_units#</option>
                        </cfloop>
                      </select></td>
                  </tr>
                </table></td>
            </tr>
            <tr>
              <td><label for="locality_remarks">Locality Remarks</label>
                <input type="text" name="locality_remarks" id="locality_remarks" value="#stripQuotes(l.LOCALITY_REMARKS)#"  size="75"></td>
            </tr>
            <tr>
              <td><label for="NoGeorefBecause"> Not Georefererenced Because <a href="##" onClick="getMCZDocs('Not_Georeferenced_Because')">(Suggested Entries)</a></label>
                <input type="text" name="NoGeorefBecause" value="#l.NoGeorefBecause#"  size="75">
                <cfif #len(l.orig_lat_long_units)# gt 0 AND len(#l.NoGeorefBecause#) gt 0>
                  <div class="redMessage"> NoGeorefBecause should be NULL for localities with georeferences.
                    Please review this locality and update accordingly. </div>
                  <cfelseif #len(l.orig_lat_long_units)# is 0 AND len(#l.NoGeorefBecause#) is 0>
                  <div class="redMessage"> Please georeference this locality or enter a value for NoGeorefBecause. </div>
                </cfif></td>
            </tr>
          </table></td>
        <td valign="top">
        <table>
        <tr>
          <td><label for="ORIG_LAT_LONG_UNITS"> Original Coordinate Units </label>
            <cfset thisUnits = #l.ORIG_LAT_LONG_UNITS#>
            <select name="ORIG_LAT_LONG_UNITS" id="ORIG_LAT_LONG_UNITS" size="1" class="reqdClr" onchange="showLLFormat(this.value)">
              <option value="">Not Georeferenced</option>
              <cfloop query="ctunits">
                <option
						  	<cfif #thisUnits# is "#ctunits.ORIG_LAT_LONG_UNITS#"> selected </cfif>value="#ctunits.ORIG_LAT_LONG_UNITS#">#ctunits.ORIG_LAT_LONG_UNITS#</option>
              </cfloop>
            </select></td>
        </tr>
        <table>
          <table id="llMeta" style="display:none;">
            <tr>
              <td><label for="coordinate_determiner"> Coordinate Determiner </label>
                <input type="text"
					name="coordinate_determiner"
					id="coordinate_determiner"
					class="reqdClr" value="#l.coordinate_determiner#" size="40"
					 onchange="getAgent('DETERMINED_BY_AGENT_ID','coordinate_determiner','loc',this.value); return false;"
					 onKeyPress="return noenter(event);">
                <input type="hidden" name="DETERMINED_BY_AGENT_ID" value="#l.DETERMINED_BY_AGENT_ID#"></td>
              <td><label for="DETERMINED_DATE"> Determined Date </label>
                <input type="text" name="determined_date" id="determined_date"
					value="#dateformat(l.determined_date,'yyyy-mm-dd')#" class="reqdClr"></td>
            </tr>
            <tr>
              <td><label for="MAX_ERROR_DISTANCE"> Maximum Error </label>
                <input type="text" name="MAX_ERROR_DISTANCE" id="MAX_ERROR_DISTANCE" value="#l.MAX_ERROR_DISTANCE#" size="6">
                <select name="MAX_ERROR_UNITS" size="1">
                  <option value=""></option>
                  <cfloop query="cterror">
                    <option <cfif #cterror.LAT_LONG_ERROR_UNITS# is "#l.MAX_ERROR_UNITS#"> selected </cfif>
								value="#cterror.LAT_LONG_ERROR_UNITS#">#cterror.LAT_LONG_ERROR_UNITS#</option>
                  </cfloop>
                </select></td>
              <td><label for="DATUM"> Datum </label>
                <cfset thisDatum = #l.DATUM#>
                <select name="DATUM" id="DATUM" size="1" class="reqdClr">
                  <option value=""></option>
                  <cfloop query="ctdatum">
                    <option <cfif #ctdatum.DATUM# is "#thisDatum#"> selected </cfif>
							value="#ctdatum.DATUM#">#ctdatum.DATUM#</option>
                  </cfloop>
                </select></td>
            </tr>
            <tr>
              <td><label for="georefMethod"> Georeference Method </label>
                <cfset thisGeoMeth = #l.georefMethod#>
                <select name="georefMethod" id="georefMethod" size="1" class="reqdClr" style="width: 300px">
                  <cfloop query="ctGeorefMethod">
                    <option
						<cfif #thisGeoMeth# is #ctGeorefMethod.georefMethod#> selected </cfif>
							value="#georefMethod#">#georefMethod#</option>
                  </cfloop>
                </select></td>
              <td><label for="extent"> Extent </label>
                <input type="text" name="extent" id="extent" value="#l.extent#" size="7"></td>
            </tr>
            <tr>
              <td><label for="GpsAccuracy"> GPS Accuracy </label>
                <input type="text" name="GpsAccuracy" id="GpsAccuracy" value="#l.GpsAccuracy#" size="7"></td>
			</tr>
			<tr>
              <td><label for="VerificationStatus"> Verification Status </label>
                <cfset thisVerificationStatus = #l.VerificationStatus#>
                <select name="VerificationStatus" id="VerificationStatus" size="1" class="reqdClr"
				onchange="if (this.value=='verified by MCZ collection' || this.value=='rejected by MCZ collection')
									{document.getElementById('verified_by').style.display = 'block';
									document.getElementById('verified_byLBL').style.display = 'block';
									document.getElementById('verified_by').className = 'reqdClr';}
									else
									{document.getElementById('verified_by').value = '';
									document.getElementById('verified_by').style.display = 'none';
									document.getElementById('verified_byLBL').style.display = 'none';
									document.getElementById('verified_by').className = '';}">
                  <cfloop query="ctVerificationStatus">
                    <option
							<cfif #thisVerificationStatus# is #ctVerificationStatus.VerificationStatus#> selected </cfif>
								value="#VerificationStatus#">#VerificationStatus#</option>
                  </cfloop>
                </select></td>
				<td>
					<cfset thisVerifiedBy = #l.verifiedby#>
					<cfset thisVerifiedByAgentId = #l.verified_by_agent_id#>
					<label for="verified_by" id="verified_byLBL" <cfif #thisVerificationStatus# EQ "verified by MCZ collection" or #thisVerificationStatus# EQ "rejected by MCZ collection">style="display:block"<cfelse>style="display:none"</cfif>>
						Verified by
					</label>
					<input type="text" name="verified_by" id="verified_by" value="#thisVerifiedBy#" size="25"
						<cfif #thisVerificationStatus# EQ "verified by MCZ collection" or #thisVerificationStatus# EQ "rejected by MCZ collection">class="reqdClr" style="display:block"
						<cfelse>style="display:none"
						</cfif>
						onchange="if (this.value.length > 0){getAgent('verified_by_agent_id','verified_by','loc',this.value); return false;}"
		 				onKeyPress="return noenter(event);">
		 			<input type="hidden" name="verified_by_agent_id" value="#thisVerifiedByAgentId#">
				</td>
            </tr>
            <tr>
              <td colspan="2"><label for="LAT_LONG_REF_SOURCE"> Reference </label>
                <input type="text" name="LAT_LONG_REF_SOURCE" id="LAT_LONG_REF_SOURCE" size="90" class="reqdClr"
					value="#encodeForHTML(l.LAT_LONG_REF_SOURCE)#" /></td>
            </tr>
            <tr>
              <td colspan="3"><label for="LAT_LONG_REMARKS"> Remarks </label>
                <input type="text"
					name="LAT_LONG_REMARKS"
					id="LAT_LONG_REMARKS"
					value="#encodeForHTML(l.LAT_LONG_REMARKS)#"
					size="90"></td>
            </tr>
          </table>
          <table id="decdeg" style="display:none;">
            <tr>
              <td><label for="dec_lat">Decimal Latitude</label>
                <cfinput
					type="text"
					name="dec_lat"
					id="dec_lat"
					value="#l.dec_lat#"
					class="reqdClr"
					validate="numeric"></td>
              <td><label for="dec_long">Decimal Longitude</label>
                <cfinput
					type="text"
					name="DEC_LONG"
					value="#l.DEC_LONG#"
					id="dec_long"
					class="reqdClr"
					validate="numeric"></td>
            </tr>
          </table>
          <table id="dms" style="display:none;">
            <tr>
              <td><label for="lat_deg">Lat. Deg.</label>
                <cfinput type="text" name="LAT_DEG" value="#l.LAT_DEG#" size="4" id="lat_deg" class="reqdClr"
					validate="numeric"></td>
              <td><label for="lat_min">Lat. Min.</label>
                <cfinput type="text" name="LAT_MIN" value="#l.LAT_MIN#" size="4" id="lat_min" class="reqdClr"
					validate="numeric"></td>
              <td><label for="lat_sec">Lat. Sec.</label>
                <cfinput type="text" name="LAT_SEC" value="#l.LAT_SEC#" id="lat_sec" class="reqdClr"
					validate="numeric"></td>
              <td><label for="lat_dir">Lat. Dir.</label>
                <select name="LAT_DIR" size="1" id="lat_dir"  class="reqdClr">
                  <option value=""></option>
                  <option <cfif #l.LAT_DIR# is "N"> selected </cfif>value="N">N</option>
                  <option <cfif #l.LAT_DIR# is "S"> selected </cfif>value="S">S</option>
                </select></td>
            </tr>
            <tr>
              <td><label for="long_deg">Long. Deg.</label>
                <cfinput type="text" name="LONG_DEG" value="#l.LONG_DEG#" size="4" id="long_deg" class="reqdClr"
					validate="numeric"></td>
              <td><label for="long_min">Long. Min.</label>
                <cfinput type="text" name="LONG_MIN" value="#l.LONG_MIN#" size="4" id="long_min" class="reqdClr"
					validate="numeric"></td>
              <td><label for="long_sec">Long. Sec.</label>
                <cfinput type="text" name="LONG_SEC" value="#l.LONG_SEC#" id="long_sec"  class="reqdClr"
					validate="numeric"></td>
              <td><label for="long_dir">Long. Dir.</label>
                <select name="LONG_DIR" size="1" id="long_dir" class="reqdClr">
                  <option value=""></option>
                  <option <cfif #l.LONG_DIR# is "E"> selected </cfif>value="E">E</option>
                  <option <cfif #l.LONG_DIR# is "W"> selected </cfif>value="W">W</option>
                </select></td>
            </tr>
          </table>
          <table id="ddm" style="display:none;">
              <tr>

              <td>

              <label for="dmlat_deg">
            Lat. Deg.
              <label>

            <input type="text" name="dmLAT_DEG" value="#l.LAT_DEG#" size="4" id="dmlat_deg" class="reqdClr">
              </td>

              <td>

              <label for="dec_lat_min">
            Lat. Dec. Min.
              <label>

            <cfinput type="text" name="DEC_LAT_MIN" value="#l.DEC_LAT_MIN#" id="dec_lat_min" class="reqdClr"
					validate="numeric">
              </td>

              <td>

              <label for="dmlat_dir">
            Lat. Dir.
              <label>

            <select name="dmLAT_DIR" size="1" id="dmlat_dir" class="reqdClr">
              <option value=""></option>
              <option <cfif #l.LAT_DIR# is "N"> selected </cfif>value="N">N</option>
              <option <cfif #l.LAT_DIR# is "S"> selected </cfif>value="S">S</option>
            </select>
              </td>

              </tr>

              <tr>

              <td>

              <label for="dmlong_deg">
            Long. Deg.
              <label>

            <cfinput type="text" name="dmLONG_DEG" value="#l.LONG_DEG#" size="4" id="dmlong_deg" class="reqdClr"
					validate="numeric">
              </td>

              <td>

              <label for="dec_long_min">
            Long. Dec. Min.
              <label>

            <cfinput type="text" name="DEC_LONG_MIN" value="#l.DEC_LONG_MIN#" id="dec_long_min" class="reqdClr"
					validate="numeric">
              </td>

              <td>

              <label for="dmlong_dir">
            Long. Dir.
              <label>

            <select name="dmLONG_DIR" size="1" id="dmlong_dir" class="reqdClr">
              <option value=""></option>
              <option <cfif #l.LONG_DIR# is "E"> selected </cfif>value="E">E</option>
              <option <cfif #l.LONG_DIR# is "W"> selected </cfif>value="W">W</option>
            </select>
              </td>

              </tr>

          </table>
          <table id="utm" style="display:none;">
              <tr>

              <td>

              <label for="utm_zone">
            UTM Zone
              <label>

            <cfinput type="text" name="UTM_ZONE" value="#l.UTM_ZONE#" id="utm_zone" class="reqdClr"
					validate="numeric">
              </td>

              <td>

              <label for="utm_ew">
            UTM East/West
              <label>

            <cfinput type="text" name="UTM_EW" value="#l.UTM_EW#" id="utm_ew" class="reqdClr"
					validate="numeric">
              </td>

              <td>

              <label for="utm_ns">
            UTM North/South
              <label>

            <cfinput type="text" name="UTM_NS" value="#l.UTM_NS#" id="utm_ns" class="reqdClr"
					validate="numeric">
              </td>

              </tr>

              </td>

          </table>
          <table>

                   <tr>
              <td><label>Verbatim Coordinates (summary)</label>
                <cfinput type="text"
					name="verbatimCoordinates"
					id="verbatimCoordinates"
					value="#stripQuotes(l.verbatimCoordinates)#"
					size="80"
					></td>
            </tr>
          </table>
          <table>
            <tr>
              <td style="padding-right: 1em;"><label>Verbatim Latitude</label>
                <cfinput type="text"
					name="verbatimLatitude"
					id="verbatimLatitude"
					value="#stripQuotes(l.verbatimLatitude)#"
					size="36"
					></td>
              <td><label>Verbatim Longitude</label>
                <cfinput type="text"
					name="verbatimLongitude"
					id="verbatimLongitude"
					value="#stripQuotes(l.verbatimLongitude)#"
					size="36"
					></td>
            </tr>
          </table>
          <table>
            <tr>
              <td style="padding-right: 1em;"><label>Verbatim Coordinate System (e.g., decimal degrees)</label>
                <cfinput type="text"
					name="verbatimCoordinateSystem"
					id="verbatimCoordinateSystem"
					value="#stripQuotes(l.verbatimCoordinateSystem)#"
					size="39"
					></td>
              <td><label>Verbatim SRS (e.g., datum)</label>
                <cfinput type="text"
					name="verbatimSRS"
					id="verbatimSRS"
					value="#stripQuotes(l.verbatimSRS)#"
					size="33"
					></td>
            </tr>
          </table>
 <!---         <table id="vc">
              <tr>

              <td colspan="2">
              <label for="verbatimCoordinates">
            Verbatim Coordinates
              <label>

            <cfinput type="text" name="verbatimCoordinates" value="#l.verbatimCoordinates#" id="verbatimCoordinates">
              </td>

              <td >
              <label for="verbatimLatitude">
            Verbatim Latitude
              <label>

            <cfinput type="text" name="verbatimLatitude" value="#l.verbatimLatitude#" id="verbatimLatitude" size="4">
              </td>

              <td >
              <label for="verbatimLongitude">
            Verbatim Longitude
              <label>

            <cfinput type="text" name="verbatimLongitude" value="#l.verbatimLongitude#" id="verbatimLongitude" size="4">
              </td>

              </tr>

              <tr>

              <td >
              <label for="verbatimCoordinateSystem">
            Verbatim Coordinate System
              <label>

            <cfinput type="text" name="verbatimCoordinateSystem" value="#l.verbatimCoordinateSystem#" id="verbatimCoordinateSystem">
              </td>

              <td >
              <label for="verbatimSRS">
            Verbatim SRS
              <label>

            <cfinput type="text" name="verbatimSRS" value="#l.verbatimSRS#" id="verbatimSRS">
              </td>

              </tr>

          </table>--->
            <label for="gTab">
          Geology
            <label>

          <table id="gTab" border="1" cellpadding="0" cellspacing="0">
            <tr>
              <td>Attribute</td>
              <td>Value</td>
              <td>Determiner</td>
              <td>Date</td>
              <td>Method</td>
              <td>Remark</td>
              <td></td>
            </tr>
            <cfloop query="g">
              <tr>
                <td><cfset thisAttribute=g.geology_attribute>
                  <select name="geology_attribute__#geology_attribute_id#"
				id="geology_attribute__#geology_attribute_id#" size="1" class="reqdClr" onchange="populateGeology(this.id)">
                    <option value="">DELETE THIS ROW</option>
                    <cfloop query="ctgeology_attribute">
                      <option
					<cfif thisAttribute is geology_attribute> selected="selected" </cfif>
						value="#geology_attribute#">#geology_attribute#</option>
                    </cfloop>
                  </select></td>
                <td><select id="geo_att_value__#geology_attribute_id#" class="reqdClr"
				name="geo_att_value__#geology_attribute_id#">
                    <option value="#geo_att_value#">#geo_att_value#</option>
                  </select></td>
                <td><input type="text" id="geo_att_determiner__#geology_attribute_id#"
				name="geo_att_determiner__#geology_attribute_id#" value="#geo_att_determiner#"
				size="15"
				onchange="getAgent('geo_att_determiner_id__#geology_attribute_id#','geo_att_determiner__#geology_attribute_id#','loc',this.value); return false;">
                  <input type="hidden" name="geo_att_determiner_id__#geology_attribute_id#"
				id="geo_att_determiner_id__#geology_attribute_id#" value="#geo_att_determiner_id#"></td>
                <td><input type="text" id="geo_att_determined_date__#geology_attribute_id#"
				name="geo_att_determined_date__#geology_attribute_id#"
				value="#dateformat(geo_att_determined_date,'yyyy-mm-dd')#"
				size="10"></td>
                <td><input type="text" id="geo_att_determined_method__#geology_attribute_id#"
				name="geo_att_determined_method__#geology_attribute_id#" value="#geo_att_determined_method#"
				size="10"></td>
                <td><input type="text" id="geo_att_remark__#geology_attribute_id#"
				name="geo_att_remark__#geology_attribute_id#" value="#geo_att_remark#"
				size="10"></td>
                <td><img src="/images/del.gif" class="likeLink" onclick="document.getElementById('geology_attribute__#geology_attribute_id#').value='';"></td>
              </tr>
            </cfloop>
            <tr class="newRec">
              <td colspan="6">New Geology Attribute</td>
            </tr>
            <tr  class="newRec">
              <td><select name="geology_attribute"  onchange="populateGeology(this.id)"
				id="geology_attribute" size="1" class="reqdClr">
                  <option value=""></option>
                  <cfloop query="ctgeology_attribute">
                    <option value="#geology_attribute#">#geology_attribute#</option>
                  </cfloop>
                </select></td>
              <td><select id="geo_att_value" class="reqdClr"  name="geo_att_value">
                </select></td>
              <td><input type="text" id="geo_att_determiner"
				name="geo_att_determiner"
				size="15"
				onchange="getAgent('geo_att_determiner_id','geo_att_determiner','loc',this.value); return false;">
                <input type="hidden" name="geo_att_determiner_id"
				id="geo_att_determiner_id"></td>
              <td><input type="text" id="geo_att_determined_date"
				name="geo_att_determined_date"
				size="10"></td>
              <td><input type="text" id="geo_att_determined_method"
				name="geo_att_determined_method"
				size="10"></td>
              <td><input type="text" id="geo_att_remark"
				name="geo_att_remark"
				size="10"></td>
            </tr>
          </table>
            </td>

            </tr>

          <tr>
            <td colspan="2" align="center">
            <cfif loccount.ct eq 1 and cecount.ct eq 1>
                <input type="submit" value="Save Changes" class="savBtn"
   				    onmouseover="this.className='savBtn btnhov';this.focus();" onmouseout="this.className='savBtn'">
            <cfelse>
                <span>
                <input type="submit" value="Split and Save Changes" class="savBtn"
   				    onmouseover="this.className='savBtn btnhov';this.focus();" onmouseout="this.className='savBtn'">
                A new locality and collecting event will be created with these values and changes will apply to this record only.
                </span>
            </cfif>
            </td>
          </tr>
        </table>
      </cfform>
      <script>
		showLLFormat('#l.ORIG_LAT_LONG_UNITS#');
	</script>
    </cfoutput> </div>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif #action# is "saveChange">
  <cfoutput>
    <cfset btime=now()>
    <cfset maxNumGeolAtts=10>
    <!--- wild overestimation of the maximum number of geologic attributes; guess high or this form dies --->
    <cftransaction>
      <cfquery name="old"  datasource="uam_god">
			SELECT
				locality_id,
				collecting_event_id
			FROM
	    		spec_with_loc
	    	WHERE collection_object_id=#collection_object_id#
		</cfquery>
      <cfquery name="geog"  datasource="uam_god">
			select min(geog_auth_rec_id) geog_auth_rec_id from geog_auth_rec where higher_geog = '#escapeQuotes(higher_geog)#'
		</cfquery>
      <cfif len(geog.geog_auth_rec_id) is 0>
        <div class="error">Geography not found.</div>
        <cfabort>
        <cfelse>
        <cfset nGeogId=geog.geog_auth_rec_id>
      </cfif>
      <cfset fLocS="select min(locality_id) locality_id
				FROM
					loc_acc_lat_long
				WHERE
    				geog_auth_rec_id = #nGeogId# AND
    				NVL(MAXIMUM_ELEVATION,-1) = NVL('#maximum_elevation#',-1) AND
					NVL(MINIMUM_ELEVATION,-1) = NVL('#minimum_elevation#',-1) AND
					NVL(ORIG_ELEV_UNITS,'NULL') = NVL('#orig_elev_units#','NULL') AND
					NVL(MIN_DEPTH,-1) = nvl('#min_depth#',-1) AND
					NVL(MAX_DEPTH,-1) = nvl('#max_depth#',-1) AND
					NVL(SPEC_LOCALITY,'NULL') = NVL('#escapeQuotes(spec_locality)#','NULL') AND
					NVL(SOVEREIGN_NATION,'NULL') = NVL('#escapeQuotes(sovereign_nation)#','NULL') AND
					NVL(LOCALITY_REMARKS,'NULL') = NVL('#escapeQuotes(locality_remarks)#','NULL') AND
					NVL(DEPTH_UNITS,'NULL') = NVL('#depth_units#','NULL') AND
					NVL(NOGEOREFBECAUSE,'NULL') = NVL('#escapeQuotes(nogeorefbecause)#','NULL')  AND
					NVL(orig_lat_long_units,'NULL') = NVL('#orig_lat_long_units#','NULL') AND
					NVL(datum,'NULL') = NVL('#datum#','NULL') AND
					NVL(determined_by_agent_id,-1) = nvl('#determined_by_agent_id#',-1) AND
					NVL(determined_date,'1600-01-01') = NVL(to_date('#determined_date#'),'1600-01-01') AND
					NVL(lat_long_ref_source,'NULL') = NVL('#escapeQuotes(lat_long_ref_source)#','NULL') AND
					NVL(lat_long_remarks,'NULL') = NVL('#escapeQuotes(lat_long_remarks)#','NULL')  AND
					NVL(max_error_distance,-1) = nvl('#max_error_distance#',-1) AND
					NVL(max_error_units,'NULL') = NVL('#max_error_units#','NULL') AND
					NVL(extent,-1) = nvl('#extent#',-1) AND
					NVL(gpsaccuracy,-1) = nvl('#gpsaccuracy#',-1) AND
					NVL(georefmethod,'NULL') = NVL('#georefmethod#','NULL')  AND
					NVL(verificationstatus,'NULL') = NVL('#escapeQuotes(verificationstatus)#','NULL') AND
					NVL(verified_by_agent_id, -1) = NVL('#verified_by_agent_id#', -1) AND
					NVL(DEC_LAT,-1) = nvl('#DEC_LAT#',-1) AND
					NVL(DEC_LONG,-1) = nvl('#DEC_LONG#',-1) AND
					NVL(UTM_EW,-1) = nvl('#UTM_EW#',-1) AND
					NVL(UTM_NS,-1) = nvl('#UTM_NS#',-1) AND
					NVL(UTM_ZONE,'NULL') = NVL('#UTM_ZONE#','NULL') AND">
      <cfif orig_lat_long_units is "degrees dec. minutes">
        <cfset fLocS=fLocS & " NVL(LAT_DEG,-1) = nvl('#dmLAT_DEG#',-1) AND
							NVL(LAT_DIR,'NULL') = NVL('#dmlat_dir#','NULL') AND
							NVL(LONG_DEG,-1) = nvl('#dmLONG_DEG#',-1) AND
							NVL(LONG_DIR,'NULL') = NVL('#dmlong_dir#','NULL') AND">
        <cfelse>
        <cfset fLocS=fLocS & " NVL(LAT_DEG,-1) = nvl('#LAT_DEG#',-1) AND
							NVL(LAT_DIR,'NULL') = NVL('#LAT_DIR#','NULL') AND
							NVL(LONG_DEG,-1) = nvl('#LONG_DEG#',-1) AND
							NVL(LONG_DIR,'NULL') = NVL('#LONG_DIR#','NULL') AND">
      </cfif>
      <cfset fLocS=fLocS & " NVL(DEC_LAT_MIN,-1) = nvl('#DEC_LAT_MIN#',-1) AND
					NVL(DEC_LONG_MIN,-1) = nvl('#DEC_LONG_MIN#',-1) AND
					NVL(LAT_MIN,-1) = nvl('#LAT_MIN#',-1) AND
					NVL(LAT_SEC,-1) = nvl('#LAT_SEC#',-1) AND
					NVL(LONG_MIN,-1) = nvl('#LONG_MIN#',-1) AND
					NVL(LONG_SEC,-1) = nvl('#LONG_SEC#',-1)
		">
      <!--- see if there are any geology attributes to deal with --->
      <!---
		<cfdump var="#form#">
		<cfdump var="#variables#">
		--->
      <cfset ffldn=form.fieldnames>
      <cfdump var="#ffldn#">
      <cfset hasGeol=0>
      <cfset gattlst="">
      <cfloop from="1" to="#maxNumGeolAtts#" index="i">
        <cfset isGeo=ListContainsNoCase(ffldn,"GEOLOGY_ATTRIBUTE__")>
        <cfif isGeo gt 0>
          <cfset hasGeol=1>
          <cfset geo=listgetat(ffldn,isGeo)>
          <cfset thisGeoAttId=replace(geo,"GEOLOGY_ATTRIBUTE__","")>
          <cfset thisGeoAtt=evaluate("GEOLOGY_ATTRIBUTE__" & thisGeoAttId)>
          <cfset thisGeoAttValue=evaluate("GEO_ATT_VALUE__" & thisGeoAttId)>
          <cfset thisGeoDeterminerId=evaluate("GEO_ATT_DETERMINER_id__" & thisGeoAttId)>
          <cfset thisGeoAttDate=evaluate("GEO_ATT_DETERMINED_DATE__" & thisGeoAttId)>
          <cfset thisGeoAttMeth=evaluate("GEO_ATT_DETERMINED_METHOD__" & thisGeoAttId)>
          <cfset thisGeoAttRemark=evaluate("GEO_ATT_REMARK__" & thisGeoAttId)>
          <cfquery name="gatt"  datasource="uam_god">
					select min(GEOLOGY_ATTRIBUTE_ID) GEOLOGY_ATTRIBUTE_ID from geology_attributes where
						GEOLOGY_ATTRIBUTE='#thisGeoAtt#' and
						GEO_ATT_VALUE='#escapeQuotes(thisGeoAttValue)#' and
						nvl(GEO_ATT_DETERMINER_ID,-1)=nvl('#thisGeoDeterminerId#',-1) and
						NVL(GEO_ATT_DETERMINED_DATE,'1600-01-01') = NVL(to_date('#thisGeoAttDate#'),'1600-01-01') AND
						NVL(GEO_ATT_DETERMINED_METHOD,'NULL') = NVL('#escapeQuotes(thisGeoAttMeth)#','NULL') AND
						NVL(GEO_ATT_REMARK,'NULL') = NVL('#escapeQuotes(thisGeoAttRemark)#','NULL')
				</cfquery>
          <cfif len(gatt.GEOLOGY_ATTRIBUTE_ID) is 0>
            <!--- no such attribute already esists, make sure we return nothing --->
            <cfset gattlst=listappend(gattlst,-1)>
            <cfelse>
            <cfset gattlst=listappend(gattlst,gatt.GEOLOGY_ATTRIBUTE_ID)>
            <cfset fLocS=fLocS & " and loc_acc_lat_long.locality_id IN (select locality_id from
						geology_attributes where GEOLOGY_ATTRIBUTE_ID=#gatt.GEOLOGY_ATTRIBUTE_ID#)">
          </cfif>
          <cfloop from="1" to="#isGeo#" index="l">
            <cfset ffldn=listdeleteat(ffldn,1)>
          </cfloop>
        </cfif>
      </cfloop>
      <cfif len(geology_attribute) gt 0>
        <!--- new attribute --->
        were making a new geology_attribute
        <cfset hasGeol=1>
        <cfquery name="gatt"  datasource="uam_god">
				select min(GEOLOGY_ATTRIBUTE_ID) GEOLOGY_ATTRIBUTE_ID from geology_attributes where
					GEOLOGY_ATTRIBUTE='#escapeQuotes(geology_attribute)#' and
					GEO_ATT_VALUE='#escapeQuotes(geo_att_value)#' and
					nvl(GEO_ATT_DETERMINER_ID,-1)=nvl('#geo_att_determiner_id#',-1) and
					NVL(GEO_ATT_DETERMINED_DATE,'1600-01-01') = NVL(to_date('#geo_att_determined_date#'),'1600-01-01') AND
					NVL(GEO_ATT_DETERMINED_METHOD,'NULL') = NVL('#escapeQuotes(geo_att_determined_method)#','NULL') AND
					NVL(GEO_ATT_REMARK,'NULL') = NVL('#escapeQuotes(geo_att_remark)#','NULL')
			</cfquery>
        <cfif len(gatt.GEOLOGY_ATTRIBUTE_ID) is 0>
          <!--- no such attribute already esists, make sure we return nothing --->
          .....no such attribute already esists.....
          <cfset gattlst=listappend(gattlst,-1)>
          <cfelse>
          <cfset gattlst=listappend(gattlst,gatt.GEOLOGY_ATTRIBUTE_ID)>
          <cfset fLocS=fLocS & " and loc_acc_lat_long.locality_id IN (select locality_id from
					geology_attributes where GEOLOGY_ATTRIBUTE_ID=#gatt.GEOLOGY_ATTRIBUTE_ID#)">
        </cfif>
      </cfif>
      <cfif hasGeol is 0>
        hasGeol is 0.....
        <cfset fLocS=fLocS & " and loc_acc_lat_long.locality_id NOT IN (select locality_id from geology_attributes)">
        <cfelse>
        hasGeol is NOT 0....
        <cfset fLocS=fLocS & " and loc_acc_lat_long.locality_id NOT IN (select locality_id from
				geology_attributes where GEOLOGY_ATTRIBUTE_ID not in (#gattlst#))">
      </cfif>
      <cfquery name="isLoc"  datasource="uam_god">
			#preservesinglequotes(fLocS)#
		</cfquery>
      <hr>
      #preservesinglequotes(fLocS)#
      <hr>
      ran the query....
      <cfset nLocalityId=isLoc.locality_id>
      <cfif len(nLocalityId) is 0>
        makin a locality....
        <cfset etime=now()>
        <cfset tt=DateDiff("s", btime, etime)>
        <br>
        Runtime: #tt#

        <!--- need to make a locality --->
        <cfquery name="nlid" datasource="uam_god">
				select sq_locality_id.nextval nlid from dual
			</cfquery>
        got locid
        <cfset etime=now()>
        <cfset tt=DateDiff("s", btime, etime)>
        <br>
        Runtime: #tt#
        <cfset nLocalityId=nlid.nlid>
        <cfquery name="nLoc" datasource="uam_god">
				insert into locality (
					LOCALITY_ID,
					GEOG_AUTH_REC_ID,
					MAXIMUM_ELEVATION,
					MINIMUM_ELEVATION,
					ORIG_ELEV_UNITS,
					SPEC_LOCALITY,
					LOCALITY_REMARKS,
					DEPTH_UNITS,
					MIN_DEPTH,
					MAX_DEPTH,
					NOGEOREFBECAUSE,
                    SOVEREIGN_NATION
				) values (
                    <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#nlid.nlid#">,
                    <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#nGeogId#">,
					<cfif len(MAXIMUM_ELEVATION) gt 0>
                        <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#MAXIMUM_ELEVATION#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(MINIMUM_ELEVATION) gt 0>
                        <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#MINIMUM_ELEVATION#">,
					<cfelse>
						NULL,
					</cfif>
                    <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#ORIG_ELEV_UNITS#">,
                    <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#SPEC_LOCALITY#">,
                    <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#LOCALITY_REMARKS#">,
                    <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#DEPTH_UNITS#">,
					<cfif len(MIN_DEPTH) gt 0>
                        <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#MIN_DEPTH#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(MAX_DEPTH) gt 0>
                        <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#MAX_DEPTH#">,
					<cfelse>
						NULL,
					</cfif>
                    <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#NOGEOREFBECAUSE#">,
                    <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#sovereign_nation#">
				)
	    </cfquery>
        made loc....
        <cfset etime=now()>
        <cfset tt=DateDiff("s", btime, etime)>
        <br>
        Runtime: #tt#

        <!--- and new geology.... --->
        <cfset ffldn=form.fieldnames>
        <cfloop from="1" to="#maxNumGeolAtts#" index="i">
          <cfset isGeo=ListContainsNoCase(ffldn,"GEOLOGY_ATTRIBUTE__")>
          <cfif isGeo gt 0>
            geology loop....
            <cfset geo=listgetat(ffldn,isGeo)>
            <cfset thisGeoAttId=replace(geo,"GEOLOGY_ATTRIBUTE__","")>
            <cfset thisGeoAtt=evaluate("GEOLOGY_ATTRIBUTE__" & thisGeoAttId)>
            <cfset thisGeoAttValue=evaluate("GEO_ATT_VALUE__" & thisGeoAttId)>
            <cfset thisGeoDeterminerId=evaluate("GEO_ATT_DETERMINER_id__" & thisGeoAttId)>
            <cfset thisGeoAttDate=evaluate("GEO_ATT_DETERMINED_DATE__" & thisGeoAttId)>
            <cfset thisGeoAttMeth=evaluate("GEO_ATT_DETERMINED_METHOD__" & thisGeoAttId)>
            <cfset thisGeoAttRemark=evaluate("GEO_ATT_REMARK__" & thisGeoAttId)>
            <cfif len(thisGeoAtt) gt 0>
              <!--- NULL=delete attribute --->
              <cfquery name="newGeo"  datasource="uam_god">
						insert into geology_attributes (
							locality_id,
							GEOLOGY_ATTRIBUTE,
							GEO_ATT_VALUE,
							GEO_ATT_DETERMINER_ID,
							GEO_ATT_DETERMINED_DATE,
							GEO_ATT_DETERMINED_METHOD,
							GEO_ATT_REMARK
						) values (
							#nlid.nlid#,
							'#thisGeoAtt#',
							'#escapeQuotes(thisGeoAttValue)#',
							<cfif len(thisGeoDeterminerId) gt 0>
								#thisGeoDeterminerId#,
							<cfelse>
								NULL,
							</cfif>
							to_date('#dateformat(thisGeoAttDate,"yyyy-mm-dd")#'),
							'#escapeQuotes(thisGeoAttMeth)#',
							'#escapeQuotes(thisGeoAttRemark)#'
						)
					</cfquery>
            </cfif>
            <cfloop from="1" to="#isGeo#" index="l">
              <cfset ffldn=listdeleteat(ffldn,1)>
            </cfloop>
          </cfif>
        </cfloop>
        <cfif len(geology_attribute) gt 0>
          <!--- new attribute --->
          <cfquery name="newGeo"  datasource="uam_god">
					insert into geology_attributes (
						locality_id,
						GEOLOGY_ATTRIBUTE,
						GEO_ATT_VALUE,
						GEO_ATT_DETERMINER_ID,
						GEO_ATT_DETERMINED_DATE,
						GEO_ATT_DETERMINED_METHOD,
						GEO_ATT_REMARK
					) values (
						#nlid.nlid#,
						'#geology_attribute#',
						'#escapeQuotes(geo_att_value)#',
						<cfif len(geo_att_determiner_id) gt 0>
							#geo_att_determiner_id#,
						<cfelse>
							NULL,
						</cfif>
						to_date('#dateformat(geo_att_determined_date,"yyyy-mm-dd")#'),
						'#escapeQuotes(geo_att_determined_method)#',
						'#escapeQuotes(geo_att_remark)#'
					)
				</cfquery>
        </cfif>
        <cfif len(orig_lat_long_units) gt 0>
          coordinates.....
          <cfset etime=now()>
          <cfset tt=DateDiff("s", btime, etime)>
          <br>
          Runtime: #tt# got llid....
          <cfset etime=now()>
          <cfset tt=DateDiff("s", btime, etime)>
          <br>
          Runtime: #tt# <br>
          gonna try this:
          <cfquery name="newCoor" datasource="uam_god">
					INSERT INTO lat_long (
						LAT_LONG_ID,
						LOCALITY_ID,
						LAT_DEG,
						DEC_LAT_MIN,
						LAT_MIN,
						LAT_SEC,
						LAT_DIR,
						LONG_DEG,
						DEC_LONG_MIN,
						LONG_MIN,
						LONG_SEC,
						LONG_DIR,
						DEC_LAT,
						DEC_LONG,
						DATUM,
						UTM_ZONE,
						UTM_EW,
						UTM_NS,
						ORIG_LAT_LONG_UNITS,
						DETERMINED_BY_AGENT_ID,
						DETERMINED_DATE,
						LAT_LONG_REF_SOURCE,
						LAT_LONG_REMARKS,
						MAX_ERROR_DISTANCE,
						MAX_ERROR_UNITS,
						ACCEPTED_LAT_LONG_FG,
						EXTENT,
						GPSACCURACY,
						GEOREFMETHOD,
						VERIFICATIONSTATUS,
						VERIFIED_BY_AGENT_ID
					) values (
						sq_lat_long_id.nextval,
						#nlid.nlid#,
						<cfif len(LAT_DEG) gt 0 or len(dmLAT_DEG) gt 0>
							<cfif orig_lat_long_units is "degrees dec. minutes">
								#dmLAT_DEG#,
							<cfelse>
								#LAT_DEG#,
							</cfif>
						<cfelse>
							NULL,
						</cfif>
						<cfif len(DEC_LAT_MIN) gt 0>
							#DEC_LAT_MIN#,
						<cfelse>
							NULL,
						</cfif>
						<cfif len(LAT_MIN) gt 0>
							#LAT_MIN#,
						<cfelse>
							NULL,
						</cfif>
						<cfif len(LAT_SEC) gt 0>
							#LAT_SEC#,
						<cfelse>
							NULL,
						</cfif>
						<cfif orig_lat_long_units is "degrees dec. minutes">
							'#dmLAT_DIR#',
						<cfelse>
							'#LAT_DIR#',
						</cfif>
						<cfif len(LONG_DEG) gt 0 or len(dmLONG_DEG) gt 0>
							<cfif orig_lat_long_units is "degrees dec. minutes">
								#dmLONG_DEG#,
							<cfelse>
								#LONG_DEG#,
							</cfif>
						<cfelse>
							NULL,
						</cfif>
						<cfif len(DEC_LONG_MIN) gt 0>
							#DEC_LONG_MIN#,
						<cfelse>
							NULL,
						</cfif>
						<cfif len(LONG_MIN) gt 0>
							#LONG_MIN#,
						<cfelse>
							NULL,
						</cfif>
						<cfif len(LONG_SEC) gt 0>
							#LONG_SEC#,
						<cfelse>
							NULL,
						</cfif>
						<cfif orig_lat_long_units is "degrees dec. minutes">
							'#dmLONG_DIR#',
						<cfelse>
							'#LONG_DIR#',
						</cfif>
						<cfif len(DEC_LAT) gt 0>
							#DEC_LAT#,
						<cfelse>
							NULL,
						</cfif>
						<cfif len(DEC_LONG) gt 0>
							#DEC_LONG#,
						<cfelse>
							NULL,
						</cfif>
						<cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#DATUM#">,
						<cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#UTM_ZONE#">,
						<cfif len(UTM_EW) gt 0>
						    <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#UTM_EW#">,
						<cfelse>
							NULL,
						</cfif>
						<cfif len(UTM_NS) gt 0>
						    <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#UTM_NS#">,
						<cfelse>
							NULL,
						</cfif>
						<cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#ORIG_LAT_LONG_UNITS#">,
						<cfif len(DETERMINED_BY_AGENT_ID) gt 0>
						    <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#DETERMINED_BY_AGENT_ID#">,
						<cfelse>
							NULL,
						</cfif>
						to_date('#DETERMINED_DATE#'),
						<cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#LAT_LONG_REF_SOURCE#">,
						<cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#LAT_LONG_REMARKS#">,
						<cfif len(MAX_ERROR_DISTANCE) gt 0>
						    <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#MAX_ERROR_DISTANCE#">,
						<cfelse>
							NULL,
						</cfif>
						'#MAX_ERROR_UNITS#',
						1,
						<cfif len(EXTENT) gt 0>
							#EXTENT#,
						<cfelse>
							NULL,
						</cfif>
						<cfif len(GPSACCURACY) gt 0>
							#GPSACCURACY#,
						<cfelse>
							NULL,
						</cfif>
						'#escapeQuotes(GEOREFMETHOD)#',
						'#escapeQuotes(VERIFICATIONSTATUS)#',
						<cfif len(verified_by_agent_id) GT 0 and len(verified_by) GT 0>
							<cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#VERIFIED_BY_AGENT_ID#">
						<cfelse>
							NULL
						</cfif>
					)
				</cfquery>
          inserted coordinates......
          <cfset etime=now()>
          <cfset tt=DateDiff("s", btime, etime)>
          <br>
          Runtime: #tt#
        </cfif>
      </cfif>
      <!--- end make new locality --->
      <!--- we now have a locality --->
      <cfquery name="hasColl" datasource="uam_god">
			select
	 			nvl(min(collecting_event_id),-1) collecting_event_id
			FROM
				collecting_event
			WHERE
				locality_id = #nLocalityId# AND
				NVL(VERBATIM_DATE,'NULL') = NVL('#VERBATIM_DATE#','NULL') AND
				NVL(BEGAN_DATE,'1600-01-01') = NVL('#BEGAN_DATE#','1600-01-01') AND
				NVL(ENDED_DATE,'1600-01-01') = NVL('#ENDED_DATE#','1600-01-01') AND
				NVL(VERBATIM_LOCALITY,'NULL') = NVL('#escapeQuotes(VERBATIM_LOCALITY)#','NULL') AND
				NVL(COLL_EVENT_REMARKS,'NULL') = NVL('#escapeQuotes(COLL_EVENT_REMARKS)#','NULL') AND
				NVL(COLLECTING_SOURCE,'NULL') = NVL('#escapeQuotes(COLLECTING_SOURCE)#','NULL') AND
				NVL(COLLECTING_METHOD,'NULL') = NVL('#escapeQuotes(COLLECTING_METHOD)#','NULL') AND
				NVL(HABITAT_DESC,'NULL') = NVL('#escapeQuotes(HABITAT_DESC)#','NULL') AND
				NVL(COLLECTING_TIME,'NULL') = NVL('#escapeQuotes(COLLECTING_TIME)#','NULL') AND
				NVL(FISH_FIELD_NUMBER,'NULL') = NVL('#escapeQuotes(ICH_FIELD_NUMBER)#','NULL') AND
				NVL(verbatimCoordinates,'NULL') = NVL('#escapeQuotes(verbatimCoordinates)#','NULL') AND
				NVL(verbatimLatitude,'NULL') = NVL('#escapeQuotes(verbatimLatitude)#','NULL') AND
				NVL(verbatimLongitude,'NULL') = NVL('#escapeQuotes(verbatimLongitude)#','NULL') AND
				NVL(verbatimCoordinateSystem,'NULL') = NVL('#escapeQuotes(verbatimCoordinateSystem)#','NULL') AND
				NVL(verbatimSRS,'NULL') = NVL('#escapeQuotes(verbatimSRS)#','NULL') AND
				NVL(startDayOfYear,-999) = NVL('#startDayOfYear#',-999) AND
				NVL(endDayOfYear,-999) = NVL('#endDayOfYear#',-999)

		</cfquery>
      gor event....
      <cfif hasColl.collecting_event_id is -1>
        <!--- need a collecting event --->
        <cfquery name="ncid" datasource="uam_god">
				select sq_collecting_event_id.nextval ncid from dual
			 </cfquery>
        <cfset ncollecting_event_id=ncid.ncid>
        making event....
        <cfquery name="newEvent" datasource="uam_god">
				INSERT INTO collecting_event (
					COLLECTING_EVENT_ID,
					LOCALITY_ID,
					BEGAN_DATE,
					ENDED_DATE,
					VERBATIM_DATE,
					VERBATIM_LOCALITY,
					COLL_EVENT_REMARKS,
					COLLECTING_SOURCE,
					COLLECTING_METHOD,
					HABITAT_DESC,
					COLLECTING_TIME,
					FISH_FIELD_NUMBER,
					verbatimCoordinates,
					verbatimLatitude,
					verbatimLongitude,
					verbatimCoordinateSystem,
					verbatimSRS,
					startDayOfYear,
					endDayOfYear
				) values (
					#ncollecting_event_id#,
					#nLocalityId#,
					'#began_date#',
					'#ended_date#',
					'#escapeQuotes(verbatim_date)#',
					'#escapeQuotes(verbatim_locality)#',
					'#escapeQuotes(coll_event_remarks)#',
					'#escapeQuotes(collecting_source)#',
					'#escapeQuotes(collecting_method)#',
					'#escapeQuotes(habitat_desc)#',
					'#escapeQuotes(COLLECTING_TIME)#',
					'#escapeQuotes(ich_field_number)#',
					'#escapeQuotes(verbatimCoordinates)#',
					'#escapeQuotes(verbatimLatitude)#',
					'#escapeQuotes(verbatimLongitude)#',
					'#escapeQuotes(verbatimCoordinateSystem)#',
					'#escapeQuotes(verbatimSRS)#',
					'#escapeQuotes(startDayOfYear)#',
					'#escapeQuotes(endDayOfYear)#'
				)
			</cfquery>
        <cfelse>
        <cfset ncollecting_event_id=hasColl.collecting_event_id>
      </cfif>
      event spiffy....
      <cfquery name="upCatItem" datasource="uam_god">
			update cataloged_item set
    			collecting_event_id = #ncollecting_event_id#
    		where collection_object_id = #collection_object_id#
		</cfquery>
      updated catitem....
      <cfquery name="canKill"  datasource="uam_god">
			SELECT COUNT(*) c
			FROM
				cataloged_item,
				collecting_event,
				locality
 			WHERE
				cataloged_item.collecting_event_id=collecting_event.collecting_event_id AND
 				collecting_event.locality_id = locality.locality_id AND
 				locality.locality_id=#old.locality_id#
		</cfquery>
      got cankill.....
      <cfif canKill.c is 0>
        <cftry>
          <cfquery name="killEvnt"  datasource="uam_god">
					DELETE FROM collecting_event WHERE collecting_event_id=#old.collecting_event_id#
				</cfquery>
          <cfcatch>
          </cfcatch>
        </cftry>
        <cftry>
          <cfquery name="killLatLong"  datasource="uam_god">
					DELETE FROM lat_long WHERE locality_id=#old.locality_id#
				</cfquery>
          <cfcatch>
          </cfcatch>
        </cftry>
        <cftry>
          <cfquery name="killGeol"  datasource="uam_god">
					DELETE FROM geology_attributes WHERE locality_id=#old.locality_id#
				</cfquery>
          <cfcatch>
          </cfcatch>
        </cftry>
        <cftry>
          <cfquery name="killLoc"  datasource="uam_god">
					DELETE FROM locality WHERE locality_id=#old.locality_id#
				</cfquery>
          <cfcatch>
          </cfcatch>
        </cftry>
      </cfif>
      fix last edited by...
      <cfquery name="fixLastEdited" datasource="uam_god">
			update flat set stale_flag = 1, lastuser='#session.dbuser#' where collection_object_id = #collection_object_id#
		</cfquery>
    </cftransaction>
    done.....
    <cflocation url="specLocality.cfm?collection_object_id=#collection_object_id#">

    <!---

	--->
  </cfoutput>
</cfif>
