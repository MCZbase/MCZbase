<cfinclude template="/includes/_header.cfm">
<cfif not isdefined("session.sdmapclass") or len(session.sdmapclass) is 0>
	<cfset session.sdmapclass='tinymap'>
</cfif>
<cfoutput>
	<cfhtmlhead text='<script src="#Application.protocol#://maps.googleapis.com/maps/api/js?key=#application.gmap_api_key#&libraries=geometry" type="text/javascript"></script>'>
</cfoutput>

<cftry>
	<script>
		/*map customization and polygon functionality commented  out for now. This will be useful as we implement more features -bkh*/
		jQuery(document).ready(function() {
			/*$( "#dialog" ).dialog({
				autoOpen: false,
				width: "50%"
			});
			$( ".mapdialog" ).click(function() {
				$( "#dialog" ).dialog( "open" );
			});*/
			mapsYo();
		});
		/*function saveSDMap(){
			$("div[id^='mapdiv_']").each(function(e){
				$(this).removeClass().addClass($("#sdetmapsize").val());
			});
			jQuery.getJSON("/component/functions.cfc",
				{
					method : "changeUserPreference",
					pref : "sdmapclass",
					val : $("#sdetmapsize").val(),
					returnformat : "json",
					queryformat : 'column'
				}
			);
			$('#dialog').dialog('close');
			mapsYo();
		}*/
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
				    scaleControl: false,
					fullscreenControl: false,
					zoomControl: false
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
				$.get( "/localities/component/georefUtilities.cfc?returnformat=plain&method=getGeogWKT&locality_id=" + locid, function( wkt ) {
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

<cfif isdefined("collection_object_id")>
	<cfset checkSql(collection_object_id)>
	<cfoutput>
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select GUID 
			from <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> 
			where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
		</cfquery>
		<cfheader statuscode="301" statustext="Moved permanently">
		<cfheader name="Location" value="/guid/#c.guid#">
		<cfabort>
	</cfoutput>
</cfif>
<cfif isdefined("guid")>
	<cfif cgi.script_name contains "/SpecimenDetail.cfm">
		<cfheader statuscode="301" statustext="Moved permanently">
		<cfheader name="Location" value="/guid/#guid#">
		<cfabort>
	</cfif>
	<cfset checkSql(guid)>
	<cfif guid contains ":">
		<cfoutput>
			<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select collection_object_id 
				from <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> 
				WHERE
					upper(guid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(guid)#">
			</cfquery>
		</cfoutput>
	<cfelseif guid contains " ">
		<cfset spos=find(" ",reverse(guid))>
		<cfset cc=left(guid,len(guid)-spos)>
		<cfset cn=right(guid,spos)>
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select collection_object_id from
				cataloged_item,
				collection
			WHERE
				cataloged_item.collection_id = collection.collection_id AND
				cat_num = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#cn#"> AND
				lower(collection.collection) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lcase(cc)#">
		</cfquery>
	</cfif>
	<cfif isdefined("c.collection_object_id") and len(c.collection_object_id) gt 0>
		<cfset collection_object_id=c.collection_object_id>
	<cfelse>
		<cfinclude template="/errors/404.cfm">
		<cfabort>
	</cfif>
<cfelse>
	<cfinclude template="/errors/404.cfm">
	<cfabort>
</cfif>
<cfset detSelect = "
	SELECT DISTINCT
		#session.flatTableName#.collection,
		#session.flatTableName#.collection_id,
		web_link,
		web_link_text,
		#session.flatTableName#.cat_num,
		#session.flatTableName#.collection_object_id as collection_object_id,
		#session.flatTableName#.scientific_name,
		#session.flatTableName#.collecting_event_id,
		#session.flatTableName#.locality_id,
		#session.flatTableName#.higher_geog,
		#session.flatTableName#.spec_locality,
		#session.flatTableName#.verbatim_date,
		#session.flatTableName#.BEGAN_DATE,
		#session.flatTableName#.ended_date,
		#session.flatTableName#.cited_as,
		#session.flatTableName#.typestatuswords,
		MCZBASE.concattypestatus_plain_s(#session.flatTableName#.collection_object_id,1,1,0) as typestatusplain,
		#session.flatTableName#.toptypestatuskind,
		concatparts_ct(#session.flatTableName#.collection_object_id) as partString,
		concatEncumbrances(#session.flatTableName#.collection_object_id) as encumbrance_action,
		#session.flatTableName#.dec_lat,
		#session.flatTableName#.dec_long,
		#session.flatTableName#.COORDINATEUNCERTAINTYINMETERS">
<cfif len(#session.CustomOtherIdentifier#) gt 0>
	<cfset detSelect = "#detSelect#
	,concatSingleOtherId(#session.flatTableName#.collection_object_id,'#session.CustomOtherIdentifier#') as	CustomID">
</cfif>
<cfset detSelect = "#detSelect#
	FROM
		#session.flatTableName#,
		collection
	where
		#session.flatTableName#.collection_id = collection.collection_id AND
		#session.flatTableName#.collection_object_id = #collection_object_id#
	ORDER BY
		cat_num">
<cfset checkSql(detSelect)>
<cfquery name="detail" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	#preservesinglequotes(detSelect)#
</cfquery>
<cfoutput>
	<cfif detail.recordcount lt 1>
		<div class="error">
			Oops! No specimen was found for that URL.
			<ul>
				<li>Did you mis-type the URL?</li>
				<li>
					Did you click a link? <a href="/info/bugs.cfm">Tell us about it</a>.
				</li>
				<li>
					You may need to log out or change your preferences to access all public data.
				</li>
			</ul>
		</div>
	</cfif>
	<cfset title="#detail.collection# #detail.cat_num#: #detail.scientific_name#">
	<cfset metaDesc="#detail.collection# #detail.cat_num# (#guid#); #detail.scientific_name#; #detail.higher_geog#; #detail.spec_locality#">
	<cf_customizeHeader collection_id=#detail.collection_id#>
</cfoutput>


<cfoutput query="detail" group="cat_num">
 <cfset typeName = typestatuswords>
 <cfif toptypestatuskind eq 'Primary' >
   <!--- Highlight as a primary type --->
   <cfset twotypes = '#replace(typestatusplain,"|","<br>","all")#'>
   <div class="primaryCont" style="margin-top:-1em;">
       <div class="primaryType">
       <cfset typeName = '<span style="font-weight:bold;background-color: white;border: 1px solid ##333;padding: 5px;width:auto;display:inline-block;">#twotypes# </span>'>
 <cfelseif toptypestatuskind eq 'Secondary' >
   <!--- Highlight as a secondary type --->
   <cfset  twotypes= '#replace(typestatusplain,"|","<br>","all")#'>
   <div class="secondaryCont" style="margin-top: -1em;">
      <div class="secondaryType">
      <cfset typeName = '<span style="font-weight:bold;background-color: white;border: 1px solid ##333;padding: 5px;width:auto;display:inline-block;">#twotypes#  </span>'>
 <cfelse>
   <!--- voucher or not a cited specimen --->
   <div class="defaultCont" style="margin-top: -1em;">
      <div class="defaultType">
 </cfif>
   <ul class="headercol1">
    <li>#collection#&nbsp;#cat_num#
      <cfif len(web_link) gt 0>
        <a href="#web_link#" target="_blank"><img src="/images/linkOut.gif" border="0" alt="#web_link_text#"></a>
      </cfif>
      <cfif len(session.CustomOtherIdentifier) gt 0>
        #session.CustomOtherIdentifier#: #CustomID#
      </cfif>
    </li>
    <li class="sciname">
        <cfset sciname = '#replace(Scientific_Name," or ","<span style='font-style:normal;'>&nbsp;or&nbsp;</span>")#'>
    #sciname#  <!---&nbsp; &nbsp;     <cfif isDefined("cited_as") and len(cited_as) gt 0>
        <span style="font-size: 15px;">#typeName#</span>
      </cfif>--->
    </li>
	<cfif encumbrance_action does not contain "mask parts" OR
					(isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user"))>
        <!--- omit part string for mask parts encumberance --->
    	<li class="partstring">#partString# </li>
	</cfif>
    <li>
    <ul class="return_links">
              <li>
                <cfif len(session.username) gt 0>
                  <cfquery name="existingAnnotations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
                                      select count(*) cnt from annotations
                                      where collection_object_id = #collection_object_id#
                                  </cfquery>
                  <span class="likeLink" onclick="openAnnotation('collection_object_id=#collection_object_id#')">Report Bad Data</span>
                  <cfif existingAnnotations.cnt gt 0>
                    <br>
                    (#existingAnnotations.cnt# existing)
                  </cfif>
                </li>
                  <cfelse>
               <!---   <a href="/login.cfm">Login or Create Account</a>--->

                 </li>
                </cfif>

        <li>
      <cfif isdefined("session.mapURL") and len(session.mapURL) gt 0>
        <a href="/SpecimenResults.cfm?#session.mapURL#">Return to results</a>
      </cfif>
      </li>
      </ul>
      </li>
  </ul>
  <ul class="headercol2">
    <li>
      <cfif isDefined("cited_as") and len(cited_as) gt 0>
       &nbsp;&nbsp; #typeName#
      </cfif>
    </li>
  </ul>
  <ul class="headercol3">
    <li>
		<cfif len(dec_lat) gt 0 and len(dec_long) gt 0>
			<cfset coordinates="#dec_lat#,#dec_long#">
			<input type="hidden" id="coordinates_#locality_id#" value="#coordinates#">
			<input type="hidden" id="error_#locality_id#" value="#COORDINATEUNCERTAINTYINMETERS#">
			<div id="mapdiv_#locality_id#" class="tinymap"></div>
			<!---span class="infoLink mapdialog">map key/tools</div--->
		</cfif>
    </li>
  </ul>
  <ul class="headercol4">
    <li>#spec_locality#</li>
    <li>#higher_geog#</li>
    <cfif encumbrance_action does not contain "year collected" OR
					(isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user"))>
      <cfif (verbatim_date is began_date) AND (verbatim_date is ended_date)>
        <cfset thisDate = verbatim_date>
        <cfelseif (
							(verbatim_date is not began_date) OR
					 		(verbatim_date is not ended_date)
						)
						AND
						began_date is ended_date>
        <cfset thisDate = "#verbatim_date# (#began_date#)">
        <cfelse>
        <cfset thisDate = "#verbatim_date# (#began_date# - #ended_date#)">
      </cfif>
      <cfelse>
      <cfif began_date is ended_date>
        <cfset thisDate = replace(began_date,left(began_date,4),"8888")>
        <cfelse>
        <cfset thisDate = '#replace(began_date,left(began_date,4),"8888")#-&nbsp;#replace(ended_date,left(ended_date,4),"8888")#'>
      </cfif>
    </cfif>
    <li> #thisDate#</li>
    <li>
      <cfif (len(dec_lat) gt 0 and len(dec_long) gt 0)>
        <cfif encumbrance_action does not contain "coordinates" OR
						(isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user"))>
		<a href="/bnhmMaps/bnhmMapData.cfm?collection_object_id=#collection_object_id#" target="_blank" class="external" style="display: block;">BerkeleyMapper</a>
		<span class="uncertaintyDisplay">
			Use ctrl+scroll wheel on your mouse or double click<br> to zoom in on the map to see coordinate uncertainty.
		</span>
		<div class="tooltipMap"><img src="/images/info.gif" border="0" class="likeLink">
		  <span class="tooltiptextMap">Use the BerkeleyMapper link to display a map with the georeferenced coordinates and the error radius. See Display on left of pages to toggle between Point Marker showing the radius and â€œMarkerClusterâ€� showing the specimen data when clicked.</span>
		</div>
        </cfif>
      </cfif>
    </li>
  </ul>

    </div><!---ends primaryType or secondaryType or defaultType--->
    </div><!---end primaryCont or secondaryCont or defaultCont--->
	<!--- NOTE: List of files invoked with loadEditApp, search on filename.cfm won't find the loadEditApp(filename) references --->
	<!--- Do not remove or rename these files until loadEditApp references have also been addressed: 
				editIdentification.cfm referenced with loadEditApp
				addAccn.cfm referenced with loadEditApp
				changeCollEvent.cfm referenced with loadEditApp
				specLocality.cfm referenced with loadEditApp
				editColls.cfm referenced with loadEditApp
				editRelationship.cfm referenced with loadEditApp
				editParts.cfm referenced with loadEditApp
				findContainer.cfm referenced with loadEditApp
				editBiolIndiv.cfm referenced with loadEditApp
				editIdentifiers.cfm referenced with loadEditApp
				MediaSearch.cfm referenced with loadEditApp
				Encumbrances.cfm referenced with loadEditApp
				catalog.cfm referenced with loadEditApp
	--->
	<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
		<script language="javascript" type="text/javascript">

			function closeEditApp() {
				$('##bgDiv').remove();
				$('##bgDiv', window.parent.document).remove();
				$('##popDiv').remove();
				$('##popDiv', window.parent.document).remove();

				$('##cDiv').remove();
				$('##cDiv', window.parent.document).remove();

				$('##theFrame').remove();
				$('##theFrame', window.parent.document).remove();
				$("span[id^='BTN_']").each(function(){
					$("##" + this.id).removeClass('activeButton');
					$('##' + this.id, window.parent.document).removeClass('activeButton');
				});
			}
			function loadEditApp(q) {
				closeEditApp();
				var bgDiv = document.createElement('div');
				bgDiv.id = 'bgDiv';
				bgDiv.className = 'bgDiv';
				bgDiv.setAttribute('onclick','closeEditApp()');
				document.body.appendChild(bgDiv);

				var popDiv=document.createElement('div');
				popDiv.id = 'popDiv';
				popDiv.className = 'editAppBox';
				document.body.appendChild(popDiv);
				var links='<ul id="navbar">';
				links+='<li><span onclick="loadEditApp(\'editIdentification\')" class="likeLink" id="BTN_editIdentification">Taxa</span></li>';
				links+='<li><span onclick="loadEditApp(\'addAccn\')" class="likeLink" id="BTN_addAccn">Accn</span></li>';
				links+='<li><span onclick="loadEditApp(\'changeCollEvent\')" class="likeLink" id="BTN_changeCollEvent">PickEvent</span></li>';
				links+='<li><span onclick="loadEditApp(\'specLocality\')" class="likeLink" id="BTN_specLocality">Locality</span></li>';
				links+='<li><span onclick="loadEditApp(\'editColls\')" class="likeLink" id="BTN_editColls">Agents</span></li>';
				links+='<li><span onclick="loadEditApp(\'editRelationship\')" class="likeLink" id="BTN_editRelationship">Relations</span></li>';
				links+='<li><span onclick="loadEditApp(\'editParts\')" class="likeLink" id="BTN_editParts">Parts</span></li>';
				links+='<li><span onclick="loadEditApp(\'findContainer\')" class="likeLink" id="BTN_findContainer">PartLocn</span></li>';
				links+='<li><span onclick="loadEditApp(\'editBiolIndiv\')" class="likeLink" id="BTN_editBiolIndiv">Attributes</span></li>';
				links+='<li><span onclick="loadEditApp(\'editIdentifiers\')" class="likeLink" id="BTN_editIdentifiers">OtherID</span></li>';
				links+='<li><span onclick="loadEditApp(\'MediaSearch\')" class="likeLink" id="BTN_MediaSearch">Media</span></li>';
				links+='<li><span onclick="loadEditApp(\'Encumbrances\')" class="likeLink" id="BTN_Encumbrances">Encumbrance</span></li>';
				links+='<li><span onclick="loadEditApp(\'catalog\')" class="likeLink" id="BTN_catalog">Catalog</span></li>';
				links+="</ul>";

				$("##popDiv").append(links);
				var cDiv=document.createElement('div');
				cDiv.className = 'fancybox-close';
				cDiv.id='cDiv';
				cDiv.setAttribute('onclick','closeEditApp()');
				$("##popDiv").append(cDiv);
				$("##popDiv").append('<img src="/images/loadingAnimation.gif" class="centeredImage">');
				var theFrame = document.createElement('iFrame');
				theFrame.id='theFrame';
				theFrame.className = 'editFrame';
				var ptl="/" + q + ".cfm?collection_object_id=" + #collection_object_id#;
				theFrame.src=ptl;
				//document.body.appendChild(theFrame);
				$("##popDiv").append(theFrame);
				$("span[id^='BTN_']").each(function(){
					$("##" + this.id).removeClass('activeButton');
					$('##' + this.id, window.parent.document).removeClass('activeButton');
				});

				$("##BTN_" + q).addClass('activeButton');
				$('##BTN_' + q, window.parent.document).addClass('activeButton');
			}
		</script>
		 <table width="100%">
		    <tr>
			    <td align="center">
					<form name="incPg" method="post" action="SpecimenDetail.cfm">
				        <input type="hidden" name="collection_object_id" value="#collection_object_id#">
						<input type="hidden" name="suppressHeader" value="true">
						<input type="hidden" name="action" value="nothing">
						<input type="hidden" name="Srch" value="Part">
						<input type="hidden" name="collecting_event_id" value="#detail.collecting_event_id#">
						<cfif isdefined("session.collObjIdList") and len(session.collObjIdList) gt 0>
						    <cfset isPrev = "no">
							<cfset isNext = "no">
							<cfset currPos = 0>

							<cfset lenOfIdList = 0>
							<cfset firstID = collection_object_id>
							<cfset nextID = collection_object_id>
							<cfset prevID = collection_object_id>
							<cfset lastID = collection_object_id>
							<cfset currPos = listfind(session.collObjIdList,collection_object_id)>
							<cfset lenOfIdList = listlen(session.collObjIdList)>
							<cfset firstID = listGetAt(session.collObjIdList,1)>
							<cfif currPos lt lenOfIdList>
								<cfset nextID = listGetAt(session.collObjIdList,currPos + 1)>
							</cfif>
							<cfif currPos gt 1>
								<cfset prevID = listGetAt(session.collObjIdList,currPos - 1)>
							</cfif>
							<cfset lastID = listGetAt(session.collObjIdList,lenOfIdList)>
							<cfif lenOfIdList gt 1>
								<cfif currPos gt 1>
									<cfset isPrev = "yes">
								</cfif>
								<cfif currPos lt lenOfIdList>
									<cfset isNext = "yes">
								</cfif>
							</cfif>
						<cfelse>
							<cfset isNext="">
							<cfset isPrev="">
						</cfif>
						<ul id="navbar">
							<cfif isPrev is "yes">
								<img src="/images/first.gif" class="likeLink" onclick="document.location='/SpecimenDetail.cfm?collection_object_id=#firstID#'" alt="[ First Record ]">
								<img src="/images/previous.gif" class="likeLink"  onclick="document.location='/SpecimenDetail.cfm?collection_object_id=#prevID#'" alt="[ Previous Record ]">
							<cfelse>
								<img src="/images/no_first.gif" alt="[ inactive button ]">
								<img src="/images/no_previous.gif" alt="[ inactive button ]">
							</cfif>
							<li><span onclick="loadEditApp('editIdentification')" class="likeLink" id="BTN_editIdentification">Taxa</span></li>
							<li>
								<span onclick="loadEditApp('addAccn')"	class="likeLink" id="BTN_addAccn">Accn</span>
							</li>
							<li>
								<span onclick="loadEditApp('changeCollEvent')" class="likeLink" id="BTN_changeCollEvent">Pick New Coll Event</span>
							</li>
							<li>
								<span onclick="loadEditApp('specLocality')" class="likeLink" id="BTN_specLocality">Locality</span>
							</li>
							<li>
								<span onclick="loadEditApp('editColls')" class="likeLink" id="BTN_editColls">Agents</span>
							</li>
							<li>
								<span onclick="loadEditApp('editRelationship')" class="likeLink" id="BTN_editRelationship">Relations</span>
							</li>
							<li>
								<span onclick="loadEditApp('editParts')" class="likeLink" id="BTN_editParts">Parts</span>
							</li>
							<li>
								<span onclick="loadEditApp('findContainer')" class="likeLink" id="BTN_findContainer">Part Locn.</span>
							</li>
							<li>
								<span onclick="loadEditApp('editBiolIndiv')" class="likeLink" id="BTN_editBiolIndiv">Attributes</span>
							</li>
							<li>
								<span onclick="loadEditApp('editIdentifiers')"	class="likeLink" id="BTN_editIdentifiers">Other IDs</span>
							</li>
							<li>
								<span onclick="loadEditApp('MediaSearch')"	class="likeLink" id="BTN_MediaSearch">Media</span>
							</li>
							<li>
								<span onclick="loadEditApp('Encumbrances')" class="likeLink" id="BTN_Encumbrances">Encumbrances</span>
							</li>
							<li>
								<span onclick="loadEditApp('catalog')" class="likeLink" id="BTN_catalog">Catalog</span>
							</li>
							<cfif isNext is "yes">
								<img src="/images/next.gif" class="likeLink" onclick="document.location='/SpecimenDetail.cfm?collection_object_id=#nextID#'" alt="[ Next Record ]">
								<img src="/images/last.gif" class="likeLink" onclick="document.location='/SpecimenDetail.cfm?collection_object_id=#lastID#'" alt="[ Last Record ]">
							<cfelse>
								<img src="/images/no_next.gif" alt="[ inactive button ]">
								<img src="/images/no_last.gif" alt="[ inactive button ]">
							</cfif>
						</ul>
	                </form>
		        </td>
		    </tr>
		</table>
	</cfif>
	<cfinclude template="SpecimenDetail_body.cfm">
	<cfinclude template="/includes/_footer.cfm">
	<cfif isdefined("showAnnotation") and showAnnotation is "true">
		<script language="javascript" type="text/javascript">
			openAnnotation('collection_object_id=#collection_object_id#');
		</script>
	</cfif>
</cfoutput>
<cfcatch>
	<cfdump var=#cfcatch#>
	<cf_logError subject="SpecimenDetail error" attributeCollection=#cfcatch#>
	<div class="error">
		Oh no! Part of this page has failed to load!
		<br>This error has been logged. Please <a href="/contact.cfm?ref=specimendetail">contact us</a> with any useful information.
	</div>
</cfcatch>
</cftry>
