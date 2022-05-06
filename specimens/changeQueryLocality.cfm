<cfset pageTitle = "Change Localities for Search Result">
<cfinclude template="/shared/_header.cfm">

<cfif not isDefined("result_id") OR len(result_id) EQ 0>
	<cfthrow message = "No result_id provided for result set on which to change localities.">
</cfif>
<cfif not isDefined("action") OR len(action) EQ 0>
	<cfset action="entryPoint">
</cfif>

<!--- For all actions, obtain data from the list of specimens specified by the result_id --->
<cfquery name="specimenList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	 SELECT distinct
	 	cataloged_item.collection_object_id as collection_object_id,
		cataloged_item.cat_num,
		cataloged_item.collecting_event_id,
		concatSingleOtherId(cataloged_item.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID,
		flat.scientific_name,
		locality.locality_id,
		locality.spec_locality,
		geog_auth_rec.higher_geog,
		collection.institution_acronym,
		collection.collection,
		flat.phylorder,
		flat.family
	FROM
		user_search_table
		left join cataloged_item on user_search_table.collection_object_id = cataloged_item.collection_object_id
		left join collection on  cataloged_item.collection_id = collection.collection_id
		left join collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id
		left join locality on collecting_event.locality_id = locality.locality_id
		left join geog_auth_rec on  locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
		left join flat on cataloged_item.collection_object_id = flat.collection_object_id
	WHERE
		result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
		<cfif isdefined("filterOrder") and len(#filterOrder#) GT 0>
			and flat.phylorder in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#filterOrder#" list="true">)
		</cfif>
		<cfif isdefined("filterFamily") and len(#filterFamily#) GT 0>
			and flat.family in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#listqualify(filterFamily, '')#" list="true">)
		</cfif>
	ORDER BY
		phylorder, family
</cfquery>
<cfif specimenList.recordcount EQ 0>
	<cfthrow message = "No records found on which to change localities with record_id #encodeForHtml(result_id)# in user_search_table.">
</cfif>

<!--------------------------------------------------------------------------------------------------->

<cfswitch expression="#action#">
	<cfcase value="entryPoint">
		<cfset title = "Change Locality">
		<cfset showLocality=1>
		<cfset showEvent=0>
		<cfoutput>
			<div class="container-lg">
				<h1 class="h3">Find new locality for specimens [in #encodeForHtml(result_id)#]</h1>
				<form name="getLoc" method="post" action="/specimens/changeQueryLocality.cfm">
					<input type="hidden" name="Action" value="findLocality">
					<input type="hidden" name="result_id" value="#result_id#">
					<cfif isdefined("filterOrder")>
						<input type="hidden" name="filterOrder" value="#filterOrder#">
					</cfif>
					<cfif isdefined("filterFamily")>
						<input type="hidden" name="filterFamily" value="#filterFamily#">
					</cfif>
					<cfset showSpecimenCounts = false>
					<cfinclude template="/localities/searchLocationForm.cfm">
				</form>
			</div>
		</cfoutput>
	</cfcase>

	<cfcase value ="updateLocality">
	<cfoutput>
	<div class="container">
		<h2 class="h2">Changed locality for specimens [in #encodeForHtml(result_id)#]</h2>
	</div>
	</cfoutput>
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
		<cfset returnURL = "/specimens/changeQueryLocality.cfm?result_id=#result_id#">
		<cfif isdefined("filterOrder")>
			<cfset returnURL = returnURL & "&fiterOrder=#filterOrder#">
		</cfif>
		<cfif isdefined("filterFamily")>
			<cfset returnURL = returnURL & "&filterFamily=#filterFamily#">
		</cfif>
		<cflocation url=#returnURL#>
		</cfoutput>
	</cfcase>

	<cfcase value="findLocality">
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
		<div class="container">
			<div class="row">
			<table class="table">
				<thead class="thead-light">
					<tr>
						<th>Geog ID</th>
						<th>&nbsp;</th>
						<th>Locality ID</th>
						<th>Spec Locality</th>
						<th>Geog</th>
					</tr>
				</thead>
				<tbody>
					<cfset i = 1>
					<cfloop query="localityResults">
				<tr>
					<td> <a href="Locality.cfm?Action=editGeog&geog_auth_rec_id=#geog_auth_rec_id#">#geog_auth_rec_id#</a></td>
					<td><a href="editLocality.cfm?locality_id=#locality_id#">#locality_id#</a></td>
					<td>
					<form name="coll#i#" method="post" action="/specimens/changeQueryLocality.cfm">
						<input type="hidden" name="result_id" value="#result_id#">
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
				</tbody>
			</table>
			</div>
		</div>
	</cfcase>
</cfswitch>

<!--- Display list of specimens to be affected --->

<cfquery name="orders" dbtype="query">
	select distinct phylorder from specimenList
</cfquery>

<cfquery name="families" dbtype="query">
	select distinct family from specimenList
</cfquery>

<cfoutput>
	<div class="container">
		<div class="row">
			<h2 class="h3">Cataloged Items Being Changed: #specimenList.recordcount#</h2>
			<form name="filterResults">
				<input type="hidden" name="result_id" value="#result_id#">
				<input type="hidden" name="action" value="nothing" id="action">
				<div class="col-12 col-md-5">
					<label for="filter_order" class="data-entry-label">Order:</label>
					<select id="filter_order" name="filterOrder" class="data-entry-select">
						<option></option>
						<cfloop query="orders">
							<option <cfif isdefined("filterOrder") and #phylorder# EQ #filterOrder#>selected</cfif>>#orders.phylorder#</option>
						</cfloop>
					</select>
				</div>
				<div class="col-12 col-md-5">
					<label for="filter_families" class="data-entry-label">Order:</label>
					<div name="filterFamily" id="filter_family" class="w-100"></div>
					<script>
						$(document).ready(function () {
							var familysource = [
							<cfset comma="">
							<cfloop query="families">
								#comma#{name:"#families.family#",value:"#families.family#"}
								<cfset comma=",">
							</cfloop>
							];
							$("##filterFamily").jqxComboBox({ source: familysource, displayMember:"name", valueMember:"value", multiSelect: true, height: '23px', width: '100%' });
						});
					</script> 
				</div>
				<div class="col-12 col-md-2">
					<input type="submit" class="btn btn-xs btn-secondary" value="Filter Specimens" onClick='document.getElementById("action").value="nothing";document.forms["filterResults"].submit();'></input>
				</div>
			</form>
		</div>
	</div>
</cfoutput>
<div class="container">
	<div class="row">
	<table class="table">
		<thead class="thead-light">
			<tr>
				<th>Catalog Number</th>
				<cfif len(#session.CustomOtherIdentifier#) GT 0>
					<th>
						<cfoutput>
						#session.CustomOtherIdentifier#
						</cfoutput>
					</th>
				</cfif>
				<th>Order</th>
				<th>Family</th>
				<th>Accepted Scientific Name</th>
				<th>Locality ID</th>
				<th>Spec Locality</th>
				<th>higher_geog</th>
			</tr>
		</thead>
		<tbody>
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
			</tbody>
		</cfoutput>
	</table>
	</div>
</div>

<cfinclude template="/shared/_footer.cfm">
