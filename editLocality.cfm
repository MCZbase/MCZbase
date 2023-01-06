:<cfset jquery11=true>
<cfinclude template="includes/_header.cfm">
<cfoutput>
	<cfhtmlhead text='<script src="#Application.protocol#://maps.googleapis.com/maps/api/js?key=#application.gmap_api_key#&libraries=geometry" type="text/javascript"></script>'>
</cfoutput>
<cfoutput>
	<script>
		function useGL(glat,glon,gerr,gpoly){
			if (gpoly=='')
				{var gpoly_wkt='';}
			else
				{var gpoly_wkt='POLYGON ((' + gpoly.replace(/,$/,'') + '))';}
			$("##MAX_ERROR_DISTANCE").val(gerr);
			$("##MAX_ERROR_UNITS").val('m');
			$("##DATUM").val('WGS84');
			$("##georeference_source").val('GeoLocate');
			$("##georeference_protocol").val('GeoLocate');
			$("##georefMethod").val('GEOLocate');
			$("##LAT_LONG_REF_SOURCE").val('GEOLocate');
			$("##dec_lat").val(glat);
			$("##dec_long").val(glon);
			$("##errorPoly").val(gpoly_wkt);
			closeGeoLocate();
		}
	</script>
</cfoutput>

<cfif action is "nothing">
<script language="JavaScript" src="/includes/jquery/scrollTo.js" type="text/javascript"></script>
<cfset title="Edit Locality">
<cfoutput>
<script language="javascript" type="text/javascript">
	jQuery(document).ready(function() {
		$("select[id^='geology_attribute_']").each(function(e){
			populateGeology(this.id);
		});
		$.each($("input[id^='determined_date']"), function() {
			$("##" + this.id).datepicker({dateFormat: "yy-mm-dd"});
		});
		$.each($("input[id^='geo_att_determined_date']"), function() {
			$("##" + this.id).datepicker({dateFormat: "yy-mm-dd",showOn:"both",buttonImage:"images/cal_icon.png",buttonImageOnly: true});
		});
		$("input[id='wktFile'").change(function(){
			console.log($("##ERROR_POLYGON1").val().length);
			if ($("##ERROR_POLYGON1").val().length > 1)
				{var r=confirm('This lat/long has an error polygon. Do you wish to overwrite?');}
				else {r=true;}
			if (r==true){
				    var url = $(this).val();
				    var ext = url.substring(url.lastIndexOf('.') + 1).toLowerCase();
				    if ($(this).prop('files') && $(this).prop('files')[0]&& (ext == "wkt"))
				     {
				        var reader = new FileReader();
				        reader.onload = function (e) {
				        	var myRE = new RegExp(/POLYGON\s*\(\s*(\(\s*(?<X>\-?\d+(:?\.\d+)?)\s+(?<Y>\-?\d+(:?\.\d+)?)(?:\s*,\s*\-?\d+(:?\.\d+)?\s+\-?\d+(:?\.\d+)?)*\s*,\s*\k<X>\s+\k<Y>\s*\))(\s*,\s*\(\s*(?<XH>\-?\d+(:?\.\d+)?)\s+(?<YH>\-?\d+(:?\.\d+)?)(?:\s*,\s*\-?\d+(:?\.\d+)?\s+\-?\d+(:?\.\d+)?)*\s*,\s*\k<XH>\s+\k<YH>\s*\))*\s*\)/);
				           if (myRE.test(e.target.result) == true){
				           $("##ERROR_POLYGON1").val(e.target.result);
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
	    if (window.addEventListener) {
		window.addEventListener("message", getGeolocate, false);
	    } else {
		window.attachEvent("onmessage", getGeolocate);
	    }
		mapsYo();
	});

	function geolocate() {
                var guri="#Application.protocol#://www.geo-locate.org/web/WebGeoreflight.aspx?georef=run";
                guri+="&state=" + $("##state_prov").val();
                guri+="&country="+$("##country").val();
                guri+="&county="+$("##county").val().replace(" County", "");
                guri+="&locality="+$("##spec_locality").val();
                var bgDiv = document.createElement('div');
                bgDiv.id = 'bgDiv';
                bgDiv.className = 'bgDiv';
                bgDiv.setAttribute('onclick','closeGeoLocate("clicked closed")');
                document.body.appendChild(bgDiv);
                var popDiv=document.createElement('div');
                popDiv.id = 'popDiv';
                popDiv.className = 'editAppBox';
                document.body.appendChild(popDiv);
                var cDiv=document.createElement('div');
                cDiv.className = 'fancybox-close';
                cDiv.id='cDiv';
                cDiv.setAttribute('onclick','closeGeoLocate("clicked closed")');
                $("##popDiv").append(cDiv);
                var hDiv=document.createElement('div');
                hDiv.className = 'fancybox-help';
                hDiv.id='hDiv';
                hDiv.innerHTML='<a href="https://arctosdb.wordpress.com/how-to/create/data-entry/geolocate/" target="blank">[ help ]</a>';
                $("##popDiv").append(hDiv);
                $("##popDiv").append('<img src="/images/loadingAnimation.gif" class="centeredImage">');
                var theFrame = document.createElement('iFrame');
                theFrame.id='theFrame';
                theFrame.className = 'editFrame';
                theFrame.src=guri;
                $("##popDiv").append(theFrame);
        }
        function getGeolocate(evt) {
            if (evt.origin.includes("://mczbase") && evt.data == "") {
               console.log(evt); // Chrome seems to include an extra invocation of getGeolocate from mczbase.
            } else {
               if (evt.origin !== "#Application.protocol#://www.geo-locate.org") {
                   console.log(evt);
                   alert( "MCZbase error: iframe url does not have permision to interact with me" );
                   closeGeoLocate('intruder alert');
               } else {
                   var breakdown = evt.data.split("|");
                   if (breakdown.length == 4) {
                        var glat=breakdown[0];
                        var glon=breakdown[1];
                        var gerr=breakdown[2];
						console.log(breakdown[3]);
						if (breakdown[3]== "Unavailable")
							{var gpoly='';}
						else
							{var gpoly=breakdown[3].replace(/([^,]*),([^,]*)[,]{0,1}/g,'$2 $1,');}
                        useGL(glat,glon,gerr,gpoly)
                   } else {
                        alert( "MCZbase error: Unable to parse geolocate data. data length=" +  breakdown.length);
                        closeGeoLocate('ERROR - breakdown length');
                   }
               }
            }
        }
</script>
	<script>
      var openFile = function(event) {
        var input = event.target;

        var reader = new FileReader();
        reader.onload = function(){
          var text = reader.result;
          var node = document.getElementById('output');
          node.innerText = text;
          console.log(reader.result.substring(0, 200));
        };
        reader.readAsText(input.files[0]);
      };
    </script>
</cfoutput>
<script language="javascript" type="text/javascript">
        function closeGeoLocate(msg) {
                $('#bgDiv').remove();
                $('#bgDiv', window.parent.document).remove();
                $('#popDiv').remove();
                $('#popDiv', window.parent.document).remove();
                $('#cDiv').remove();
                $('#cDiv', window.parent.document).remove();
                $('#theFrame').remove();
                $('#theFrame', window.parent.document).remove();
        }

	function populateGeology(id) {
		if (id=='geology_attribute') {
			// new geol attribute
			var idNum='';
			var thisValue=$("#geology_attribute").val();
			var dataValue=$("#geo_att_value").val();
			var theSelect="geo_att_value";
		} else {
			var idNum=id.replace('geology_attribute_','');
			var thisValue=$("#geology_attribute_" + idNum).val();;
			var dataValue=$("#geo_att_value_" + idNum).val();
			var theSelect="geo_att_value_";
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
				if (dataValue !==null){
				for (i=0; i<r.ROWCOUNT; ++i) {
					if (r.DATA.ATTRIBUTE_VALUE[i]==dataValue){exists=true;}
					}

				if (exists==false){s='<option value="' + dataValue + '" selected="selected" style="color:red">' + dataValue + '</option>';}

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

	function showLLFormat(orig_units,recID) {
		//alert(orig_units);
		//alert(recID);
		if (recID.length == 0) {
			//alert('new');
			var addNewLL = document.getElementById('addNewLL');
			addNewLL.style.display='none';
			var llMeta = document.getElementById('llMeta');
			llMeta.style.display='';

		}
		var dd = 'dd' + recID;
		//alert('dd='+dd+':');
		var dd = document.getElementById(dd);
		var utm = 'utm' + recID;
		var utm = document.getElementById(utm);
		var dms = 'dms' + recID;
		var dms = document.getElementById(dms);
		var ddm = 'ddm' + recID;
		var ddm = document.getElementById(ddm);
		dd.style.display='none';
		utm.style.display='none';
		ddm.style.display='none';
		dms.style.display='none';
		//alert('everything off');
		if (orig_units.length > 0) {
			//alert('got something');
			if (orig_units == 'decimal degrees') {
				dd.style.display='';
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

		function mapsYo(){
			$("input[id^='coordinates_']").each(function(e){
				var locid=this.id.split('_')[1];
				var coords=this.value;
				var bounds = new google.maps.LatLngBounds();
				var polygonArray = [];
				var ptsArray=[];
				var lat=coords.split(',')[0];
				var lng=coords.split(',')[1];
				var errorm=$("#error_" + locid).val();
				var mapOptions = {
					zoom: 1,
				    center: new google.maps.LatLng(lat, lng),
				    mapTypeId: google.maps.MapTypeId.ROADMAP,
				    panControl: false,
				    scaleControl: true,
					fullscreenControl: true,
					zoomControl: true
				};
				var map = new google.maps.Map(document.getElementById("mapdiv_" + locid), mapOptions);

				var center=new google.maps.LatLng(lat,lng);
				var marker = new google.maps.Marker({
					position: center,
					map: map,
					zIndex: 10
				});
				bounds.extend(center);
				if (parseInt(errorm)>0){
					var circleoptn = {
						strokeColor: '#FF0000',
						strokeOpacity: 0.8,
						strokeWeight: 2,
						fillColor: '#FF0000',
						fillOpacity: 0.15,
						map: map,
						center: center,
						radius: parseInt(errorm),
						zIndex:-99
					};
					crcl = new google.maps.Circle(circleoptn);
					bounds.union(crcl.getBounds());
				}
				// WKT can be big and slow, so async fetch
				$.get( "/component/utilities.cfc?returnformat=plain&method=getGeogWKT&locality_id=" + locid, function( wkt ) {
  					  if (wkt.length>0){
						var regex = /\(([^()]+)\)/g;
						var Rings = [];
						var results;
						while( results = regex.exec(wkt) ) {
						    Rings.push( results[1] );
						}
						for(var i=0;i<Rings.length;i++){
							// for every polygon in the WKT, create an array
							var lary=[];
							var da=Rings[i].split(",");
							for(var j=0;j<da.length;j++){
								// push the coordinate pairs to the array as LatLngs
								var xy = da[j].trim().split(" ");
								var pt=new google.maps.LatLng(xy[1],xy[0]);
								lary.push(pt);
								//console.log(lary);
								bounds.extend(pt);
							}
							// now push the single-polygon array to the array of arrays (of polygons)
							ptsArray.push(lary);
						}
						var poly = new google.maps.Polygon({
						    paths: ptsArray,
						    strokeColor: '#1E90FF',
						    strokeOpacity: 0.8,
						    strokeWeight: 2,
						    fillColor: '#1E90FF',
						    fillOpacity: 0.35
						});
						poly.setMap(map);
						polygonArray.push(poly);
						// END this block build WKT
  					  	} else {
  					  		$("#mapdiv_" + locid).addClass('noWKT');
  					  	}
  					  	if (bounds.getNorthEast().equals(bounds.getSouthWest())) {
					       var extendPoint1 = new google.maps.LatLng(bounds.getNorthEast().lat() + 0.05, bounds.getNorthEast().lng() + 0.05);
					       var extendPoint2 = new google.maps.LatLng(bounds.getNorthEast().lat() - 0.05, bounds.getNorthEast().lng() - 0.05);
					       bounds.extend(extendPoint1);
					       bounds.extend(extendPoint2);
					    }
						map.fitBounds(bounds);
			        	for(var a=0; a<polygonArray.length; a++){
			        		if  (! google.maps.geometry.poly.containsLocation(center, polygonArray[a]) ) {
			        			$("#mapdiv_" + locid).addClass('uglyGeoSPatData');
				        	} else {
				    			$("#mapdiv_" + locid).addClass('niceGeoSPatData');
			        		}
			        	}
					});
					map.fitBounds(bounds);
			});
		}
</script>

<!--- Provide a probably sane value for sovereign_nation if none is currently provided. --->
<cfquery name="getSov" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
    	select
			sovereign_nation, mczbase.suggest_sovereign_nation(locality_id) suggest
		from
			locality
		where
			locality.locality_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
</cfquery>
<cfif len(getSov.sovereign_nation) eq 0>
   <cfquery name="getSov" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
      update locality
            set sovereign_nation =  <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getSov.suggest#">
      where sovereign_nation is null and
			locality.locality_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
   </cfquery>
</cfif>

<cfoutput>
<cfquery name="locDet" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
    	select
			*
		from
			locality,
			geog_auth_rec
		where
			locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id and
			locality.locality_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
	</cfquery>
	<cfquery name="geolDet" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
    	select
			*
		from
			geology_attributes,
			preferred_agent_name
		where
			geology_attributes.geo_att_determiner_id = preferred_agent_name.agent_id (+) and
			geology_attributes.locality_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
		order by 
			decode(geology_attribute,
				'Lithology',1,
				'Group',10,
				'Formation',11,
				'Member',12,
				'Horizon',13,
				'Bed',14,
				'Eonothem/Eon',20,
				'Erathem/Era',21,
				'Period/System',22,
				'Epoch/Series',23,
				'Sub-Epoch', 24,
				'Age/Stage', 25,
				'Zone',26,
				50)
	</cfquery>
	<cfquery name="whatSpecs" datasource="uam_god">
  		SELECT
			count(cataloged_item.cat_num) numOfSpecs,
			count(collecting_event.collecting_event_id) numOfCollEvents,
			collection.collection,
			collection.collection_id
		from
			cataloged_item,
			collection,
			collecting_event
		WHERE
			cataloged_item.collecting_event_id = collecting_event.collecting_event_id and
			cataloged_item.collection_id = collection.collection_id and
			collecting_event.locality_id=  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
		GROUP BY
			collection.collection,
			collection.collection_id
  	</cfquery>
	<cfquery name="collectingEvents" datasource="uam_god">
		SELECT count(collecting_event_id) ct 
		FROM collecting_event
		WHERE
			collecting_event.locality_id=  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
	</cfquery>
	<cfquery name="getLL" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
        select LAT_LONG_ID,LOCALITY_ID,LAT_DEG,DEC_LAT_MIN,LAT_MIN,trim(LAT_SEC) LAT_SEC,LAT_DIR,LONG_DEG,DEC_LONG_MIN,LONG_MIN,trim(LONG_SEC) LONG_SEC,LONG_DIR,trim(DEC_LAT) DEC_LAT,trim(DEC_LONG) DEC_LONG,DATUM,to_meters(max_error_distance, max_error_units) COORDINATEUNCERTAINTYINMETERS,UTM_ZONE,UTM_EW,UTM_NS,ORIG_LAT_LONG_UNITS,DETERMINED_BY_AGENT_ID,DETERMINED_DATE,LAT_LONG_REF_SOURCE,LAT_LONG_REMARKS,MAX_ERROR_DISTANCE,MAX_ERROR_UNITS,NEAREST_NAMED_PLACE,LAT_LONG_FOR_NNP_FG,FIELD_VERIFIED_FG,ACCEPTED_LAT_LONG_FG,EXTENT,GPSACCURACY,GEOREFMETHOD,VERIFICATIONSTATUS,SPATIALFIT,GEOLOCATE_UNCERTAINTYPOLYGON,GEOLOCATE_SCORE,GEOLOCATE_PRECISION,GEOLOCATE_NUMRESULTS,GEOLOCATE_PARSEPATTERN,VERIFIED_BY_AGENT_ID,ERROR_POLYGON,db.agent_name as "determiner",vb.agent_name as "verifiedby"
		 from
			lat_long,
			preferred_agent_name db,
			preferred_agent_name vb
		where determined_by_agent_id = db.agent_id
		and verified_by_agent_id = vb.agent_id(+)
        and locality_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
		order by ACCEPTED_LAT_LONG_FG DESC, lat_long_id
     </cfquery>
	<cfquery name="getAccLL" dbtype="query">
        select * from
			getLL
		where accepted_lat_long_fg=1
     </cfquery>
     <cfquery name="ctdatum" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
        select datum from ctdatum order by datum
     </cfquery>
	<cfquery name="ctElevUnit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select orig_elev_units from ctorig_elev_units order by orig_elev_units
	</cfquery>
	<cfquery name="ctDepthUnit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select depth_units from ctdepth_units order by depth_units
	</cfquery>
        <cfquery name="cterror" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
        select LAT_LONG_ERROR_UNITS from ctLAT_LONG_ERROR_UNITS order by LAT_LONG_ERROR_UNITS
     </cfquery>
     <cfquery name="ctGeorefMethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select georefMethod from ctgeorefmethod order by georefMethod
	</cfquery>
	<cfquery name="ctVerificationStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select VerificationStatus from ctVerificationStatus order by VerificationStatus
	</cfquery>
     <cfquery name="ctunits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
        select ORIG_LAT_LONG_UNITS from ctLAT_LONG_UNITS order by ORIG_LAT_LONG_UNITS
     </cfquery>
	<cfquery name="ctgeology_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT geology_attribute from ctgeology_attribute 
		ORDER BY ordinal
     </cfquery>
    <cfquery name="ctSovereignNation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	    select sovereign_nation from ctsovereign_nation order by sovereign_nation
    </cfquery>
    <div style="width: 60em;margin: 0 auto;padding: 1em 0 3em 0";>
  	<table>
  		<tr>
			<td>
				<div style="position: relative;">
					<div style="width: 60em;postion: relative;">
					<ul class="headercol1" style="padding-left:0;margin-left:0;float: left;text-align: left;margin-bottom: 1em;">
						<li>
							<h2 class="wikilink">Edit Locality 	<img src="/images/info_i_2.gif" onClick="getMCZDocs('Edit_Locality')" class="likeLink" alt="[ help ]"></h2>
							<h3>
								<cfif #whatSpecs.recordcount# is 0>
									<font color="##FF0000">This Locality (#locDet.locality_id#)
									contains no specimens. Please delete it if you don't have plans for it!</font>
								<cfelseif #whatSpecs.recordcount# is 1>
									<font color="##FF0000">This Locality (#locDet.locality_id#)
										contains 
										<a href="SpecimenResults.cfm?locality_id=#locality_id#">
											#whatSpecs.numOfSpecs# #whatSpecs.collection# specimens
										</a>
										from 
										<a href="/Locality.cfm?action=findCO&locality_id=#locality_id#&include_counts=true">
											#whatSpecs.numOfCollEvents# collecting events
										</a>
									</font>
									</h3><h3>
									in <a href="/Locality.cfm?action=findCollEvent&locality_id=#locality_id#">#collectingEvents.ct# collecting events</a>.
								<cfelse>
									<font color="##FF0000">This Locality (#locDet.locality_id#)
									contains the following <a href="SpecimenResults.cfm?locality_id=#locality_id#">specimens</a></font>
									</h3><h3>
									in <a href="/Locality.cfm?action=findCollEvent&locality_id=#locality_id#">#collectingEvents.ct# collecting events</a>:</font>
									<ul class="geol_hier" style="padding-bottom: 0em;margin-bottom:0;">
										<cfloop query="whatSpecs">
											<li style="margin-left: 1.5em;">
												<a href="SpecimenResults.cfm?locality_id=#locality_id#&collection=#whatSpecs.collection#">
													#numOfSpecs# #collection# specimens
												</a>
												from 
												<a href="/Locality.cfm?action=findCollEvent&locality_id=#locality_id#&collnOper=usedBy&collection_id=#whatSpecs.collection_id#&include_counts=true">
													#whatSpecs.numOfCollEvents# collecting events
												</a>
												<br>
												<a href="/Locality.cfm?action=findCollEvent&locality_id=#locality_id#&collnOper=usedOnlyBy&collection_id=#whatSpecs.collection_id#&include_counts=true">
													(show only by #collection#)
												</a>
											</li>
										</cfloop>
									</ul>
								</cfif>
							</h3>
						</li>
					</ul>

					   <div style="top: 0;right:10px;position:absolute;height: 288px;width: 288px;">
						  <cfif len(getAccLL.dec_lat) gt 0 and len(getAccLL.dec_long) gt 0 and (getAccLL.dec_lat is not 0 and getAccLL.dec_long is not 0)>
							<cfset coordinates="#getAccLL.dec_lat#,#getAccLL.dec_long#">
							<input type="hidden" id="coordinates_#getAccLL.locality_id#" value="#coordinates#">
							<input type="hidden" id="error_#getAccLL.locality_id#" value="#getAccLL.COORDINATEUNCERTAINTYINMETERS#">
							<div id="mapdiv_#getAccLL.locality_id#" class="smallmap"></div>
							<!---span class="infoLink mapdialog">map key/tools</div--->
							</cfif>
							</div>
						</div>
				</div>
			</td>
		</tr>
	</cfoutput>
	<cfoutput query="locDet">
		<form name="geog" action="editLocality.cfm" method="get">
			<input type="hidden" name="action" value="changeGeog">
            <input type="hidden" name="geog_auth_rec_id">
            <input type="hidden" name="locality_id" value="#locality_id#">

			<tr>
				<td>
                    <h4 style="margin-bottom:.5em;">Higher Geography</h4>
	            	<input type="text"
						name="higher_geog"
						id="higher_geog"
						value="#higher_geog#"
						size="90"
						class="readClr"
						readonly="yes" >
				</td>
			</tr>
			<tr>
				<td>
					<input type="button" value="Change" class="picBtn" id="changeGeogButton"
							onmouseover="this.className='picBtn btnhov'"
							onmouseout="this.className='picBtn'"
							onclick="document.getElementById('saveGeogChangeButton').style.display='';document.getElementById('higher_geog').className='red';GeogPick('geog_auth_rec_id','higher_geog','geog'); return false;">
			 			<input type="submit" value="Save" class="savBtn" id="saveGeogChangeButton"
			 				style="display:none"
							onmouseover="this.className='savBtn btnhov'"
							onmouseout="this.className='savBtn'">
						<cfif len(session.roles) gt 0 and FindNoCase("manage_geography",session.roles) NEQ 0>
						<input type="button" value="Edit" class="lnkBtn"
							onmouseover="this.className='lnkBtn btnhov'"
							onmouseout="this.className='lnkBtn'"
							onClick="document.location='Locality.cfm?action=editGeog&geog_auth_rec_id=#geog_auth_rec_id#'">
						</cfif>
				</td>
			</tr>
         </form>
         <form name="locality" method="post" action="editLocality.cfm">
 	    <input type="hidden" id="state_prov" name="state_prov" value="#locDet.state_prov#">
            <input type="hidden" id="country" name="country" value="#locDet.country#">
	    <input type="hidden" id="county" name="county" value="#locDet.county#">
            <input type="hidden" name="action" value="saveLocalityEdit">
            <input type="hidden" name="locality_id" value="#locality_id#">
         </table>
			<br><br>
            <table style="margin-top: 3em;">
			<tr>
				<td><h4 style="margin-bottom: .5em;">Locality</h4></td>
			<tr>
				<td>
               <label for="curated_fg">Vetted</label>
					<cfif locDet.curated_fg EQ 1>
						<select name="curated_fg" id="curated_fg">
							<option selected="selected" value="1">Yes*</option>
							<option value="0">No</option>
						</select>
						<strong>This locality record has been vetted.  Please do not edit (or delete).</strong>
					<cfelse>
						<select name="curated_fg" id="curated_fg">
							<option value="1">Yes</option>
							<option selected="selected" value="0">No</option>
						</select>
					</cfif>
				</td>
			</tr>
			</tr>
            <tr>
            	<td>
					<label for="spec_locality">
						<a href="javascript:void(0);" onClick="getMCZDocs(''Edit_Locality')">
							Specific Locality
						</a>
					</label>
					<input type="text"
						id="spec_locality"
						name="spec_locality"
						value="#stripQuotes(spec_locality)#"
						size="131">
				</td>
			</tr>
            <tr>
            	<td>
                   <label for="sovereign_nation">Sovereign Nation</label>
	    	       <select name="sovereign_nation" id="sovereign_nation" size="1">
                       <cfloop query="ctSovereignNation">
            	           <option <cfif isdefined("locDet.sovereign_nation") AND ctsovereignnation.sovereign_nation is locDet.sovereign_nation> selected="selected" </cfif>value="#ctSovereignNation.sovereign_nation#">#ctSovereignNation.sovereign_nation#</option>
                       </cfloop>
	        	   </select>
				</td>
			</tr>
            <tr>
				<td>
					<table>
						<tr>
							<td style="width: 134px;">
								<label for="minimum_elevation">
									<a href="javascript:void(0);" onClick="getDocs('locality','elevation')">
										Min. Elev.
									</a>
								</label>
								<input type="text" name="minimum_elevation"
									id="minimum_elevation"
									value="#minimum_elevation#" size="10">&nbsp;TO&nbsp;
							</td>
							<td style="width:115px;">
								<label for="maximum_elevation">
									<a href="javascript:void(0);" onClick="getDocs('locality','elevation')">
										Max. Elev.
									</a>
								</label>
								<input type="text" name="maximum_elevation"
									id="maximum_elevation"
									value="#maximum_elevation#" size="10">&nbsp;&nbsp;
							</td>
							<td>
								<label for="orig_elev_units">
									<a href="javascript:void(0);" onClick="getDocs('locality','elevation')">
										Elev. Unit
									</a>
								</label>
								<select name="orig_elev_units" size="1" id="orig_elev_units">
									<option value=""></option>
				                    <cfloop query="ctElevUnit">
				                      <option <cfif #ctelevunit.orig_elev_units# is "#locdet.orig_elev_units#"> selected </cfif>value="#ctElevUnit.orig_elev_units#">#ctElevUnit.orig_elev_units#</option>
				                    </cfloop>
				                  </select>
							</td>
						</tr>
					</table>
				</td>
			</tr>
			 <tr>
				<td>
					<table>
						<tr>
							<td style="width: 134px;">
								<label for="min_depth">
									<a href="javascript:void(0);" onClick="getDocs('locality','depth')">
										Min. Depth.
									</a>
								</label>
								<input type="text" name="min_depth"
									id="min_depth"
									value="#min_depth#" size="10">&nbsp;TO&nbsp;
							</td>
							<td style="width: 115px;">
								<label for="max_depth">
									<a href="javascript:void(0);" onClick="getDocs('locality','depth')">
										Max. Depth.
									</a>
								</label>
								<input type="text" name="max_depth"
									id="max_depth"
									value="#max_depth#" size="10">&nbsp;&nbsp;
							</td>
							<td>
								<label for="depth_units">
									<a href="javascript:void(0);" onClick="getDocs('locality','depth')">
										Depth Unit
									</a>
								</label>
								<select name="depth_units" size="1" id="depth_units">
									<option value=""></option>
				                    <cfloop query="ctDepthUnit">
				                      <option <cfif #ctDepthUnit.depth_units# is "#locdet.depth_units#"> selected </cfif>value="#ctDepthUnit.depth_units#">#ctDepthUnit.depth_units#</option>
				                    </cfloop>
				                  </select>
							</td>
						</tr>
					</table>
				</td>
			</tr>
              <tr>
                <td>
					<label for="locality_remarks">
						Locality Remarks
					</label>
					<input type="text" name="locality_remarks" id="locality_remarks"
						value="#stripQuotes(locality_remarks)#"  style="width:71em;">
				</td>
              </tr>
			<tr>
                <td>
					<label for="locality_remarks">
						Not Georeferenced Because <a href="##" onClick="getMCZDocs('Not_Georeferenced_Because')">
										(Suggested Entries)
									</a>
					</label>
					<input type="text" name="NoGeorefBecause"
						id="NoGeorefBecause" value="#NoGeorefBecause#"  style="width:71em;">
					<cfif getLL.recordcount gt 0 AND len(#NoGeorefBecause#) gt 0>
						<div style="background-color:red">
							NoGeorefBecause should be NULL for localities with georeferences.
							Please review this locality and update accordingly.
						</div>
					<cfelseif getLL.recordcount is 0 AND len(#NoGeorefBecause#) is 0>
						<div style="background-color:red">
							Please georeference this locality or enter a value for Not Georeferenced Because.
						</div>
					</cfif>
				</td>
              </tr>
              <tr>
                <td><!---div align="center"--->
                   <input type="submit" value="Save" class="savBtn"
  						 onmouseover="this.className='savBtn btnhov'"
						 onmouseout="this.className='savBtn'">
					 <input type="button" value="Quit" class="qutBtn"
  						 onmouseover="this.className='qutBtn btnhov'"
						 onmouseout="this.className='qutBtn'"
						 onClick="document.location='Locality.cfm';">
					<input type="button" value="Delete" class="delBtn"
  						 onmouseover="this.className='delBtn btnhov'"
						 onmouseout="this.className='delBtn'"
						 onClick="locality.action.value='deleteLocality';confirmDelete('locality');">
					<input type="button" value="Map" class="lnkBtn"
  						 onmouseover="this.className='lnkBtn btnhov'"
						 onmouseout="this.className='lnkBtn'"
						 onClick="window.open('/bnhmMaps/bnhmPointMapper.cfm?locality_id=#locality_id#','bnhmMap');">

                  <!---/div--->

					</td>
              </tr>
              <tr>
                <td><div align="center">
					<input type="button" value="Collecting Events" class="lnkBtn"
  						 onmouseover="this.className='lnkBtn btnhov'"
						 onmouseout="this.className='lnkBtn'"
						 onClick="document.location='Locality.cfm?Action=findCollEvent&locality_id=#locality_id#';">
					</div></td>
              </tr>
          </form>
		  <form name="cloneLoc" method="post" action="Locality.cfm">
		  				<input type="hidden" name="Action" value="newLocality">
						<input type="hidden" name="geog_auth_rec_id" value="#geog_auth_rec_id#">
						<input type="hidden" name="spec_locality" value="#spec_locality#">
						<input type="hidden" name="minimum_elevation" value="#minimum_elevation#">
						<input type="hidden" name="maximum_elevation" value="#maximum_elevation#">
						<input type="hidden" name="ORIGEELEVUNITS" value="#orig_elev_units#">
						<input type="hidden" name="locality_id" value="#locality_id#">
					</form>
					<form name="nada" method="post" action="Locality.cfm">
							<input type="hidden" name="Action" value="newCollEvent">
							<input type="hidden" name="locality_id" value="#locality_id#">
						</form>
		  <tr>
		  <td nowrap>
			<script>
				function cloneLocality(locality_id) {
					if(confirm('Do you want to create a copy of this locality which you may then edit?')) {
						var rurl='editLocality.cfm?action=clone&locality_id=' + locality_id;
						if(confirm('Do you want to include accepted georeferences?')){
							rurl+='&keepAcc=1';
							if(confirm('Do you want to include unaccepted georeferences too?')){
								rurl+='&keepUnacc=1';
							}
						}
						document.location=rurl;
					}
				}
			</script>
		  	<div align="center">
						<input type="button" value="Create Clone" class="insBtn"
  						 	onmouseover="this.className='insBtn btnhov'"
						 	onmouseout="this.className='insBtn'" onClick="cloneLocality(#locality_id#)">
							<input type="button" value="New Coll Event" class="insBtn"
								 onmouseover="this.className='insBtn btnhov'"
								 onmouseout="this.className='insBtn'" onClick="nada.submit();">
						</div>
						 </td>
					</tr>
		   </table>
		   <hr />
        <table>
			<tr>
				<td>
					<h3 style="margin: 1.5em 0 1em 0;">Coordinates for this locality:</h3>
				</td>

			</tr>
		</table>
		<cfset i=1>
		<table border>
		</cfoutput>

		<cfoutput query="getLL" group="lat_long_id">
		<tr	#iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#	>
		<td>
          <form name="latLong#i#" method="post" action="editLocality.cfm" onSubmit="return noenter();">
		   <input type="hidden" name="locality_id" value="#locality_id#">
            <input type="hidden" name="Action" value="editAccLatLong">
            <input type="hidden" name="lat_long_id" value="#lat_long_id#">
            <table border>

     <cfset thisScore = #getLL.geolocate_score#>
     	<cfif #thisScore# is "#getLL.geolocate_score#" and #thisScore# gt 0>
			<tr>
				<td>GeoLocate Score:<span style="color: green;text-align:right;"> #getLL.geolocate_score#</span></td>
				<td>GeoLocate Precision:<span style="color: green;text-align:right;"> #getLL.geolocate_precision#</span></td>
				<td colspan="2">GeoLocate Number of Results:<span style="color: green;text-align:right;"> #getLL.geolocate_numresults#</span></td>
			</tr>
			<tr>
				<td colspan="4">Geolocate Parse Pattern: <span style="color: green;text-align:right;">#getLL.geolocate_parsepattern#</span></td>
			</tr>
		 </cfif>
              <tr>
                <td>
					<cfset thisUnits = #getLL.ORIG_LAT_LONG_UNITS#>
					<label for="ORIG_LAT_LONG_UNITS#i#">
						<a href="javascript:void(0);" onClick="getDocs('lat_long','original_units')">Original Units</a>
					</label>
					<select name="ORIG_LAT_LONG_UNITS" id="ORIG_LAT_LONG_UNITS#i#" size="1" class="reqdClr"
						onchange="showLLFormat(this.value,'#i#');">
	                    <cfloop query="ctunits">
	                      <option
						  	<cfif #thisUnits# is "#ctunits.ORIG_LAT_LONG_UNITS#"> selected </cfif>value="#ctunits.ORIG_LAT_LONG_UNITS#">#ctunits.ORIG_LAT_LONG_UNITS#</option>
	                    </cfloop>
	                  </select>
				</td>
				<td nowrap>
	                <label for="accepted_lat_long_fg#i#">
						<a href="javascript:void(0);" onClick="getDocs('lat_long','accepted')">Accepted?</a>
					</label>
					<select name="accepted_lat_long_fg" id="accepted_lat_long_fg#i#" size="1" class="reqdClr">
						<option <cfif #accepted_lat_long_fg# is 1> selected </cfif>value="1">yes</option>
						<option <cfif #accepted_lat_long_fg# is 0> selected </cfif> value="0">no</option>
					</select>
				</td>
				<td>
					<label for="determined_by#i#">
						<a href="javascript:void(0);" onClick="getDocs('lat_long','determiner')">Determiner</a>
					</label>
					<input type="text" name="determined_by" id="determined_by#i#" class="reqdClr" value="#determiner#" size="40"
						onchange="getAgent('determined_by_agent_id','determined_by','latLong#i#',this.value); return false;"
		 				onKeyPress="return noenter(event);">
		 			<input type="hidden" name="determined_by_agent_id" value="#determined_by_agent_id#">
				</td>
				<td>
					<label for="determined_date#i#">
						<a href="javascript:void(0);" onClick="getDocs('lat_long','date')">Determined Date</a>
					</label>
					<input type="text" name="determined_date" id="determined_date#i#"
						value="#dateformat(determined_date,'yyyy-mm-dd')#" class="reqdClr">
				</td>
              </tr>
            <tr>
				<td>
					<table>
						<tr>
							<td>
								<label for="MAX_ERROR_DISTANCE#i#">
									<a href="javascript:void(0);" onClick="getDocs('lat_long','maximum_error')">Maximum Error</a>
								</label>
								<input type="text" name="MAX_ERROR_DISTANCE" id="MAX_ERROR_DISTANCE#i#" value="#MAX_ERROR_DISTANCE#" size="6">
							</td>
							<td>
								<label for="MAX_ERROR_UNITS#i#">
									<a href="javascript:void(0);" onClick="getDocs('lat_long','maximum_error')">Maximum Error Units</a>
								</label>
								<cfset thisunits = #MAX_ERROR_UNITS#>
								<select name="MAX_ERROR_UNITS" size="1" id="MAX_ERROR_UNITS#i#">
				                    <option value=""></option>
				                    <cfloop query="cterror">
				                      <option <cfif #cterror.LAT_LONG_ERROR_UNITS# is "#thisunits#"> selected </cfif>
										value="#cterror.LAT_LONG_ERROR_UNITS#">#cterror.LAT_LONG_ERROR_UNITS#</option>
				                    </cfloop>
				                  </select>
							</td>
						</tr>
					</table>
				</td>
				<td>
					<label for="DATUM#i#">
						<a href="javascript:void(0);" onClick="getDocs('lat_long','datum')">Datum</a>
					</label>
					<select name="DATUM" id="DATUM#i#" size="1" class="reqdClr">
	                   <cfset thisDatum = #getLL.DATUM#>
	                    <cfloop query="ctdatum">
	                      <option <cfif #ctdatum.DATUM# is "#thisDatum#"> selected </cfif>
							value="#ctdatum.DATUM#">#ctdatum.DATUM#</option>
	                    </cfloop>
	                  </select>
				</td>
				<td>
					<cfset thisGeoMeth = #georefMethod#>
					<label for="georefMethod#i#">
						Georeference Method
					</label>
					<select name="georefMethod" id="georefMethod#i#" size="1" class="reqdClr narrowselect" style="width: 300px !important;">
				   		<cfloop query="ctGeorefMethod">
							<option class="reqdClr"
								<cfif #thisGeoMeth# is #ctGeorefMethod.georefMethod#> selected </cfif>
								value="#georefMethod#">#georefMethod#</option>
						</cfloop>
				   </select>
				</td>
				<td>
					<label for="extent#i#">
						Extent
					</label>
					<input type="text" name="extent" id="extent#i#" value="#extent#" size="7">
				</td>
			</tr>
			<tr>
				<td>
					<label for="GpsAccuracy#i#">
						GPS Accuracy
					</label>
					<input type="text" name="GpsAccuracy" id="GpsAccuracy#i#" value="#GpsAccuracy#" size="7">
				</td>
				<td>
					<label for="VerificationStatus#i#">
						Verification Status
					</label>
					<select name="VerificationStatus" id="VerificationStatus#i#" size="1" class="reqdClr"
						onchange="if (this.value=='verified by MCZ collection' || this.value=='rejected by MCZ collection')
									{document.getElementById('verified_by#i#').style.display = 'block';
									document.getElementById('verified_byLBL#i#').style.display = 'block';
									document.getElementById('verified_by#i#').className = 'reqdClr';}
									else
									{document.getElementById('verified_by#i#').value = '';
									document.getElementById('verified_by#i#').style.display = 'none';
									document.getElementById('verified_byLBL#i#').style.display = 'none';
									document.getElementById('verified_by#i#').className = '';}">
					   	<cfset thisVerificationStatus = #VerificationStatus#>
					   		<cfloop query="ctVerificationStatus">
								<option
									<cfif #thisVerificationStatus# is #ctVerificationStatus.VerificationStatus#> selected </cfif>
									value="#VerificationStatus#">#VerificationStatus#</option>
							</cfloop>
					   </select>
				</td>
				<td colspan=2>
					<label for="verified_by#i#" id="verified_byLBL#i#" <cfif #VerificationStatus# EQ "verified by MCZ collection" or #VerificationStatus# EQ "rejected by MCZ collection">style="display:block"<cfelse>style="display:none"</cfif>>
						Verified by
					</label>
					<input type="text" name="verified_by" id="verified_by#i#" value="#verifiedby#" size="40" <cfif #VerificationStatus# EQ "verified by MCZ collection" or #VerificationStatus# EQ "rejected by MCZ collection">class="reqdClr" style="display:block"<cfelse>style="display:none"</cfif>
						onchange="if (this.value.length > 0){getAgent('verified_by_agent_id','verified_by','latLong#i#',this.value); return false;}"
		 				onKeyPress="return noenter(event);">
		 			<input type="hidden" name="verified_by_agent_id" value="#verified_by_agent_id#">
				</td>
			</tr>
			<tr>
				<td colspan="4">
					<label for="LAT_LONG_REMARKS#i#">
						Remarks
					</label>
					<input type="text"
						name="LAT_LONG_REMARKS"
						id="LAT_LONG_REMARKS#i#"
						value="#encodeForHTML(LAT_LONG_REMARKS)#"
						size="120">
				</td>
			</tr>
			<tr>
				<td colspan="4">
					<label for="LAT_LONG_REF_SOURCE#i#">
						Reference
					</label>
					<input type="text" name="LAT_LONG_REF_SOURCE" id="LAT_LONG_REF_SOURCE#i#" size="120" class="reqdClr"
						value="#encodeForHTML(getLL.LAT_LONG_REF_SOURCE)#" />
					<script>
						$(function() {
      							$("##LAT_LONG_REF_SOURCE#i#").autocomplete({source:"component//functions.cfc?method=getLatLonRefSourceFilter",minLength:2 });
						});
					</script>
				</td>
			</tr>
			<tr>
				<td colspan="4">
					<table id="dms#i#" style="display:none;">
						<tr>
							<td>
								<label for="lat_deg#i#">Lat. Deg.</label>
								<input type="text" name="LAT_DEG" value="#LAT_DEG#" size="4" id="lat_deg#i#" class="reqdClr">
							</td>
							<td>
								<label for="lat_min#i#">Lat. Min.</label>
								<input type="text" name="LAT_MIN" value="#LAT_MIN#" size="4" id="lat_min#i#" class="reqdClr">
							</td>
							<td>
								<label for="lat_sec#i#">Lat. Sec.</label>
								<input type="text" name="LAT_SEC" value="#LAT_SEC#" id="lat_sec#i#" class="reqdClr">
							</td>
							<td>
								<label for="lat_dir#i#">Lat. Dir.</label>
								<select name="LAT_DIR" size="1" id="lat_dir#i#"  class="reqdClr">
									<option value=""></option>
							        <option <cfif #LAT_DIR# is "N"> selected </cfif>value="N">N</option>
							        <option <cfif #LAT_DIR# is "S"> selected </cfif>value="S">S</option>
							    </select>
							</td>
						</tr>
						<tr>
							<td>
								<label for="long_deg#i#">Long. Deg.</label>
								<input type="text" name="LONG_DEG" value="#LONG_DEG#" size="4" id="long_deg#i#" class="reqdClr">
							</td>
							<td>
								<label for="long_min#i#">Long. Min.</label>
								<input type="text" name="LONG_MIN" value="#LONG_MIN#" size="4" id="long_min#i#" class="reqdClr">
							</td>
							<td>
								<label for="long_sec#i#">Long. Sec.</label>
								<input type="text" name="LONG_SEC" value="#LONG_SEC#" id="long_sec#i#"  class="reqdClr">
							</td>
							<td>
								<label for="long_dir#i#">Long. Dir.</label>
								<select name="LONG_DIR" size="1" id="long_dir#i#" class="reqdClr">
							    	<option value=""></option>
							        <option <cfif #LONG_DIR# is "E"> selected </cfif>value="E">E</option>
							        <option <cfif #LONG_DIR# is "W"> selected </cfif>value="W">W</option>
							    </select>
							</td>
						</tr>
					</table>
					<table id="ddm#i#" style="display:none;">
						<tr>
							<td>
								<label for="dmlat_deg#i#">Lat. Deg.<label>
								<input type="text" name="dmLAT_DEG" value="#LAT_DEG#" size="4" id="dmlat_deg#i#" class="reqdClr">
							</td>
							<td>
								<label for="dec_lat_min#i#">Lat. Dec. Min.<label>
								<input type="text" name="DEC_LAT_MIN" value="#DEC_LAT_MIN#" id="dec_lat_min#i#" class="reqdClr">
							</td>
							<td>
								<label for="dmlat_dir#i#">Lat. Dir.<label>
								<select name="dmLAT_DIR" size="1" id="dmlat_dir#i#" class="reqdClr">
				                	<option value=""></option>
				                   	<option <cfif #LAT_DIR# is "N"> selected </cfif>value="N">N</option>
				                   	<option <cfif #LAT_DIR# is "S"> selected </cfif>value="S">S</option>
				                 </select>
							</td>
						</tr>
						<tr>
							<td>
								<label for="dmlong_deg#i#">Long. Deg.<label>
								<input type="text" name="dmLONG_DEG" value="#LONG_DEG#" size="4" id="dmlong_deg#i#" class="reqdClr">
							</td>
							<td>
								<label for="dec_long_min#i#">Long. Dec. Min.<label>
								<input type="text" name="DEC_LONG_MIN" value="#DEC_LONG_MIN#" id="dec_long_min#i#" class="reqdClr">
							</td>
							<td>
								<label for="dmlong_dir#i#">Long. Dir.<label>
								<select name="dmLONG_DIR" size="1" id="dmlong_dir#i#" class="reqdClr">
									<option value=""></option>
								    <option <cfif #LONG_DIR# is "E"> selected </cfif>value="E">E</option>
								    <option <cfif #LONG_DIR# is "W"> selected </cfif>value="W">W</option>
								</select>
							</td>
						</tr>
					</table>
					 <table id="dd#i#" style="display:none;">
						<tr>
							<td>
								<label for="dec_lat#i#">Decimal Latitude</label>
								<input type="text" name="DEC_LAT" id="dec_lat#i#" value="#DEC_LAT#" class="reqdClr">
							</td>
							<td>
								<label for="dec_long#i#">Decimal Longitude</label>
								<input type="text" name="DEC_LONG" value="#DEC_LONG#" id="dec_long#i#" class="reqdClr">
							</td>
						</tr>
					</table>
					<table id="utm#i#" style="display:none;">
						<tr>
							<td>
								<label for="utm_zone#i#">UTM Zone<label>
								<input type="text" name="UTM_ZONE" value="#UTM_ZONE#" id="utm_zone#i#" class="reqdClr">
							</td>
							<td>
								<label for="utm_ew#i#">UTM East/West<label>
								<input type="text" name="UTM_EW" value="#UTM_EW#" id="utm_ew#i#" class="reqdClr">
							</td>
							<td>
								<label for="utm_ns#i#">UTM North/South<label>
								<input type="text" name="UTM_NS" value="#UTM_NS#" id="utm_ns#i#" class="reqdClr">
							</td>
						</tr>
					</table>
				</td>
			</tr>
			<tr>
				<td colspan="4">
					<label for = "errorPoly#i#">Error Polygon<label>
					<input type="text" name="errorPoly" value="#ERROR_POLYGON#" id = "ERROR_POLYGON#i#" size="120" readonly>
				</td>
			</tr>
              <tr>
                <td colspan=<cfif #accepted_lat_long_fg# is 1>"2"<cfelse>"4"</cfif>>
				<input type="button" value="Save Changes" class="savBtn"
  						 onmouseover="this.className='savBtn btnhov'"
						 onmouseout="this.className='savBtn'"
						 onClick="latLong#i#.Action.value='editAccLatLong';submit();">
				<input type="button" value="Delete" class="delBtn"
  						 onmouseover="this.className='delBtn btnhov'"
						 onmouseout="this.className='delBtn'" onClick="latLong#i#.Action.value='deleteLatLong';confirmDelete('latLong#i#');">
				</td>
				<cfif #accepted_lat_long_fg# is 1>
				<td colspan="1">
				<input type="button" value="Copy Polygon from LocID:" class="savBtn"
  						 onmouseover="this.className='savBtn btnhov'"
						 onmouseout="this.className='savBtn'"
						 onClick="latLong#i#.Action.value='copypolygon';
						 	if(latLong#i#.copyPolyFrom.value.length==0){
						 		alert('You need to enter a Locality ID');}
						 	else if(latLong#i#.errorPoly.value.length>0)
						 		{var r=confirm('This lat/long has an error polygon. Do you wish to overwrite?');
						 		if (r==true)
						 			{submit();}
						 		else
						 			{return false;}

						 		}
						 	else {submit()};">
				<input type="text" name="copyPolyFrom" value="" size="10">
				</td>
				<td colspan="1">
				<label for="wktFile">Load Polygon from WKT file</label>
				<input type="file"
						id="wktFile"
						name="wktFile"
						accept=".wkt"
						>
				</td>
				</cfif>
              </tr>
            </table>
          </form>

		  </td></tr>
		  	<script>
				showLLFormat('#orig_lat_long_units#','#i#')
			</script>
			<cfset i=#i#+1>
        </cfoutput>
		</table>
		 <cfoutput>











		<form name="newlatLong" method="post" action="editLocality.cfm">
            <input type="hidden" name="Action" value="AddLatLong">
            <input type="hidden" name="locality_id" value="#locDet.locality_id#">



<table> <tr><td><h4 style="margin: 1.5em 0 .5em 0;">Add Coordinate Determination&nbsp;&nbsp;<img src="/images/info_i_2.gif" border="0" onClick="getMCZDocs('Georeferencing')" class="likeLink" alt="[ help ]"></h4></td>

				<td>
					&nbsp;&nbsp;&nbsp;
					<span style="font-size:smaller;">
				        <a href="http://manisnet.org/gci2.html" target="_blank">Georef Calculator<img src="/images/linkOut.gif" border="0"></a>
				     </span>
				</td>
    </tr>
            </table>
<table class="newRec" style="padding: .5em 0;margin: 0 0 1em 0;background-color:none;padding-left: 5px;padding-right: 8px;">

		<tr>
            <td style="padding-right:20px;width:150px;"><p><i>You have original coordinates:</i><br/> <b>Enter manually</b></p></td>
			<td id="addNewLL" colspan="4" style="border-right: 1px solid green;padding-right: 10px;">

				<label for="ORIG_LAT_LONG_UNITS">
					<a href="javascript:void(0);" onClick="getDocs('lat_long','original_units')">Original Units</a>
				</label>
				<select name="ORIG_LAT_LONG_U"
					id="ORIG_LAT_LONG_U" size="1"
					class="reqdClr"
                    style="width: 220px"
					onchange="document.getElementById('ORIG_LAT_LONG_UNITS').value=this.value; showLLFormat(this.value,'')">
	                    		<option selected value="">Pick one...</option>
					<cfloop query="ctunits">
						<option value="#ctunits.ORIG_LAT_LONG_UNITS#">#ctunits.ORIG_LAT_LONG_UNITS#</option>
					</cfloop>
	                  	</select>
            </td>
                <td>&nbsp;</td>
            <td><label>&nbsp;</label>&nbsp;or&nbsp;</td>
            <td>&nbsp;</td>
            <td colspan="2" style="border-left: 1px solid green;padding-left: 20px;"><p><i>You have a specific locality: <br/></i><b>Use GeoLocate</b></p></td>
            <td style="padding-left: 20px;">
                <label>&nbsp;</label>
				<input type="button" value="GeoLocate" class="insBtn" style="background-color: ##ccffcc;"
					onClick="showLLFormat('decimal degrees',''); geolocate();">
                <p style="font-size:11px;">Some fields will still need to be entered manually after saving the georeference in the GeoLocate app.</p>
			</td>
    </tr>

		<tr>
			<td>
		<table border id="llMeta" style="display:none;">
              <tr>
                <td>
					<label for="ORIG_LAT_LONG_UNITS">
						<a href="javascript:void(0);" onClick="getDocs('lat_long','original_units')">Original Units</a>
					</label>
					<select name="ORIG_LAT_LONG_UNITS" id="ORIG_LAT_LONG_UNITS" size="1" class="reqdClr"
						onchange="showLLFormat(this.value,'')">
	                    <cfloop query="ctunits">
	                      <option value="#ctunits.ORIG_LAT_LONG_UNITS#">#ctunits.ORIG_LAT_LONG_UNITS#</option>
	                    </cfloop>
	                  </select>
				</td>
				<td nowrap>
	                <label for="accepted_lat_long_fg">
						<a href="javascript:void(0);" onClick="getDocs('lat_long','accepted')">Accepted?</a>
					</label>
					<select name="accepted_lat_long_fg" id="accepted_lat_long_fg" size="1" class="reqdClr">
						<option selected value="1">yes</option>
						<option value="0">no</option>
					</select>
				</td>
				<td>
					<label for="determined_by">
						<a href="javascript:void(0);" onClick="getDocs('lat_long','determiner')">Determiner</a>
					</label>
					<input type="text" name="determined_by" id="determined_by" class="reqdClr" size="40"
						onchange="getAgent('determined_by_agent_id','determined_by','newlatLong',this.value); return false;"
		 				onKeyPress="return noenter(event);">
		 			<input type="hidden" name="determined_by_agent_id">
				</td>
				<td>
					<label for="determined_date">
						<a href="javascript:void(0);" onClick="getDocs('lat_long','date')">Determined Date</a>
					</label>
					<input type="text" name="determined_date" id="determined_date" class="reqdClr">
				</td>
              </tr>
            <tr>
				<td>
					<table>
						<tr>
							<td>
								<label for="MAX_ERROR_DISTANCE">
									<a href="javascript:void(0);" onClick="getDocs('lat_long','maximum_error')">Maximum Error</a>
								</label>
								<input type="text" name="MAX_ERROR_DISTANCE" id="MAX_ERROR_DISTANCE" size="6">
							</td>
							<td>
								<label for="MAX_ERROR_UNITS">
									<a href="javascript:void(0);" onClick="getDocs('lat_long','maximum_error')">Maximum Error Units</a>
								</label>
								<select name="MAX_ERROR_UNITS" size="1" id="MAX_ERROR_UNITS">
				                    <option value=""></option>
				                    <cfloop query="cterror">
				                      <option value="#cterror.LAT_LONG_ERROR_UNITS#">#cterror.LAT_LONG_ERROR_UNITS#</option>
				                    </cfloop>
				                  </select>
							</td>
						</tr>
					</table>
				</td>
				<td>
					<label for="DATUM">
						<a href="javascript:void(0);" onClick="getDocs('lat_long','datum')">Datum</a>
					</label>
					<select name="DATUM" id="DATUM" size="1" class="reqdClr">
	                    <option value=""></option>
	                    <cfloop query="ctdatum">
	                      <option value="#ctdatum.DATUM#">#ctdatum.DATUM#</option>
	                    </cfloop>
	                  </select>
				</td>
				<td>
					<label for="georefMethod">
						Georeference Method
					</label>
					<select name="georefMethod" id="georefMethod" size="1" class="reqdClr narrowselect" style="width: 300px !important;">
				   		<cfloop query="ctGeorefMethod">
							<option value="#georefMethod#">#georefMethod#</option>
						</cfloop>
				   </select>
				</td>
				<td>
					<label for="extent">
						Extent
					</label>
					<input type="text" name="extent" id="extent" size="7">
				</td>
			</tr>
			<tr>
				<td>
					<label for="GpsAccuracy">
						GPS Accuracy
					</label>
					<input type="text" name="GpsAccuracy" id="GpsAccuracy" size="7">
				</td>
				<td>
					<label for="VerificationStatus">
						Verification Status
					</label>
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
								<option value="#VerificationStatus#">#VerificationStatus#</option>
							</cfloop>
					   </select>
				</td>
				<td colspan=2>
					<label for="verified_by" id="verified_byLBL" style="display:none">
						Verified by
					</label>
					<input type="text" name="verified_by" id="verified_by" size="40" style="display:none"
						onchange="if (this.value.length > 0){getAgent('verified_by_agent_id','verified_by','newlatLong',this.value); return false;}"
		 				onKeyPress="return noenter(event);">
		 			<input type="hidden" name="verified_by_agent_id">
				</td>
			</tr>
			<tr>
				<td colspan="4">
					<label for="LAT_LONG_REMARKS">
						Remarks
					</label>
					<input type="text"
						name="LAT_LONG_REMARKS"
						id="LAT_LONG_REMARKS"
						size="60">
				</td>
			</tr>
			<tr>
				<td colspan="4">
					<label for="LAT_LONG_REF_SOURCE">
						Reference
					</label>
					<input type="text" name="LAT_LONG_REF_SOURCE"
						id="LAT_LONG_REF_SOURCE" size="120" class="reqdClr" />
					<script>
						$(function() {
      							$("##LAT_LONG_REF_SOURCE").autocomplete({source:"component//functions.cfc?method=getLatLonRefSourceFilter",minLength:2 });
						});
					</script>
				</td>
			</tr>
			<tr>
				<td colspan="4">
					 <table id="dms" style="display:none;">
						<tr>
							<td>
								<label for="lat_deg">Lat. Deg.</label>
								<input type="text" name="LAT_DEG" size="4" id="lat_deg" class="reqdClr">
							</td>
							<td>
								<label for="lat_min">Lat. Min.</label>
								<input type="text" name="LAT_MIN" size="4" id="lat_min" class="reqdClr">
							</td>
							<td>
								<label for="lat_sec">Lat. Sec.</label>
								<input type="text" name="LAT_SEC" id="lat_sec" class="reqdClr">
							</td>
							<td>
								<label for="lat_dir">Lat. Dir.</label>
								<select name="LAT_DIR" size="1" id="lat_dir"  class="reqdClr">
									<option value=""></option>
							        <option value="N">N</option>
							        <option value="S">S</option>
							    </select>
							</td>
						</tr>
						<tr>
							<td>
								<label for="long_deg">Long. Deg.</label>
								<input type="text" name="LONG_DEG" size="4" id="long_deg" class="reqdClr">
							</td>
							<td>
								<label for="long_min">Long. Min.</label>
								<input type="text" name="LONG_MIN" size="4" id="long_min" class="reqdClr">
							</td>
							<td>
								<label for="long_sec">Long. Sec.</label>
								<input type="text" name="LONG_SEC" id="long_sec"  class="reqdClr">
							</td>
							<td>
								<label for="long_dir">Long. Dir.</label>
								<select name="LONG_DIR" size="1" id="long_dir" class="reqdClr">
							    	 <option value="E">E</option>
							        <option value="W">W</option>
							    </select>
							</td>
						</tr>
					</table>
					<table id="ddm" style="display:none;">
						<tr>
							<td>
								<label for="dmlat_deg">Lat. Deg.<label>
								<input type="text" name="dmLAT_DEG" size="4" id="dmlat_deg" class="reqdClr">
							</td>
							<td>
								<label for="dec_lat_min">Lat. Dec. Min.<label>
								<input type="text" name="DEC_LAT_MIN" id="dec_lat_min" class="reqdClr">
							</td>
							<td>
								<label for="dmlat_dir">Lat. Dir.<label>
								<select name="dmLAT_DIR" size="1" id="dmlat_dir" class="reqdClr">
				                	<option value="N">N</option>
				                   	<option value="S">S</option>
				                 </select>
							</td>
						</tr>
						<tr>
							<td>
								<label for="dmlong_deg">Long. Deg.<label>
								<input type="text" name="dmLONG_DEG" size="4" id="dmlong_deg" class="reqdClr">
							</td>
							<td>
								<label for="dec_long_min">Long. Dec. Min.<label>
								<input type="text" name="DEC_LONG_MIN" id="dec_long_min" class="reqdClr">
							</td>
							<td>
								<label for="dmlong_dir">Long. Dir.<label>
								<select name="dmLONG_DIR" size="1" id="dmlong_dir" class="reqdClr">
								    <option value="E">E</option>
								    <option value="W">W</option>
								</select>
							</td>
						</tr>
					</table>
					 <table id="dd" style="display:none;">
						<tr>
							<td>
								<label for="dec_lat">Decimal Latitude</label>
								<input type="text" name="DEC_LAT" id="dec_lat"class="reqdClr">
							</td>
							<td>
								<label for="dec_long">Decimal Longitude</label>
								<input type="text" name="DEC_LONG" id="dec_long" class="reqdClr">
							</td>
						</tr>
					</table>
					<table id="utm" style="display:none;">
						<tr>
							<td>
								<label for="utm_zone">UTM Zone<label>
								<input type="text" name="UTM_ZONE" id="utm_zone" class="reqdClr">
							</td>
							<td>
								<label for="utm_ew">UTM East/West<label>
								<input type="text" name="UTM_EW"  id="utm_ew" class="reqdClr">
							</td>
							<td>
								<label for="utm_ns">UTM North/South<label>
								<input type="text" name="UTM_NS" id="utm_ns" class="reqdClr">
							</td>
						</tr>
					</table>
				</td>
			</tr>
			<tr>
				<td colspan="4">
					<label for = "errorPoly">Error Polygon<label>
					<input type="text" name="errorPoly" id = "errorPoly" size="120" readonly>
				</td>
			</tr>
              <tr>
          <td colspan="4">
				  <!---  <input type="button" value="Georeference with GeoLocate" class="insBtn"
						 onClick="geolocate();">--->
				<input type="submit" value="Create Determination" class="insBtn"
  						 onmouseover="this.className='insBtn btnhov'"
						 onmouseout="this.className='insBtn'">
                  </td>
              </tr>
            </table>
		</td>
		</tr>
			</form>

	<table >
	<hr>

	<h3 style="margin: 1.5em 0 1em 0">Geology Attributes</h3>
	<cfif geolDet.recordcount gt 0>
		<table border>
			<form name="editGeolAtt" method="post" action="editLocality.cfm">
				<input type="hidden" name="Action" value="editGeol">
            	<input type="hidden" name="locality_id" value="#locDet.locality_id#">
				<input type="hidden" name="number_of_determinations" value="#geolDet.recordcount#">

			<cfset i=1>
			<cfloop query="geolDet">
				<input type="hidden" name="geology_attribute_id_#i#" value="#geology_attribute_id#">
				<tr	#iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#	>
					<td>
						<label for="geology_attribute_#i#">Geology Attribute</label>
						<cfset ttAtt=#geology_attribute#>
						<select name="geology_attribute_#i#" id="geology_attribute_#i#" class="reqdClr" onchange="populateGeology(this.id)">
							<option value="delete" class="red">Delete This</option>
							<cfloop query="ctgeology_attribute">
								<option <cfif #geology_attribute# is #ttAtt#> selected="selected" </cfif>value="#geology_attribute#">#geology_attribute#</option>
							</cfloop>
						</select>
						<span class="infoLink" onclick="document.getElementById('geology_attribute_#i#').value='delete'">Delete This</span>
						<label for="geo_att_value">Value</label>
						<select name="geo_att_value_#i#" id="geo_att_value_#i#" class="reqdClr">
							<option value="#geo_att_value#">#geo_att_value#</option>
						</select>
						<label for="geo_att_determiner_#i#">Determiner</label>
						<input type="text" name="geo_att_determiner_#i#"  size="40"
							onchange="getAgent('geo_att_determiner_id_#i#','geo_att_determiner_#i#','editGeolAtt',this.value); return false;"
		 					onKeyPress="return noenter(event);"
		 					value="#agent_name#">
						<input type="hidden" name="geo_att_determiner_id_#i#" id="geo_att_determiner_id" value="#geo_att_determiner_id#">
						<label for="geo_att_determined_date_#i#">Date</label>
						<input type="text" name="geo_att_determined_date_#i#" id="geo_att_determined_date_#i#"
							value="#dateformat(geo_att_determined_date,'yyyy-mm-dd')#">
						<label for="geo_att_determined_method_#i#">Method</label>
						<input type="text" name="geo_att_determined_method_#i#"
							size="60"  value="#geo_att_determined_method#">
						<label for="geo_att_remark_#i#">Remark</label>
						<input type="text" name="geo_att_remark_#i#"
							size="60" value="#stripquotes(geo_att_remark)#">
					</td>
				</tr>
				<cfset i=i+1>
			</cfloop>
			<tr>
				<td colspan="2">
					<input type="submit"
					value="Save Changes"
					class="savBtn"
					onmouseover="this.className='savBtn btnhov'"
					onmouseout="this.className='savBtn'">
				</td>
			</tr>

		</table>

		</form>
	</cfif>
        <h4 style="margin: 1.5em 0 .5em 0">Create Geology Determination</h4>
	<table class="newRec">
		<tr>
			<td>
			<form name="newGeolDet" method="post" action="editLocality.cfm">
            <input type="hidden" name="Action" value="AddGeol">
            <input type="hidden" name="locality_id" value="#locDet.locality_id#">
				<label for="geology_attribute">Geology Attribute</label>
				<select name="geology_attribute" id="geology_attribute" class="reqdClr" onchange="populateGeology(this.id)">
					<option value=""></option>
					<cfloop query="ctgeology_attribute">
						<option value="#geology_attribute#">#geology_attribute#</option>
					</cfloop>
				</select>
				<label for="geo_att_value">Value</label>
				<select name="geo_att_value" id="geo_att_value" class="reqdClr"></select>
				<label for="geo_att_determiner">Determiner</label>
				<input type="text" name="geo_att_determiner" id="geo_att_determiner" size="40"
						onchange="getAgent('geo_att_determiner_id','geo_att_determiner','newGeolDet',this.value); return false;"
		 				onKeyPress="return noenter(event);">
				<input type="hidden" name="geo_att_determiner_id" id="geo_att_determiner_id">
				<label for="geo_att_determined_date">Determined Date</label>
				<input type="text" name="geo_att_determined_date" id="geo_att_determined_date">
				<label for="geo_att_determined_method">Determination Method</label>
				<input type="text" name="geo_att_determined_method" id="geo_att_determined_method" size="60">
				<label for="geo_att_remark">Remark</label>
				<input type="text" name="geo_att_remark" id="geo_att_remark" size="60">
				<br>
				<input type="submit"
					value="Create Determination"
					class="insBtn"
					onmouseover="this.className='insBtn btnhov'"
					onmouseout="this.className='insBtn'">
			</form>
			</td>
		</tr>
	</table>
	<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
    select distinct
        media.media_id,
        media.media_uri,
        media.mime_type,
        media.media_type,
        media.preview_uri,
		 mczbase.get_media_descriptor(media.media_id) as media_descriptor
     from
         media,
         media_relations,
         media_labels
     where
         media.media_id=media_relations.media_id and
         media.media_id=media_labels.media_id (+) and
         media_relations.media_relationship like '%locality' and
         media_relations.related_primary_key = #locality_id#
	</cfquery>
	<cfif media.recordcount gt 0>
		<div class="detailCell">
			<div class="detailLabel">
				Media
				<cfquery name="wrlCount" dbtype="query">
					select * from media where mime_type = 'model/vrml'
				</cfquery>
				<cfif wrlCount.recordcount gt 0>
					<br>
					<span class="innerDetailLabel">Note: CT scans with mime type "model/vrml" require an external plugin such as <a href="http://cic.nist.gov/vrml/cosmoplayer.html">Cosmo3d</a> or <a href="http://mediamachines.wordpress.com/flux-player-and-flux-studio/">Flux Player</a>. For Mac users, a standalone player such as <a href="http://meshlab.sourceforge.net/">MeshLab</a> will be required.</span>
				</cfif>
		 		<!---cfif oneOfUs is 1>
				 <cfquery name="hasConfirmedImageAttr"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT count(*) c
					FROM
						ctattribute_type
					where attribute_type='image confirmed' and
					collection_cde='#one.collection_cde#'
				</cfquery>
				<span class="detailEditCell" onclick="window.parent.loadEditApp('MediaSearch');">Edit</span>
				<cfquery name="isConf"  dbtype="query">
					SELECT count(*) c
					FROM
						attribute
					where attribute_type='image confirmed'
				</cfquery>
				<CFIF isConf.c is "" and hasConfirmedImageAttr.c gt 0>
					<span class="infoLink"
						id="ala_image_confirm" onclick='windowOpener("/ALA_Imaging/confirmImage.cfm?collection_object_id=#collection_object_id#","alaWin","width=700,height=400, resizable,scrollbars,location,toolbar");'>
						Confirm Image IDs
					</span>
				</CFIF>
				</cfif--->
			</div>
		</div>
		<div class="detailBlock">
            <span class="detailData">
				<!---div class="thumbs"--->
					<div class="thumb_spcr">&nbsp;</div>
					<cfloop query="media">
						<cfset altText = media.media_descriptor>
						<cfset puri=getMediaPreview(preview_uri,media_type)>
		            	<cfquery name="labels"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select
								media_label,
								label_value
							from
								media_labels
							where
								media_id=#media_id#
						</cfquery>

						<cfquery name="desc" dbtype="query">
							select label_value from labels where media_label='description'
						</cfquery>
						<cfset alt="Media Preview Image">
						<cfif desc.recordcount is 1>
							<cfset alt=desc.label_value>
						</cfif>
		               <div class="one_thumb">
			               <a href="#media_uri#" target="_blank"><img src="#getMediaPreview(preview_uri,media_type)#" alt="#altText#" class="theThumb"></a>
		                   	<p>
								#media_type# (#mime_type#)
			                   	<br><a href="/media/#media_id#" target="_blank">Media Details</a>
								<br>#alt#
							</p>
						</div>
					</cfloop>
					<div class="thumb_spcr">&nbsp;</div>
				<!--/div--->
	        </span>
		</div>
	</div>
</cfif>
</div>
<div>
	<cfif isdefined("session.roles") and listfindnocase(session.roles,"collops")>
		<!---  For a small set of collections operations users, include the TDWG BDQ TG2 test integration --->
		<script type='text/javascript' language="javascript" src='/dataquality/js/bdq_quality_control.js'></script>
		<script>
			function runTests() {
				loadSpaceQC("", "#locality_id#", "SpatialDQDiv");
			}
		</script>
		<input type="button" value="QC" class="savBtn" onClick=" runTests(); ">
		<!---  Spatial tests --->
		<div id="SpatialDQDiv"></div>
	</cfif>
<div>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">
</cfif>
<!------------------------------------------------------------------------------------------------------>
<cfif action is "editGeol">
<cfoutput>
	<cfloop from="1" to="#number_of_determinations#" index="n">
		<cfset deleteThis="">
		<cfset thisID = #evaluate("geology_attribute_id_" & n)#>
		<cfset thisAttribute = #evaluate("geology_attribute_" & n)#>
		<cfset thisValue = #evaluate("geo_att_value_" & n)#>
		<cfset thisDate = #evaluate("geo_att_determined_date_" & n)#>
		<cfset thisMethod = #evaluate("geo_att_determined_method_" & n)#>
		<cfset thisDeterminer = #evaluate("geo_att_determiner_id_" & n)#>
		<cfset thisRemark = #evaluate("geo_att_remark_" & n)#>

		<cfif #thisAttribute# is "delete">
			<cfquery name="deleteGeol" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				delete from geology_attributes where geology_attribute_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisID#">
			</cfquery>
		<cfelse>
			<cfquery name="upGeol" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update
					geology_attributes
				set
					geology_attribute=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisAttribute#">,
					geo_att_value=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisValue#">
					<cfif len(#thisDeterminer#) gt 0>
						,geo_att_determiner_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisDeterminer#">
					<cfelse>
						,geo_att_determiner_id=NULL
					</cfif>
					<cfif len(#thisDate#) gt 0>
						,geo_att_determined_date=<cfqueryparam cfsqltype="CF_SQL_DATE" value="#dateformat(thisDate,"yyyy-mm-dd")#">
					<cfelse>
						,geo_att_determined_date=NULL
					</cfif>
					<cfif len(#thisMethod#) gt 0>
						,geo_att_determined_method=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisMethod#">
					<cfelse>
						,geo_att_determined_method=NULL
					</cfif>
					<cfif len(#thisRemark#) gt 0>
						,geo_att_remark=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#stripQuotes(thisRemark)#">
					<cfelse>
						,geo_att_remark=NULL
					</cfif>
				where
					geology_attribute_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisID#">
			</cfquery>
		</cfif>
	</cfloop>
	<cflocation url="editLocality.cfm?locality_id=#locality_id#" addtoken="no">
</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------------------>
<cfif action is "AddGeol">
<cfoutput>
		<cfquery name="changeGeog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			insert into geology_attributes (
    			locality_id,
			    geology_attribute,
			    geo_att_value
			    <cfif len(#geo_att_determiner_id#) gt 0>
					,geo_att_determiner_id
				</cfif>
				<cfif len(#geo_att_determined_date#) gt 0>
					,geo_att_determined_date
				</cfif>
			   	<cfif len(#geo_att_determined_method#) gt 0>
					,geo_att_determined_method
				</cfif>
			   	<cfif len(#geo_att_remark#) gt 0>
					,geo_att_remark
				</cfif>
			   ) values (
			   #locality_id#,
			   '#geology_attribute#',
			   '#stripQuotes(geo_att_value)#'
			   <cfif len(#geo_att_determiner_id#) gt 0>
					,#geo_att_determiner_id#
				</cfif>
				<cfif len(#geo_att_determined_date#) gt 0>
					,'#dateformat(geo_att_determined_date,"yyyy-mm-dd")#'
				</cfif>
				<cfif len(#geo_att_determined_method#) gt 0>
					,'#stripQuotes(geo_att_determined_method)#'
				</cfif>
				<cfif len(#geo_att_remark#) gt 0>
					,'#stripQuotes(geo_att_remark)#'
				</cfif>
			 )
		</cfquery>
		<cflocation url="editLocality.cfm?locality_id=#locality_id#" addtoken="no">
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "changeGeog">
	<cfoutput>
		<cfquery name="changeGeog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			UPDATE locality SET geog_auth_rec_id=#geog_auth_rec_id# where locality_id=#locality_id#
		</cfquery>
		<cflocation url="editLocality.cfm?locality_id=#locality_id#" addtoken="no">
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "saveLocalityEdit">
	<cfoutput>
	<cfif len(MINIMUM_ELEVATION) gt 0 OR
			len(MAXIMUM_ELEVATION) gt 0>
		<cfif len(ORIG_ELEV_UNITS) is 0>
			You must provide elevation units if you provide elevation data!
			<cfabort>
		</cfif>
	</cfif>
	<cfif len(ORIG_ELEV_UNITS) gt 0>
		<cfif len(MINIMUM_ELEVATION) is 0 AND
			len(MAXIMUM_ELEVATION) is 0>
			You can't provide elevation units if you don't provide elevation data!
			<cfabort>
		</cfif>
	</cfif>
	<cfset sql = "UPDATE locality SET locality_id = #locality_id#">
	<cfif len(#spec_locality#) gt 0>
		<cfset sql = "#sql#,spec_locality = '#escapeQuotes(spec_locality)#'">
	  <cfelse>
		<cfset sql = ",spec_locality=null">
	</cfif>
	<cfif len(#MINIMUM_ELEVATION#) gt 0>
		<cfset sql = "#sql#,MINIMUM_ELEVATION = #MINIMUM_ELEVATION#">
	<cfelse>
		<cfset sql = "#sql#,MINIMUM_ELEVATION = null">
	</cfif>
	<cfif len(#MAXIMUM_ELEVATION#) gt 0>
		<cfset sql = "#sql#,MAXIMUM_ELEVATION = #MAXIMUM_ELEVATION#">
	<cfelse>
		<cfset sql = "#sql#,MAXIMUM_ELEVATION = null">
	</cfif>
	<cfif len(#ORIG_ELEV_UNITS#) gt 0>
		<cfset sql = "#sql#,ORIG_ELEV_UNITS = '#ORIG_ELEV_UNITS#'">
	<cfelse>
		<cfset sql = "#sql#,ORIG_ELEV_UNITS = null">
	</cfif>
	<cfif len(#min_depth#) gt 0>
		<cfset sql = "#sql#,min_depth = #min_depth#">
	<cfelse>
		<cfset sql = "#sql#,min_depth = null">
	</cfif>
	<cfif len(#max_depth#) gt 0>
		<cfset sql = "#sql#,max_depth = #max_depth#">
	<cfelse>
		<cfset sql = "#sql#,max_depth = null">
	</cfif>
	<cfif len(#depth_units#) gt 0>
		<cfset sql = "#sql#,depth_units = '#depth_units#'">
	<cfelse>
		<cfset sql = "#sql#,depth_units = null">
	</cfif>
	<cfif len(#sovereign_nation#) gt 0>
		<cfset sql = "#sql#,SOVEREIGN_NATION = '#escapeQuotes(sovereign_nation)#'">
	<cfelse>
		<cfset sql = "#sql#,SOVEREIGN_NATION = '[unknown]'">
	</cfif>
	<cfif len(#LOCALITY_REMARKS#) gt 0>
		<cfset sql = "#sql#,LOCALITY_REMARKS = '#escapeQuotes(LOCALITY_REMARKS)#'">
	<cfelse>
		<cfset sql = "#sql#,LOCALITY_REMARKS = null">
	</cfif>
	<cfif len(#NoGeorefBecause#) gt 0>
		<cfset sql = "#sql#,NoGeorefBecause = '#escapeQuotes(NoGeorefBecause)#'">
	<cfelse>
		<cfset sql = "#sql#,NoGeorefBecause = null">
	</cfif>
	<cfif isdefined("curated_fg") AND len(#curated_fg#) gt 0>
		<cfset sql = "#sql#,curated_fg = '#escapeQuotes(curated_fg)#'">
	</cfif>
	<cfset sql = "#sql# where locality_id = #locality_id#">
	<cfquery name="edLoc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		#preservesinglequotes(sql)#
	</cfquery>
	<cflocation addtoken="no" url="editLocality.cfm?locality_id=#locality_id#">
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif #Action# is "deleteLocality">
<cfoutput>
	<cfquery name="isColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select collecting_event_id from collecting_event where locality_id=#locality_id#
	</cfquery>

<cfif len(#isColl.collecting_event_id#) gt 0>
	There are active collecting events for this locality. It cannot be deleted.
	<br><a href="editLocality.cfm?locality_id=#locality_id#">Return</a> to editing.
	<cfabort>
</cfif>

	<cftransaction>
		<cfquery name="deleLatLong" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from lat_long where locality_id=#locality_id#
		</cfquery>

		<cftransaction action="commit">
		<cfquery name="deleLocality" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from locality where locality_id=#locality_id#
		</cfquery>
	</cftransaction>
	<cflocation addtoken="no" url="editLocality.cfm?locality_id=#locality_id#">
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif #action# is "clone">
	<cfoutput>
		<cftransaction>
			<cfquery name="nLocId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select sq_locality_id.nextval nv from dual
			</cfquery>
			<cfset lid=nLocId.nv>
			<cfquery name="oldLoc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select * from locality where locality_id=#locality_id#
			</cfquery>
			<cfquery name="newLocality" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO locality (
					LOCALITY_ID,
					GEOG_AUTH_REC_ID
					,MAXIMUM_ELEVATION
					,MINIMUM_ELEVATION
					,ORIG_ELEV_UNITS
					,SPEC_LOCALITY
					,LOCALITY_REMARKS,
					DEPTH_UNITS,
					MIN_DEPTH,
					MAX_DEPTH,
					NOGEOREFBECAUSE,
                			SOVEREIGN_NATION,
					curated_fg
				) VALUES (
					#lid#,
					#oldLoc.GEOG_AUTH_REC_ID#
					<cfif len(#oldLoc.MAXIMUM_ELEVATION#) gt 0>
						,#oldLoc.MAXIMUM_ELEVATION#
					<cfelse>
						,NULL
					</cfif>
					<cfif len(#oldLoc.MINIMUM_ELEVATION#) gt 0>
						,#oldLoc.MINIMUM_ELEVATION#
					<cfelse>
						,NULL
					</cfif>
					<cfif len(#oldLoc.orig_elev_units#) gt 0>
						,'#oldLoc.orig_elev_units#'
					<cfelse>
						,NULL
					</cfif>
					<cfif len(#oldLoc.SPEC_LOCALITY#) gt 0>
						,'#oldLoc.SPEC_LOCALITY#'
					<cfelse>
						,NULL
					</cfif>
					<cfif len(#oldLoc.LOCALITY_REMARKS#) gt 0>
						,'#oldLoc.LOCALITY_REMARKS#'
					<cfelse>
						,NULL
					</cfif>
					<cfif len(#oldLoc.DEPTH_UNITS#) gt 0>
						,'#oldLoc.DEPTH_UNITS#'
					<cfelse>
						,NULL
					</cfif>
					<cfif len(#oldLoc.MIN_DEPTH#) gt 0>
						,#oldLoc.MIN_DEPTH#
					<cfelse>
						,NULL
					</cfif>
					<cfif len(#oldLoc.MAX_DEPTH#) gt 0>
						,#oldLoc.MAX_DEPTH#
					<cfelse>
						,NULL
					</cfif>
					<cfif len(#oldLoc.NOGEOREFBECAUSE#) gt 0>
						,'#oldLoc.NOGEOREFBECAUSE#'
					<cfelse>
						,NULL
					</cfif>
					<cfif len(#oldLoc.SOVEREIGN_NATION#) gt 0>
						,'#oldLoc.SOVEREIGN_NATION#'
					<cfelse>
						,'[unknown]'
					</cfif>
					,#oldLoc.curated_fg#
				)
			</cfquery>
			<cfif isdefined("keepAcc") and keepAcc is 1>
				<cfquery name="accCoord" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select * from lat_long where locality_id=#locality_id# and accepted_lat_long_fg=1
				</cfquery>
				<cfloop query="accCoord">
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
							,VERIFICATIONSTATUS
							,VERIFIED_BY_AGENT_ID
							,ERROR_POLYGON)
						VALUES (
							sq_lat_long_id.nextval,
							#lid#
							<cfif len(#LAT_DEG#) gt 0>
								,#LAT_DEG#
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#DEC_LAT_MIN#) gt 0>
								,#DEC_LAT_MIN#
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LAT_MIN#) gt 0>
								,#LAT_MIN#
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LAT_SEC#) gt 0>
								,#LAT_SEC#
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LAT_DIR#) gt 0>
								,'#LAT_DIR#'
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LONG_DEG#) gt 0>
								,#LONG_DEG#
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#DEC_LONG_MIN#) gt 0>
								,#DEC_LONG_MIN#
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LONG_MIN#) gt 0>
								,#LONG_MIN#
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LONG_SEC#) gt 0>
								,#LONG_SEC#
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LONG_DIR#) gt 0>
								,'#LONG_DIR#'
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#DEC_LAT#) gt 0>
								,#DEC_LAT#
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#DEC_LONG#) gt 0>
								,#DEC_LONG#
							<cfelse>
								,NULL
							</cfif>
						    ,<cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#DATUM#">
							<cfif len(#UTM_ZONE#) gt 0>
						        ,<cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#UTM_ZONE#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#UTM_EW#) gt 0>
						        ,<cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#UTM_EW#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#UTM_NS#) gt 0>
						        ,<cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#UTM_NS#">
							<cfelse>
								,NULL
							</cfif>
							,'#ORIG_LAT_LONG_UNITS#'
						    ,<cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#DETERMINED_BY_AGENT_ID#">
							,'#dateformat(DETERMINED_DATE,"yyyy-mm-dd")#'
						    ,<cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#LAT_LONG_REF_SOURCE#">
							<cfif len(#LAT_LONG_REMARKS#) gt 0>
						        ,<cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#LAT_LONG_REMARKS#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#MAX_ERROR_DISTANCE#) gt 0>
						        ,<cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#MAX_ERROR_DISTANCE#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#MAX_ERROR_UNITS#) gt 0>
								,'#MAX_ERROR_UNITS#'
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#NEAREST_NAMED_PLACE#) gt 0>
								,'#NEAREST_NAMED_PLACE#'
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LAT_LONG_FOR_NNP_FG#) gt 0>
								,#LAT_LONG_FOR_NNP_FG#
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#FIELD_VERIFIED_FG#) gt 0>
								,#FIELD_VERIFIED_FG#
							<cfelse>
								,NULL
							</cfif>
							,#ACCEPTED_LAT_LONG_FG#
							<cfif len(#EXTENT#) gt 0>
								,#EXTENT#
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#GPSACCURACY#) gt 0>
								,#GPSACCURACY#
							<cfelse>
								,NULL
							</cfif>
							,'#GEOREFMETHOD#'
							,'#VERIFICATIONSTATUS#'
							<cfif len(#VERIFIED_BY_AGENT_ID#) gt 0>
								, <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#VERIFIED_BY_AGENT_ID#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#ERROR_POLYGON#) gt 0>
								, <cfqueryparam CFSQLTYPE="CF_SQL_CLOB" value="#ERROR_POLYGON#">
							<cfelse>
								,NULL
							</cfif>)
					</cfquery>
				</cfloop>
			</cfif>
			<cfif isdefined("keepUnacc") and keepUnacc is 1>
				<cfquery name="uaccCoord" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select * from lat_long where locality_id=#locality_id# and accepted_lat_long_fg=0
				</cfquery>
				<cfloop query="uaccCoord">
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
							,VERIFICATIONSTATUS,
							,VERIFIED_BY_AGENT_ID
							,ERROR_POLYGON)
						VALUES (
							sq_lat_long_id.nextval,
							#lid#
							<cfif len(#LAT_DEG#) gt 0>
								,#LAT_DEG#
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#DEC_LAT_MIN#) gt 0>
								,#DEC_LAT_MIN#
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LAT_MIN#) gt 0>
								,#LAT_MIN#
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LAT_SEC#) gt 0>
								,#LAT_SEC#
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LAT_DIR#) gt 0>
								,'#LAT_DIR#'
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LONG_DEG#) gt 0>
								,#LONG_DEG#
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#DEC_LONG_MIN#) gt 0>
								,#DEC_LONG_MIN#
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LONG_MIN#) gt 0>
								,#LONG_MIN#
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LONG_SEC#) gt 0>
								,#LONG_SEC#
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LONG_DIR#) gt 0>
								,'#LONG_DIR#'
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#DEC_LAT#) gt 0>
								,#DEC_LAT#
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#DEC_LONG#) gt 0>
								,#DEC_LONG#
							<cfelse>
								,NULL
							</cfif>
							,'#DATUM#'
							<cfif len(#UTM_ZONE#) gt 0>
								,'#UTM_ZONE#'
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#UTM_EW#) gt 0>
								,'#UTM_EW#'
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#UTM_NS#) gt 0>
								,'#UTM_NS#'
							<cfelse>
								,NULL
							</cfif>
							,'#ORIG_LAT_LONG_UNITS#'
							,#DETERMINED_BY_AGENT_ID#
							,'#dateformat(DETERMINED_DATE,"yyyy-mm-dd")#'
							,'#LAT_LONG_REF_SOURCE#'
							<cfif len(#LAT_LONG_REMARKS#) gt 0>
						        ,<cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#LAT_LONG_REMARKS#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#MAX_ERROR_DISTANCE#) gt 0>
								,#MAX_ERROR_DISTANCE#
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#MAX_ERROR_UNITS#) gt 0>
								,'#MAX_ERROR_UNITS#'
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#NEAREST_NAMED_PLACE#) gt 0>
								,'#NEAREST_NAMED_PLACE#'
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LAT_LONG_FOR_NNP_FG#) gt 0>
								,#LAT_LONG_FOR_NNP_FG#
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#FIELD_VERIFIED_FG#) gt 0>
								,#FIELD_VERIFIED_FG#
							<cfelse>
								,NULL
							</cfif>
							,#ACCEPTED_LAT_LONG_FG#
							<cfif len(#EXTENT#) gt 0>
								,#EXTENT#
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#GPSACCURACY#) gt 0>
								,#GPSACCURACY#
							<cfelse>
								,NULL
							</cfif>
							,'#GEOREFMETHOD#'
							,'#VERIFICATIONSTATUS#'
							<cfif len(#VERIFIED_BY_AGENT_ID#) gt 0>
								, <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#VERIFIED_BY_AGENT_ID#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#ERROR_POLYGON#) gt 0>
								, <cfqueryparam CFSQLTYPE="CF_SQL_CLOB" value="#ERROR_POLYGON#">
							<cfelse>
								,NULL
							</cfif>)
					</cfquery>
				</cfloop>
			</cfif>
		</cftransaction>
		<cflocation url="editLocality.cfm?locality_id=#lid#">
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif #Action# is "editAccLatLong">

<cfoutput>

<!--- update things that we're allowing changes to. Set non-original units to null and
	get them once we have an Oracle procedure in place to handle conversions --->
<!---cftransaction--->
<cfif ACCEPTED_LAT_LONG_FG is 1>
	<!---flagging all zero ACCEPTED_LAT_LONG_FG: #ACCEPTED_LAT_LONG_FG# for LOCALITY_ID: #locality_id#--->
	<cfquery name="flagAllZero" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update lat_long set ACCEPTED_LAT_LONG_FG=0 where
		locality_id = #locality_id#
	</cfquery>
	<!---success?--->
</cfif>
<cfset sql = "
	UPDATE lat_long SET
		DATUM = '#DATUM#'
		,ACCEPTED_LAT_LONG_FG = #ACCEPTED_LAT_LONG_FG#
		,orig_lat_long_units = '#orig_lat_long_units#'
		,determined_date = '#dateformat(determined_date,'yyyy-mm-dd')#'
		,lat_long_ref_source = '#stripQuotes(lat_long_ref_source)#'
		,determined_by_agent_id = #determined_by_agent_id#
		,georefMethod='#georefMethod#'
		,VerificationStatus='#VerificationStatus#'">
		<cfif len(#VERIFIED_BY_AGENT_ID#) gt 0 and len(#VERIFIED_BY#) GT 0>
			<cfset sql = "#sql#,VERIFIED_BY_AGENT_ID = #VERIFIED_BY_AGENT_ID#">
		  <cfelse>
			<cfset sql = "#sql#,VERIFIED_BY_AGENT_ID = NULL">
		</cfif>
		<cfif len(#MAX_ERROR_DISTANCE#) gt 0>
			<cfset sql = "#sql#,MAX_ERROR_DISTANCE = #MAX_ERROR_DISTANCE#">
		  <cfelse>
			<cfset sql = "#sql#,MAX_ERROR_DISTANCE = NULL">
		</cfif>
		<cfif len(#MAX_ERROR_UNITS#) gt 0>
			<cfset sql = "#sql#,MAX_ERROR_UNITS = '#MAX_ERROR_UNITS#'">
		  <cfelse>
			<cfset sql = "#sql#,MAX_ERROR_UNITS = NULL">
		</cfif>
		<cfif len(#LAT_LONG_REMARKS#) gt 0>
			<cfset sql = "#sql#,LAT_LONG_REMARKS = '#escapeQuotes(LAT_LONG_REMARKS)#'">
		  <cfelse>
			<cfset sql = "#sql#,LAT_LONG_REMARKS = null">
		</cfif>
		<cfif len(#extent#) gt 0>
			<cfset sql = "#sql#,extent=#extent#">
		<cfelse>
			<cfset sql = "#sql#,extent=null">
		</cfif>
		<cfif len(#GpsAccuracy#) gt 0>
			<cfset sql = "#sql#,GpsAccuracy=#GpsAccuracy#">
		<cfelse>
			<cfset sql = "#sql#,GpsAccuracy=null">
		</cfif>
		<cfif len(#LAT_SEC#) EQ 0>
			<cfset lat_sec="null">
		</cfif>
		<cfif len(#LONG_SEC#) EQ 0>
			<cfset long_sec="null">
		</cfif>
		<cfif len(#LONG_SEC#) EQ 0>
			<cfset long_sec="null">
		</cfif>
		<cfif #ORIG_LAT_LONG_UNITS# is "deg. min. sec.">
			<cfset sql = "#sql#
				,LAT_DEG = #LAT_DEG#
				,LAT_MIN = #LAT_MIN#
				,LAT_SEC = #LAT_SEC#
				,LAT_DIR = '#LAT_DIR#'
				,LONG_DEG = #LONG_DEG#
				,LONG_MIN = #LONG_MIN#
				,LONG_SEC = #LONG_SEC#
				,LONG_DIR = '#LONG_DIR#'
				,DEC_LAT = null
				,DEC_LONG = null
				,UTM_ZONE = null
				,UTM_EW = null
				,UTM_NS = null
				,DEC_LAT_MIN = null
				,DEC_LONG_MIN = null">
		<cfelseif #ORIG_LAT_LONG_UNITS# is "degrees dec. minutes">
			<cfset sql = "#sql#
				,LAT_DEG = #dmLAT_DEG#
				,LAT_MIN = null
				,LAT_SEC = null
				,LAT_DIR = '#dmLAT_DIR#'
				,LONG_DEG = #dmLONG_DEG#
				,LONG_MIN = null
				,LONG_SEC = null
				,LONG_DIR = '#dmLONG_DIR#'
				,DEC_LAT = null
				,DEC_LONG = null
				,UTM_ZONE = null
				,UTM_EW = null
				,UTM_NS = null
				,DEC_LAT_MIN = #DEC_LAT_MIN#
				,DEC_LONG_MIN = #DEC_LONG_MIN#
				">
		<cfelseif #ORIG_LAT_LONG_UNITS# is "decimal degrees">
			<cfset sql = "#sql#
				,LAT_DEG = null
				,LAT_MIN = null
				,LAT_SEC = null
				,LAT_DIR = null
				,LONG_DEG = null
				,LONG_MIN = null
				,LONG_SEC = null
				,LONG_DIR = null
				,DEC_LAT = #DEC_LAT#
				,DEC_LONG = #DEC_LONG#
				,UTM_ZONE = null
				,UTM_EW = null
				,UTM_NS = null
				,DEC_LAT_MIN = null
				,DEC_LONG_MIN = null
				">
		<cfelseif #ORIG_LAT_LONG_UNITS# is "UTM">
			<cfset sql = "#sql#
				,LAT_DEG = null
				,LAT_MIN = null
				,LAT_SEC = null
				,LAT_DIR = null
				,LONG_DEG = null
				,LONG_MIN = null
				,LONG_SEC = null
				,LONG_DIR = null
				,DEC_LAT = null
				,DEC_LONG = null
				,UTM_ZONE = '#UTM_ZONE#'
				,UTM_EW = #UTM_EW#
				,UTM_NS = #UTM_NS#
				,DEC_LAT_MIN = null
				,DEC_LONG_MIN = null
				">
		<cfelse>
			<div class="error">
			You really can't load #ORIG_LAT_LONG_UNITS#. Really. I wouldn't lie to you! Clean up the code table!
			Use your back button or
			<br><a href="editLocality.cfm?locality_id=#locality_id#">continue editing</a>.
			</div>
			<cfabort>
		</cfif>
		<cfset sql = "#sql#	where lat_long_id=#lat_long_id#">
<cftransaction>
<cfquery name="upLatLong" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	#preservesinglequotes(sql)#
</cfquery>

<!---/cftransaction--->
<cfif isdefined("wktFile") and len(wktFile) GT 0>
	<cfquery name="addPoly" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update lat_long set error_polygon =  <cfqueryparam cfsqltype="cf_sql_clob" value="#errorPoly#"> where lat_long_id = #lat_long_id#
	</cfquery>
</cfif>
</cftransaction>
<cfquery name="getAcc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select lat_long_id from lat_long where locality_id=#locality_id#
	and accepted_lat_long_fg = 1
</cfquery>
<cfif #getAcc.recordcount# is 1>
	<cflocation url="editLocality.cfm?locality_id=#locality_id#" addtoken="no">
<cfelseif #getAcc.recordcount# gt 1>
	<div class="error">
	There are more than one accepted lat_longs for this locality. Please change all but one
	of them to unaccepted. A better fix is coming soon.

	<br><a href="editLocality.cfm?locality_id=#locality_id#">continue</a>
	</div>
	<cfabort>
<cfelseif #getAcc.recordcount# lt 1>
	<div class="error">
	There are no accepted lat_longs for this locality. Is that what you meant to do?
	<br><a href="editLocality.cfm?locality_id=#locality_id#">continue</a>
	</div>
		<cfabort>
</cfif>
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif #Action# is "AddLatLong">
<cfoutput>
	<cfquery name="notAcc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		UPDATE lat_long SET accepted_lat_long_fg = 0 where
		locality_id=#locality_id#
	</cfquery>
	<cfquery name="getLATLONGID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select sq_lat_long_id.nextval latlongid from dual
	</cfquery>
	<cfset sql = "
	INSERT INTO lat_long (
		LAT_LONG_ID
		,LOCALITY_ID
		,ACCEPTED_LAT_LONG_FG
		,lat_long_ref_source
		,determined_by_agent_id
		,determined_date
		,ORIG_LAT_LONG_UNITS
		,georefmethod
		,verificationstatus
		,DATUM
		">
		<cfif len(#verified_by_agent_id#) gt 0>
			<cfset sql = "#sql#,verified_by_agent_id">
		</cfif>
		<cfif len(#gpsaccuracy#) gt 0>
			<cfset sql = "#sql#,gpsaccuracy">
		</cfif>
		<cfif len(#extent#) gt 0>
			<cfset sql = "#sql#,extent">
		</cfif>
		<cfif len(#gpsaccuracy#) gt 0>
			<cfset sql = "#sql#,gpsaccuracy">
		</cfif>
		<cfif len(#LAT_LONG_REMARKS#) gt 0>
			<cfset sql = "#sql#,LAT_LONG_REMARKS">
		</cfif>
		<cfif len(#MAX_ERROR_DISTANCE#) gt 0>
			<cfset sql = "#sql#,MAX_ERROR_DISTANCE">
		</cfif>
		<cfif len(#MAX_ERROR_UNITS#) gt 0>
			<cfset sql = "#sql#,MAX_ERROR_UNITS">
		</cfif>
		<cfif #ORIG_LAT_LONG_UNITS# is "deg. min. sec.">
			<cfset sql="#sql#
			,LAT_DEG
			,LAT_MIN
			,LAT_SEC
			,LAT_DIR
			,LONG_DEG
			,LONG_MIN
			,LONG_SEC
			,LONG_DIR">
		<cfelseif #ORIG_LAT_LONG_UNITS# is "degrees dec. minutes">
			<cfset sql="#sql#
				,LAT_DEG
				,DEC_LAT_MIN
				,LAT_DIR
				,LONG_DEG
				,DEC_LONG_MIN
				,LONG_DIR
				">
		<cfelseif #ORIG_LAT_LONG_UNITS# is "decimal degrees">
			<cfset sql="#sql#
				,DEC_LAT
				,DEC_LONG">
		<cfelseif #ORIG_LAT_LONG_UNITS# is "UTM">
			 <cfset sql="#sql#
			 	,UTM_ZONE
			 	,UTM_EW
			 	,UTM_NS">
		<cfelse>
			<div class="error">
			You really can't load #ORIG_LAT_LONG_UNITS#. Really. I wouldn't lie to you! Clean up the code table!
			Use your back button or
			<br><a href="editLocality.cfm?locality_id=#locality_id#">continue editing</a>.
			</div>
			<cfabort>
		</cfif>

		<cfset sql="#sql#
		)
	VALUES (
		#getLATLONGID.latlongid#,
		#LOCALITY_ID#
		,#ACCEPTED_LAT_LONG_FG#
		,'#stripQuotes(lat_long_ref_source)#'
		,#determined_by_agent_id#
		,'#dateformat(determined_date,'yyyy-mm-dd')#'
		,'#ORIG_LAT_LONG_UNITS#'
		,'#georefmethod#'
		,'#verificationstatus#'
		,'#DATUM#'">
		<cfif len(#verified_by_agent_id#) gt 0 and len(#verified_by# GT 0)>
			<cfset sql = "#sql#,#verified_by_agent_id#">
		</cfif>
		<cfif len(#extent#) gt 0>
			<cfset sql="#sql#,'#extent#'">
		</cfif>
		<cfif len(#gpsaccuracy#) gt 0>
			<cfset sql = "#sql#,#gpsaccuracy#">
		</cfif>
		<cfif len(#LAT_LONG_REMARKS#) gt 0>
			<cfset sql="#sql#,'#escapeQuotes(LAT_LONG_REMARKS)#'">
		</cfif>
		<cfif len(#MAX_ERROR_DISTANCE#) gt 0>
			<cfset sql="#sql#,#MAX_ERROR_DISTANCE#">
		</cfif>
		<cfif len(#MAX_ERROR_UNITS#) gt 0>
			<cfset sql="#sql#,'#MAX_ERROR_UNITS#'">
		</cfif>
		<cfif #ORIG_LAT_LONG_UNITS# is "deg. min. sec.">
		<cfset sql="#sql#
			,#LAT_DEG#
			,#LAT_MIN#
			,#LAT_SEC#
			,'#LAT_DIR#'
			,#LONG_DEG#
			,#LONG_MIN#
			,#LONG_SEC#
			,'#LONG_DIR#'">
		<cfelseif #ORIG_LAT_LONG_UNITS# is "degrees dec. minutes">
		<cfset sql="#sql#
			,#dmLAT_DEG#
			,#DEC_LAT_MIN#
			,'#dmLAT_DIR#'
			,#dmLONG_DEG#
			,#DEC_LONG_MIN#
			,'#dmLONG_DIR#'">
		<cfelseif #ORIG_LAT_LONG_UNITS# is "decimal degrees">
		<cfset sql="#sql#
			,#DEC_LAT#
			,#DEC_LONG#">
		<cfelseif #ORIG_LAT_LONG_UNITS# is "UTM">
			 <cfset sql="#sql#
			 	,'#UTM_ZONE#'
			 	,#UTM_EW#
			 	,#UTM_NS#">
		</cfif>
		<cfset sql="#sql# )">
<cftransaction>
	<cfquery name="newLatLong" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		#preservesinglequotes(sql)#
	</cfquery>
	<cfif len(#errorPoly#) gt 0>
	<cfquery name="addPoly" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update lat_long set error_polygon = <cfqueryparam cfsqltype="cf_sql_clob" value="#errorPoly#"> where lat_long_id = #getLATLONGID.latlongid#
	</cfquery>
	</cfif>
</cftransaction>
	<cfquery name="getAcc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select lat_long_id from lat_long where locality_id=#locality_id#
		and accepted_lat_long_fg = 1
	</cfquery>
<cfif #getAcc.recordcount# is 1>
	<cflocation url="editLocality.cfm?locality_id=#locality_id#" addtoken="no">
<cfelseif #getAcc.recordcount# gt 1>
	<div class="error">
	There are more than one accepted lat_longs for this locality. Please change all but one
	of them to unaccepted. A better fix is coming soon.

	<br><a href="editLocality.cfm?locality_id=#locality_id#">continue</a>
	</div>
	<cfabort>
<cfelseif #getAcc.recordcount# lt 1>
	<div class="error">
	There are no accepted lat_longs for this locality. Is that what you meant to do?
	<br><a href="editLocality.cfm?locality_id=#locality_id#">continue</a>
	</div>
		<cfabort>
</cfif>
	<cflocation url="editLocality.cfm?locality_id=#locality_id#" addtoken="no">
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif #Action# is "deleteLatLong">
	<cfoutput>
		<cfif #ACCEPTED_LAT_LONG_FG# is "1">
			<div class="error">
			I can't delete the accepted lat/long!
			<cfabort>
			</div>
		</cfif>
		<cfquery name="killLatLong" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from lat_long where lat_long_id = #lat_long_id#
		</cfquery>

	<cflocation url="editLocality.cfm?locality_id=#locality_id#" addtoken="no">
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif #Action# is "copypolygon">
	<cfoutput>
		<cfquery name="getPoly" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select error_polygon from lat_long where locality_id = <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#copyPolyFrom#"> and accepted_lat_long_fg = 1
		</cfquery>
		<cftransaction>
			<cfquery name="disableLLTrig" datasource="uam_god">
				alter trigger TR_LATLONG_ACCEPTED_BIUPA disable
			</cfquery>
			<cfquery name="copyPoly" datasource="uam_god">
				update lat_long set error_polygon = <cfqueryparam CFSQLTYPE="CF_SQL_CLOB" value="#getPoly.ERROR_POLYGON#"> WHERE LAT_LONG_ID = <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#LAT_LONG_ID#">
			</cfquery>
			<cfquery name="disableLLTrig" datasource="uam_god">
				alter trigger TR_LATLONG_ACCEPTED_BIUPA enable
			</cfquery>
		</cftransaction>
	<cflocation url="editLocality.cfm?locality_id=#locality_id#" addtoken="no">
	</cfoutput>
</cfif>
