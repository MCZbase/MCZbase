<!--- Deprecated.  To be removed.  Replaced with /manage/changeQueryLocality.cfm --->
<cfinclude template="includes/_header.cfm">

<!--------------------------------------------------------------------------------------------------->

<cfquery name="specimenList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	 SELECT
	 	cataloged_item.collection_object_id as collection_object_id,
		cataloged_item.cat_num,
		cataloged_item.collecting_event_id,
		concatSingleOtherId(cataloged_item.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID,
		identification.scientific_name,
		locality.locality_id,
		locality.spec_locality,
		geog_auth_rec.higher_geog,
		collection.institution_acronym,
		collection.collection,
		flat.phylorder,
		flat.family
	FROM
		identification,
		collecting_event,
		locality,
		geog_auth_rec,
		cataloged_item,
		collection,
		flat,
		#table_name# T
	WHERE
		locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
		AND collecting_event.locality_id = locality.locality_id
		AND cataloged_item.collecting_event_id = collecting_event.collecting_event_id
		AND cataloged_item.collection_object_id = flat.collection_object_id
		AND cataloged_item.collection_object_id = identification.collection_object_id
		AND cataloged_item.collection_id = collection.collection_id
		AND identification.accepted_id_fg = 1
		AND cataloged_item.collection_object_id = T.collection_object_id
		<cfif isdefined("filterOrder") and len(#filterOrder#) GT 0>
				and flat.phylorder in ('#filterOrder#')
		</cfif>
		<cfif isdefined("filterFamily") and len(#filterFamily#) GT 0>
				and flat.family in (#listqualify(filterFamily, "'")#)
		</cfif>
	ORDER BY
		phylorder, family
</cfquery>

<cfif #Action# is "nothing">
<cfset title = "Change Locality">

<cfset showLocality=1>
<cfset showEvent=0>
<cfoutput>
 <h3>Find new locality</h3>
<form name="getLoc" method="post" action="bulkLocality.cfm">
	<input type="hidden" name="Action" value="findLocality">
	<input type="hidden" name="table_name" value="#table_name#">
	<cfif isdefined("filterOrder")>
			<input type="hidden" name="filterOrder" value="#filterOrder#">
	</cfif>
	<cfif isdefined("filterFamily")>
		<input type="hidden" name="filterFamily" value="#filterFamily#">
	</cfif>
	<cfset showSpecimenCounts = false>
	<cfinclude template="/includes/frmFindLocation_guts.cfm">
</form>
</cfoutput>
</cfif>

<cfif #action# is "findLocality">
<cfoutput>
	<cf_findLocality>
	<cfquery name="localityResults" dbtype="query">
		select
			locality_id,
            geog_auth_rec_id,
            spec_locality,
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
			orig_elev_units
		from localityResults
		group by
            locality_id,
            geog_auth_rec_id,
            spec_locality,
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
			orig_elev_units

	</cfquery>

	<table border>
		<tr>
	      	<td><b>Geog ID</b></td>
	      	<td>&nbsp;</td>
	     	<td><b>Locality ID</b></td>
	      	<td><b>Spec Locality</b></td>
		   	<td><b>Geog</b></td>
	    </tr>
	<cfset i = 1>
	<cfloop query="localityResults">
		<tr>
			<td> 
				<a href="/localities/viewHigherGeography.cfm?geog_auth_rec_id=#geog_auth_rec_id#">#geog_auth_rec_id#</a>
			</td>
			<td>
				<a href="/localities/viewLocality.cfm?locality_id=#locality_id#">#locality_id#</a>
			</td>
			<td>
			<form name="coll#i#" method="post" action="bulkLocality.cfm">
				<input type="hidden" name="table_name" value="#table_name#">
				<input type="hidden" name="newlocality_id" value="#locality_id#">
				<input type="hidden" name="action" value="updateLocality">
				<cfif isdefined("filterOrder")>
					<input type="hidden" name="filterOrder" value="#filterOrder#">
				</cfif>
				<cfif isdefined("filterFamily")>
					<input type="hidden" name="filterFamily" value="#filterFamily#">
				</cfif>
				<input type="submit"
					 	value="Change ALL listed specimens to this Locality"
						class="savBtn"
   						onmouseover="this.className='savBtn btnhov'"
						onmouseout="this.className='savBtn'">
			</form>
			</td>
			<td>#spec_locality#</td>
			<td>#higher_geog#</td>
		</tr>
	<cfset i=#i#+1>
	</cfloop>
		</cfoutput>
	</table>
</cfif>

<cfquery name="orders" dbtype="query">
	select distinct phylorder from specimenList
</cfquery>

<cfquery name="families" dbtype="query">
	select distinct family from specimenList
</cfquery>

<br><b>Specimens Being Changed:</b>
<cfoutput>
		<table width="95%">
		<form name="filterResults">
		<input type="hidden" name="table_name" value="#table_name#">
		<input type="hidden" name="action" value="nothing" id="action">

			<tr>
				<td width="33%">Order:
				<select name="filterOrder" style="width:150px" class="chosen-select-deselect">
					<option></option>
					<cfloop query="orders">
						<option <cfif isdefined("filterOrder") and #phylorder# EQ #filterOrder#>selected</cfif>>#orders.phylorder#</option>
					</cfloop>
				</td>
				<td width="33%"><select data-placeholder="Choose Families..." name="filterFamily" class ="chosen-select" multiple tabindex="4" style="width:500px;">
					<option value=""></option>
					<cfloop query="families">
						<option value="#family#"<cfif isdefined("filterFamily") and listfind(filterFamily,family)>selected="selected"</cfif>>#family#</option>
					</cfloop>
				</td>

				<td align="right"><input type="submit" value="Filter Specimens" onClick='document.getElementById("action").value="nothing";document.forms["filterResults"].submit();'></input></td>
			</tr>
		</table>
		</form>
</cfoutput>
<table width="95%" border="1">
<tr>
	<td><strong>Catalog Number</strong></td>
	<cfif len(#session.CustomOtherIdentifier#) GT 0>
	<td>
		<cfoutput>
			<strong>#session.CustomOtherIdentifier#</strong>
		</cfoutput>
	</td>
	</cfif>
	<td>Order</td>
	<td>Family</td>
	<td><strong>Accepted Scientific Name</strong></td>
	<td><strong>Locality ID</strong></td>
	<td><strong>Spec Locality</strong></td>
	<td><strong>higher_geog</strong></td>
</tr>
 <cfoutput query="specimenList" group="collection_object_id">
    <tr>
	  <td>
	  	<a href="/SpecimenDetail.cfm?collection_object_id=#collection_object_id#">
	  #collection#&nbsp;#cat_num#
	  	</a>
	  </td>
	<cfif len(#session.CustomOtherIdentifier#) GT 0>
	<td>
		#CustomID#&nbsp;
	</td>
	</cfif>
	<td>#phylorder#</td>
	<td>#family#</td>
	<td><i>#Scientific_Name#</i></td>
	<td>#locality_id#</td>
	<td>#spec_locality#</td>
	<td>#higher_geog#</td>
</tr>
</cfoutput>
</table>
<!----------------------------------------------------------------------------------->
<cfif action is "updateLocality">

		<cfquery name="collEvents" dbtype="query">
			select distinct collecting_event_id from specimenList
		</cfquery>
		<cfset collEventIdsList = valuelist(collEvents.collecting_event_id)>

		<cfquery name="collObjects" dbtype="query">
			select distinct collection_object_id from specimenList
		</cfquery>
		<cfset collObjIdsList = valuelist(collObjects.collection_object_id)>
<cfoutput>
		<cftransaction>
		<cfloop list="#collEventIdsList#" index = "CEID">

			<cfquery name="checkCollEvent" datasource="uam_god">
				select collection_object_id from cataloged_item where  collecting_event_id = #CEID# and collection_object_id not in (#collObjIdsList#)
			</cfquery>

			<cfif checkCollEvent.RecordCount is 0>
				<cfquery name="updateCollEvent" datasource="uam_god">
					update collecting_event set locality_id = #newLocality_Id# where collecting_event_id = #CEID#
				</cfquery>
			<cfelse>
				<cfquery name="getID" datasource = "uam_god">
					select sq_collecting_event_id.nextval as newID from dual
				</cfquery>
				<cfset newCollEventID = getId.newId>
				<cfquery name="cloneCE" datasource="uam_god">
					insert into collecting_event(COLLECTING_EVENT_ID,LOCALITY_ID,DATE_BEGAN_DATE,DATE_ENDED_DATE,VERBATIM_DATE,VERBATIM_LOCALITY,COLL_EVENT_REMARKS,VALID_DISTRIBUTION_FG,COLLECTING_SOURCE,COLLECTING_METHOD,HABITAT_DESC,DATE_DETERMINED_BY_AGENT_ID,FISH_FIELD_NUMBER,BEGAN_DATE,ENDED_DATE,COLLECTING_TIME,VERBATIMCOORDINATES,VERBATIMLATITUDE,VERBATIMLONGITUDE,VERBATIMCOORDINATESYSTEM,VERBATIMSRS, STARTDAYOFYEAR,ENDDAYOFYEAR)
					select #newCollEventID#, #newLocality_ID#,DATE_BEGAN_DATE,DATE_ENDED_DATE,VERBATIM_DATE,VERBATIM_LOCALITY,COLL_EVENT_REMARKS,VALID_DISTRIBUTION_FG,COLLECTING_SOURCE,COLLECTING_METHOD,HABITAT_DESC,DATE_DETERMINED_BY_AGENT_ID,FISH_FIELD_NUMBER,BEGAN_DATE,ENDED_DATE,COLLECTING_TIME,VERBATIMCOORDINATES,VERBATIMLATITUDE,VERBATIMLONGITUDE,VERBATIMCOORDINATESYSTEM,VERBATIMSRS,STARTDAYOFYEAR,ENDDAYOFYEAR
						from collecting_event where collecting_event_id = #CEID#
				</cfquery>
				<cfquery name="updateSpecs" datasource="uam_god">
					update cataloged_item set collecting_event_id = #newCollEventID# where collection_object_id in
						(#collObjIdsList#)
						and collecting_event_id = #CEID#
				</cfquery>
			</cfif>
		</cfloop>
		</cftransaction>
		<cfset returnURL = "bulkLocality.cfm?table_name=#table_name#">
		<cfif isdefined("filterOrder")>
			<cfset returnURL = returnURL & "&fiterOrder=#filterOrder#">
		</cfif>
		<cfif isdefined("filterFamily")>
			<cfset returnURL = returnURL & "&filterFamily=#filterFamily#">
		</cfif>
	<cflocation url=#returnURL#>
</cfoutput>
</cfif>
			<link rel="stylesheet" href="/includes/css/chosen.css">
			<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.4/jquery.js" type="text/javascript"></script>
			<script src="/includes/jquery/chosen.jquery.js" type="text/javascript"></script>
			<script type="text/javascript" language="javascript">
				var config = {
				  '.chosen-select'           : {},
				  '.chosen-select-deselect'  : { allow_single_deselect: true },
				  '.chosen-select-no-single' : { disable_search_threshold: 10 },
				  '.chosen-select-no-results': { no_results_text: 'Oops, nothing found!' },
				  '.chosen-select-rtl'       : { rtl: true },
				  '.chosen-select-width'     : { width: '95%' }
				}
				for (var selector in config) {
				  $(selector).chosen(config[selector]);
				}
			</script>
<cfinclude template="includes/_footer.cfm">
