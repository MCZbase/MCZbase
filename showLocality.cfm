<cfinclude template="includes/_header.cfm">
<script src="/lib/misc/sorttable.js"></script>
<script>
	function removeDetail(){
		$("#bgDiv").remove();
		$("#customDiv").remove();
	}
	function expandGeog(geogID){
		jQuery.getJSON("/component/functions.cfc",
			{
				method : "getGeogDetails",
				geogID : geogID,
				returnformat : "json",
				queryformat : 'column'
			},
			function (r) {
				if (r.ROWCOUNT){
 					var d='<div align="right" class="infoLink" onclick="removeDetail()">close</div>';
 					d+="Detail for geography <strong>" + r.DATA.HIGHER_GEOG[0] + '</strong>';
 					if(r.DATA.CONTINENT_OCEAN[0]){
 						 d+='<br>Continent or Ocean: <strong>' + r.DATA.CONTINENT_OCEAN[0] + '</strong>';
 					}
 					if(r.DATA.COUNTRY[0]){
 						d+='<br>Country: <strong>' + r.DATA.COUNTRY[0] + '</strong>';
 					}
 					if(r.DATA.STATE_PROV[0]){
 						d+='<br>State or Province: <strong>' + r.DATA.STATE_PROV[0] + '</strong>';
 					}
 					if(r.DATA.COUNTY[0]){
 						d+='<br>County: <strong>' + r.DATA.COUNTY[0] + '</strong>';
 					}
 					if(r.DATA.QUAD[0]){
 						d+='<br>USGS Quad: <strong>' + r.DATA.QUAD[0] + '</strong>';
 					}
 					if(r.DATA.FEATURE[0]){
 						d+='<br>Land Feature: <strong>' + r.DATA.FEATURE[0] + '</strong>';
 					}
					if(r.DATA.WATER_FEATURE[0]){
						d+='<br>Water Feature: <strong>' + r.DATA.WATER_FEATURE[0] + '</strong>';
					}
 					if(r.DATA.ISLAND_GROUP[0]){
 						d+='<br>Island Group: <strong>' + r.DATA.ISLAND_GROUP[0] + '</strong>';
 					}
 					if(r.DATA.ISLAND[0]){
 						d+='<br>Island: <strong>' + r.DATA.ISLAND[0] + '</strong>';
 					}
 					if(r.DATA.SEA[0]){
 						d+='<br>Sea: <strong>' + r.DATA.SEA[0] + '</strong>';
 					}
 					if(r.DATA.SOURCE_AUTHORITY[0]){
 						d+='<br>Source: <strong>' + r.DATA.SOURCE_AUTHORITY[0] + '</strong>';
 					}
					$('<div />').addClass('bgDiv').attr("id","bgDiv").bind("click",removeDetail).appendTo('body').show();
		            $('<div />').html(d).attr("id","customDiv").addClass('infoPop').appendTo('body');
					viewport.init("#customDiv");
					viewport.init("#bgDiv");
				} else {
					alert('An error occurred. \n' + r);
				}
			}
		);
	}

	function expand(variable, value){
		$('<div />').addClass('bgDiv').attr("id","bgDiv").bind("click",removeDetail).appendTo('body').show();
		$('<div />').attr("id","customDiv").addClass('infoPop').appendTo('body');
		var ptl="/includes/forms/locationDetail.cfm?" + variable + "=" + value;
		jQuery("#customDiv").load(ptl,{},function(){
			viewport.init("#customDiv");
			viewport.init("#bgDiv");
		});
	}
</script>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "nothing">
<cfoutput>
	<cfset title="Explore Localities">
	<cfset showLocality=1>
	<cfset showEvent=1>
    <div class="basic_search_box" style="width: 52em;">
	<h2 class="wikilink">Search Places
	<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
    <img src="/images/info_i_2.gif" onClick="getMCZDocs('Find Locality')" class="likeLink" alt="[ help ]" style="vertical-align:top;">
    </cfif>
    </h2>
    <form name="getCol" method="post" action="showLocality.cfm" style="margin-top: 0">
		<input type="hidden" name="action" value="srch">
		<cfinclude template="/includes/frmFindLocation_guts.cfm">
    </form>
    </div>
</cfoutput>
</cfif>

<!---------------------------------------------------------------------------------------------------->
<cfif action is "srch">
	<cfoutput>
		<cf_findLocality>

		<cfquery name="localityResults" dbtype="query">
			select
				collecting_event_id,
				higher_geog,
				geog_auth_rec_id,
				spec_locality,
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
  				collcountlocality
			from localityResults
			order by higher_geog, spec_locality
		</cfquery>
		<a href="showLocality.cfm">Search Again</a>
		<table border id="t" class="sortable">
			<tr>
				<th>Geography</th>
				<th>Locality</th>
				<th>Event</th>
			</tr>
			<cfloop query="localityResults">
		        <cfif (verbatim_date is began_date) AND (verbatim_date is ended_date)>
					<cfset thisDate = began_date>
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
		        <tr>
					<td>
						[<span class="infoLink" onclick="expand('geog_auth_rec_id', #geog_auth_rec_id#)">&nbsp;details&nbsp;</span>]
						[<a class="infoLink" href="/SpecimenResults.cfm?geog_auth_rec_id=#geog_auth_rec_id#">&nbsp;specimens&nbsp;</a>]
						<a href="showLocality.cfm?action=srch&geog_auth_rec_id=#geog_auth_rec_id#">#higher_geog#</a>
					</td>
					<td>
						<cfif len(locality_id) gt 0>
							[<span class="infoLink" onclick="expand('locality_id', #locality_id#)">&nbsp;details&nbsp;</span>]
							[<a class="infoLink" href="/SpecimenResults.cfm?locality_id=#locality_id#">&nbsp;specimens&nbsp;</a>#collcountlocality#]
							<cfif len(spec_locality) gt 0>
								<a href="showLocality.cfm?action=srch&locality_id=#locality_id#">#spec_locality#</a>
							<cfelse>
								[null]
							</cfif>
							<cfif len(geolAtts) gt 0>[#geolAtts#]</cfif>
							<cfif len(#LatitudeString#) gt 0>
								<cfquery name="isMaskCoord" datasource="uam_god">
									select MCZBASE.IS_MASK_LOC_COORD(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#localityResults.locality_id#">) as mask_loc_coord from dual
								</cfquery>
								<cfif isMaskCoord.mask_loc_coord EQ 0>
									<br>#LatitudeString#/#LongitudeString#
								<cfelse>
									<br>[coordinates redacted]
								</cfif>
							<cfelse>
								<br>#nogeorefbecause#
							</cfif>
						<cfelse>
							[no localities]
						</cfif>
					<td>
						<cfif len(collecting_event_id) gt 0>
							<span class="infoLink" onclick="expand('collecting_event_id', #collecting_event_id#)">[&nbsp;details&nbsp;]</span>
							<a class="infoLink" href="/SpecimenResults.cfm?collecting_event_id=#collecting_event_id#">[&nbsp;specimens&nbsp;]</a>
							<a href="showLocality.cfm?action=srch&collecting_event_id=#collecting_event_id#">
							<cfif len(verbatim_locality) gt 0>
								#verbatim_locality#
							<cfelse>
								[null]
							</cfif>
							</a>
							<br>#thisDate#; #collecting_source#
							<cfif len(collecting_method) gt 0>
								(#collecting_method#)
							</cfif>
						<cfelse>
							[no events]
						</cfif>
					</td>
				</tr>
			</cfloop>
		</table>
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfinclude template="includes/_footer.cfm">
