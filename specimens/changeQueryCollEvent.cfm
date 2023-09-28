<!--- specimens/changeQueryCollEvent.cfm manage specimens by collecting event

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2022 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--->
<cfset pageTitle = "Change Collecting Events for Search Result">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">
<script src="/includes/sorttable.js"></script>

<cfif not isDefined("result_id") OR len(result_id) EQ 0>
	<cfthrow message = "No result_id provided for result set on which to change collecting events.">
</cfif>
<cfif not isDefined("action") OR len(action) EQ 0>
	<cfset action="entryPoint">
</cfif>
<cfset actionWord = "To Be">

<!--- For all actions, obtain data from the list of cataloged items specified by the result_id --->
<cfquery name="specimenList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	 SELECT distinct
	 	cataloged_item.collection_object_id as collection_object_id,
		cataloged_item.cat_num,
		cataloged_item.collecting_event_id,
		concatSingleOtherId(cataloged_item.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID,
		flat.scientific_name,
		locality.locality_id,
		locality.spec_locality,
		concatGeologyAttributeDetail(locality.locality_id) geolAtts,
		locality.minimum_elevation,
		locality.maximum_elevation,
		locality.orig_elev_units,
		locality.min_depth,
		locality.max_depth,
		locality.depth_units,
		locality.geog_auth_rec_id,
		collecting_event.began_date,
		collecting_event.ended_date,
		collecting_event.collecting_time,
		collecting_event.startdayofyear,
		collecting_event.enddayofyear,
		collecting_event.verbatim_date,
		collecting_event.verbatim_locality,
		collecting_event.verbatimcoordinates,
		collecting_event.verbatimSRS,
		collecting_event.verbatimdepth,
		collecting_event.verbatimelevation,
		collecting_event.collecting_method,
		collecting_event.collecting_source,
		collecting_event.habitat_desc,
		collecting_event.fish_field_number,
		collecting_event.coll_event_remarks,
		geog_auth_rec.higher_geog,
		collection.institution_acronym,
		collection.collection,
		flat.phylorder,
		flat.family,
		nvl2(accepted_lat_long.coordinate_precision, round(accepted_lat_long.dec_lat,accepted_lat_long.coordinate_precision), round(accepted_lat_long.dec_lat,5)) as dec_lat,
		nvl2(accepted_lat_long.coordinate_precision, round(accepted_lat_long.dec_long,accepted_lat_long.coordinate_precision), round(accepted_lat_long.dec_long,5)) as dec_long,
		accepted_lat_long.datum,
		trim(upper(section_part) || ' ' || nvl2(section,'S','') || section ||  nvl2(township,' T',' ') || township || upper(township_direction) || nvl2(range,' R',' ') || range || upper(range_direction)) as plss,
		accepted_lat_long.verificationstatus
	FROM
		user_search_table
		left join cataloged_item on user_search_table.collection_object_id = cataloged_item.collection_object_id
		left join collection on  cataloged_item.collection_id = collection.collection_id
		left join collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id
		left join locality on collecting_event.locality_id = locality.locality_id
		left join geog_auth_rec on  locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
		left join flat on cataloged_item.collection_object_id = flat.collection_object_id
		left join accepted_lat_long on locality.locality_id = accepted_lat_long.locality_id
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
	<cfthrow message = "No records found on which to change collecting events with record_id #encodeForHtml(result_id)# in user_search_table.  Did someone else send you a link to this result set?">
</cfif>
<cfset filterTextForHead = "">
<cfset hasFilter = false>
<cfif isdefined("filterOrder") AND len(filterOrder) GT 0 >
	<cfset filterTextForHead = "#filterTextForHead# filtered by Order #encodeForHtml(filterOrder)#">
	<cfset hasFilter = true>
</cfif>
<cfif isdefined("filterFamily") AND len(filterFamily) GT 0 >
	<cfset filterTextForHead = "#filterTextForHead# filtered by Family #encodeForHtml(filterFamily)#">
	<cfset hasFilter = true>
</cfif>

<!--------------------------------------------------------------------------------------------------->

<!--- actions entryPoint, findCollectingEvent, updateCollectingEvent, and updateComplete, determine top portion of page --->

<!--- normal call sequence is entryPoint (list to change with locality search form), 
  findCollectingEvent (run locality search, list localities to pick from), updateCollectingEvent (apply change), and 
  updateComplete (report on sucessfull update) --->

<cfswitch expression="#action#">
	<cfcase value="entryPoint">
		<cfset title = "Change Collecting Event">
		<cfset showLocality=1>
		<cfset showEvent=1>
		<cfoutput>
			<main id="content">
				<h1 class="h2 mt-3 mb-0 px-4">Find new collecting event for cataloged items [in #encodeForHtml(result_id)#]#filterTextForHead#</h1>
				<form name="getLoc" method="post" action="/specimens/changeQueryCollEvent.cfm">
					<input type="hidden" name="Action" value="findCollectingEvent">
					<input type="hidden" name="result_id" value="#result_id#">
					<cfif isdefined("filterOrder")>
						<input type="hidden" name="filterOrder" value="#filterOrder#">
					</cfif>
					<cfif isdefined("filterFamily")>
						<input type="hidden" name="filterFamily" value="#filterFamily#">
					</cfif>
					<cfset showSpecimenCounts = false>
					<div class="row mx-0">
						<section class="container-fluid" role="search">
							<cfinclude template="/localities/searchLocationForm.cfm">
						</section>
					</div>
				</form>
			</main>
		</cfoutput>
	</cfcase>

	<cfcase value ="updateCollectingEvent">
		<cfoutput>
			<cfset failed=false>
			<cftransaction>
				<cftry>
					<cfquery name="checkCollEvent" datasource="uam_god">
						SELECT count(*) ct
						FROM collecting_event
						WHERE collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#newcollecting_event_id#">
					</cfquery>
					<cfif checkCollEvent.ct NEQ 1>
						<cfthrow message="Target collecting event id to change to [#encodeForHtml(newcollecting_event_id)#] not found.">
					</cfif>
					<!--- filter criteria on result are applied in specimenList query, so list passed to updateCollEvent is filtered --->
					<cfquery name="collObjects" dbtype="query">
						select distinct collection_object_id from specimenList
					</cfquery>
					<cfset collObjIdsList = valuelist(collObjects.collection_object_id)>
					<cfoutput>
						<cfquery name="updateCollEvent" datasource="uam_god">
							UPDATE cataloged_item 
							SET collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#newcollecting_event_id#">
							WHERE collection_object_id in (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collObjIdsList#" list="yes">)
						</cfquery>
					</cfoutput>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="rollback">
					<cfset failed=true>
					<cfset error_message = cfcatchToErrorMessage(cfcatch)>
					<h3 class="h3">Update failed</h3>
					<div>Error setting collecting event for cataloged items in search result: #error_message#</div>
				</cfcatch>
				</cftry>
			</cftransaction>
			<cfset returnURL = "/specimens/changeQueryCollEvent.cfm?result_id=#encodeForURL(result_id)#">
			<cfif isdefined("filterOrder")>
				<cfset returnURL = returnURL & "&filterOrder=#encodeForURL(filterOrder)#">
			</cfif>
			<cfif isdefined("filterFamily")>
				<cfset returnURL = returnURL & "&filterFamily=#encodeForURL(filterFamily)#">
			</cfif>
			<cfif failed>
				<div class="container-fluid">
					<div class="row">
						<div class="col-12 mt-3">
							<h2 class="h2">Changing collecting event for cataloged items [in #encodeForHtml(result_id)#]#filterTextForHead#</h2>
							<div><a href="#returnURL#"><i class="fa fa-arrow-left"></i> Back to Manage Collecting Event</a></div>
						</div>
					</div>
				</div>
			<cfelse>
				<cflocation url="#returnURL#&action=updateComplete">
			</cfif>
		</cfoutput>
	</cfcase>

	<cfcase value="updateComplete">
		<cfset returnURL = "/specimens/changeQueryCollEvent.cfm?result_id=#encodeForURL(result_id)#">
		<cfif isdefined("filterOrder")>
			<cfset returnURL = returnURL & "&filterOrder=#encodeForURL(filterOrder)#">
		</cfif>
		<cfif isdefined("filterFamily")>
			<cfset returnURL = returnURL & "&filterFamily=#encodeForURL(filterFamily)#">
		</cfif>
		<cfset actionWord = "That Have Been">
		<cfoutput>
			<div class="container-fluid">
				<div class="row mx-0">
					<div class="col-12 px-4 mt-3">
						<h2 class="h2">Changed collecting event for all #specimenList.recordcount# cataloged items [in #encodeForHtml(result_id)#]#filterTextForHead#</h2>
						<ul class="col-12 list-group list-group-horizontal">
							<li class="list-group-item d-flex justify-content-between align-items-center">
								<a href="#returnURL#"><i class="fa fa-arrow-left"></i> Back to Manage Collecting Event  <!---<span class="badge badge-primary badge-pill">1</span>--->
								</a>
							</li>
							<li class="list-group-item d-flex justify-content-between align-items-center">
								<a href="/specimens/manageSpecimens.cfm?result_id=#encodeForURL(result_id)#"><i class="fa fa-arrow-left"></i> Back to Manage Results <!---<span class="badge badge-primary badge-pill">1</span>--->
								</a>
							</li>
						</ul>
					</div>
				</div>
			</div>
		</cfoutput>
	</cfcase>

	<cfcase value="findCollectingEvent">
	<cfoutput>
	<cf_findLocality>
	<cfquery name="localityResults" dbtype="query">
		SELECT
			collecting_event_id,
			locality_id,
			geog_auth_rec_id,
			spec_locality,
			higher_geog,
			LatitudeString,
			LongitudeString,
			verbatimcoordinates,
			NoGeorefBecause,
			coordinateDeterminer,
			coordinate_precision,
			datum,
			lat_long_ref_source,
			plss,
			verificationstatus,
			determined_date,
			geolAtts,
			min_depth,
			max_depth,
			depth_units,
			minimum_elevation,
			maximum_elevation,
			orig_elev_units,
			began_date,
			ended_date,
			startdayofyear,
			enddayofyear,
			collecting_time,
			verbatim_date,
			verbatim_locality,
			verbatimlatitude,
			verbatimlongitude,
			verbatimsrs,
			habitat_desc,
			collecting_source,
			collecting_method,
			coll_event_remarks,
			fish_field_number
		FROM localityResults
		GROUP BY
			collecting_event_id,
			locality_id,
			geog_auth_rec_id,
			spec_locality,
			higher_geog,
			LatitudeString,
			LongitudeString,
			verbatimcoordinates,
			NoGeorefBecause,
			coordinate_precision,
			datum,
			coordinateDeterminer,
			lat_long_ref_source,
			plss,
			verificationstatus,
			determined_date,
			geolAtts,
			min_depth,
			max_depth,
			depth_units,
			minimum_elevation,
			maximum_elevation,
			orig_elev_units,
			began_date,
			ended_date,
			startdayofyear,
			enddayofyear,
			collecting_time,
			verbatim_date,
			verbatim_locality,
			verbatimlatitude,
			verbatimlongitude,
			verbatimsrs,
			habitat_desc,
			collecting_source,
			collecting_method,
			coll_event_remarks,
			fish_field_number
	</cfquery>
	<div class="container-fluid">
		<div class="row mx-1">
			<div class="col-12 px-4 mt-3">
				<cfif hasFilter>
					<h2 class="h2 px-3">Change collecting event for #specimenList.recordCount# cataloged items [in #encodeForHtml(result_id)#]<strong>#filterTextForHead#</strong></h2>
				<cfelse>
					<h2 class="h2 px-3">Change collecting event for all cataloged items [in #encodeForHtml(result_id)#]#filterTextForHead#</h2>
				</cfif>
				<table class="table table-responsive-lg sortable" id="catItemsTable">
					<thead class="thead-light">
						<tr>
							<th>Higher Geog (ID)</th>
							<th>Locality (ID)</th>
							<th>&nbsp;</th>
							<th>CollEvent ID</th>
							<th>Date Collected [verbatim]</th>
							<th>Coll Source/ Method/ Numbers</th>
							<th>Verbatim Locality</th>
							<th>Depth/Elevation</th>
							<th>Georeference [verbatim]</th>
							<th>Geology</th>
							<th>Remarks</th>
						</tr>
					</thead>
					<tbody>
						<cfset i = 1>
						<cfloop query="localityResults">
							<cfquery name="getCollNumbers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								SELECT distinct 
									coll_event_number, number_series, collector_agent_id
								FROM
									coll_event_number
									join coll_event_num_series on coll_event_number.coll_event_num_series_id = coll_event_num_series.coll_event_num_series_id
								WHERE 
									coll_event_number.collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
							</cfquery>
							<cfset eventNumbers = fish_field_number>
							<cfloop query="getCollNumbers">
								<cfset series = getCollNumbers.number_series>
								<cfif len(getCollNumbers.collector_agent_id) GT 0>
									<cfset series = "<a href='/agents/Agent.cfm?agent_id=#getCollNumbers.collector_agent_id#' target='_blank'>#series#</a>" ><!--- " --->
								</cfif>
								<cfset eventNumbers = "#eventNumbers# #getCollNumbers.coll_event_number# #series#">
							</cfloop>
							<cfif localityResults.began_date EQ localityResults.ended_date>
								<cfset date=localityResults.began_date>
							<cfelseif len(localityResults.began_date) GT 0 AND len(localityResults.began_date) GT 0>
								<cfset date="#localityResults.began_date#/#localityResults.ended_date#">
							<cfelse>
								<cfset date=localityResults.began_date>
							</cfif>
							<cfif len(localityResults.verbatim_date) GT 0>
								<cfset date="#date# [#localityResults.verbatim_date#]">
							</cfif>
							<cfset depth_elevation = "">
							<cfif len(min_depth) GT 0>
								<cfif min_depth EQ max_depth>
									<cfset depth_elevation = "Depth: #min_depth# #depth_units#">
								<cfelse>
									<cfset depth_elevation = "Depth: #min_depth#-#max_depth# #depth_units#">
								</cfif>
							</cfif>
							<cfif len(minimum_elevation) GT 0>
								<cfif minimum_elevation EQ maximum_elevation>
									<cfset depth_elevation = "Depth: #minimum_elevation# #orig_elev_units#">
								<cfelse>
									<cfset depth_elevation = "Depth: #minimum_elevation#-#maximum_elevation# #orig_elev_units#">
								</cfif>
							</cfif>
							<cfif len(NoGeorefBecause) GT 0>
								<cfset georeference = NoGeorefBecause>
							<cfelse>
								<cfset georeference="#LatitudeString# #LongitudeString#">
							</cfif>
							<cfif len(localityResults.verbatimcoordinates) GT 0>
								<cfset verbatimcoordinates=" [#verbatimcoordinates# #verbatimsrs#]">
							<cfelseif len(localityResults.verbatimlatitude) GT 0>
								<cfset verbatimcoordinates="[#verbatimlatitude#, #verbatimlongitude# #verbatimsrs#]">
							<cfelse>
								<cfset verbatimcoordinates="">
							</cfif>
							<tr>
								<td>
									#higher_geog#
									(<a href="/localities/viewHigherGeography.cfm?geog_auth_rec_id=#geog_auth_rec_id#" target="_blank">#geog_auth_rec_id#</a>)
								</td>
								<td>
									#spec_locality#
									(<a href="/localities/viewLocality.cfm?locality_id=#locality_id#" target="_blank">#locality_id#</a>)
								</td>
								<td>
									<form name="coll#i#" method="post" action="/specimens/changeQueryCollEvent.cfm">
										<input type="hidden" name="result_id" value="#result_id#">
										<input type="hidden" name="newcollecting_event_id" value="#collecting_event_id#">
										<input type="hidden" name="action" value="updateCollectingEvent">
										<cfif isdefined("filterOrder")>
											<input type="hidden" name="filterOrder" value="#filterOrder#">
										</cfif>
										<cfif isdefined("filterFamily")>
											<input type="hidden" name="filterFamily" value="#filterFamily#">
										</cfif>
										<cfset targetCount = "ALL">
										<cfif hasFilter>
											<cfset targetCount = "#specimenList.recordcount#">
										</cfif>
										<input type="submit"
											value="Change #targetCount# to this Collecting Event"
											class="btn btn-warning btn-xs">
									</form>
								</td>
								<td>
									<!--- TODO: Point to view collecting event page --->
									<a href="/localities/CollectingEvent.cfm?action=edit&collecting_event_id=#collecting_event_id#" target="_blank">#collecting_event_id#</a>
								</td>
								<td>#date#</td>
								<td>#collecting_source# #collecting_method# #eventNumbers#</td>
								<td>#verbatim_locality#</td>
								<td>#depth_elevation#</td>
								<td>#georeference# #verbatimcoordinates# #plss# #verificationstatus#</td>
								<td>#geolAtts#</td>
								<td>#coll_event_remarks#</td>
							</tr>
							<cfset i=#i#+1>
						</cfloop>
					</tbody>
				</table>
			</div>
		</div>
	</div>
	<cfset returnURL = "/specimens/changeQueryCollEvent.cfm?result_id=#encodeForURL(result_id)#">
	<cfif isdefined("filterOrder")>
		<cfset returnURL = returnURL & "&filterOrder=#encodeForURL(filterOrder)#">
	</cfif>
	<cfif isdefined("filterFamily")>
		<cfset returnURL = returnURL & "&filterFamily=#encodeForURL(filterFamily)#">
	</cfif>
	<div class="container-fluid">
		<div class="row">
			<div class="col-12 mt-3">
				<div><a href="#returnURL#"><i class="fa fa-arrow-left"></i> Search Again</a></div>
			</div>
		</div>
	</div>
	</cfoutput>
	</cfcase>
</cfswitch>

<!--------------------------------------------------------------------------------------------------->

<!--- After any action, display the list of cataloged items to be/having been affected --->

<cfquery name="orders" dbtype="query">
	select distinct phylorder from specimenList where phylorder is not null
</cfquery>

<cfquery name="families" dbtype="query">
	select distinct family from specimenList where family is not null
</cfquery>

<cfoutput>
	<div class="container-fluid">
		<div class="row">
			<div class="col-12 mt-3">
				<cfif orders.recordcount GT 1 AND families.recordcount GT 1>
					<form name="filterResults">
						<div class="col-7 px-0 mx-auto">
							<div class="form-row mx-0 mb-0">
								<input type="hidden" name="result_id" value="#result_id#">
								<input type="hidden" name="action" value="entryPoint" id="action">
								<div class="col-12 col-md-5 my-0">
									<label for="filterOrder" class="data-entry-label">Filter by Order:</label>
									<select id="filterOrder" name="filterOrder" class="data-entry-select">
										<option></option>
										<cfloop query="orders">
											<option <cfif isdefined("filterOrder") and #phylorder# EQ #filterOrder#>selected</cfif>>#orders.phylorder#</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 col-md-5 my-0">
									<label for="filterFamily" class="data-entry-label">Filter by Families:</label>
									<div name="filterFamily" id="filterFamily" class="w-100"></div>
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
								<div class="col-12 col-md-2 my-0">
									<label for="filter records" class="data-entry-label" style="color: transparent">Filter</label>
									<input type="submit" class="btn btn-xs btn-primary" value="Filter Records" onClick='document.getElementById("action").value="entryPoint";document.forms["filterResults"].submit();'></input>
								</div>
							</div>
						</div>
					</form>
					<h2 class="h3 pt-0 mt-0 mb-1 px-4">Cataloged Items #actionWord# Changed: #specimenList.recordcount##filterTextForHead#</h2>
				<cfelseif hasFilter>
					<cfset returnURL = "/specimens/changeQueryCollEvent.cfm?result_id=#encodeForURL(result_id)#">
					<h2 class="h3 pt-0 mt-0 mb-1 px-4">Cataloged Items #actionWord# Changed: #specimenList.recordcount##filterTextForHead#</h2>
					<cfif actionWord NEQ "That Have Been">
						<div><a href="#returnURL#"><i class="fa fa-arrow-left"></i> Remove Filter</a></div>
					</cfif>
				<cfelse>
					<h2 class="h3 pt-0 mt-0 mb-1 px-4">Cataloged Items #actionWord# Changed: #specimenList.recordcount##filterTextForHead#</h2>
				</cfif>
			</div>
		</div>
	</div>
</cfoutput>
<div class="container-fluid">
	<div class="row mx-0">
		<div class="col-12">
			<table class="table table-responsive-lg sortable" id="specimensTable">
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
						<th>Order: Family</th>
						<th>Accepted Scientific Name</th>
						<th>Higher Geog (ID)</th>
						<th>Locality (ID)</th>
						<th>Coll Event ID</th>
						<th>Date Collected [verbatim]</th>
						<th>Coll Method/ Source
							<cfif specimenList.recordcount LT 101>
								/ Numbers
							</cfif>
						</th>
						<th>Verbatim Locality</th>
						<th>Depth/Elevation</th>
						<th>Georeference</th>
						<th>Geology</th>
					</tr>
				</thead>
				<tbody>
					<cfoutput query="specimenList" group="collection_object_id">
						<cfif len(fish_field_number) GT 0>
							<cfset eventNumbers = "Fish field No: #fish_field_number#">
						<cfelse>
							<cfset eventNumbers = "">
						</cfif>
						<cfif specimenList.recordcount LT 201>
							<cfquery name="getCollNumbersSpec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								SELECT distinct 
									coll_event_number, number_series, collector_agent_id
								FROM
									coll_event_number
									join coll_event_num_series on coll_event_number.coll_event_num_series_id = coll_event_num_series.coll_event_num_series_id
								WHERE 
									coll_event_number.collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#specimenList.collecting_event_id#">
							</cfquery>
							<cfloop query="getCollNumbersSpec">
								<cfset series = getCollNumbersSpec.number_series>
								<cfif len(getCollNumbersSpec.collector_agent_id) GT 0>
									<cfset series = "<a href='/agents/Agent.cfm?agent_id=#getCollNumbersSpec.collector_agent_id#' target='_blank'>#series#</a>" ><!--- " --->
								</cfif>
								<cfset eventNumbers = "#eventNumbers# #getCollNumbersSpec.coll_event_number# #series#">
							</cfloop>
						</cfif>
						<cfif specimenList.began_date EQ specimenList.ended_date>
							<cfset date=specimenList.began_date>
						<cfelseif len(specimenList.began_date) GT 0 AND len(specimenList.began_date) GT 0>
							<cfset date="#specimenList.began_date#/#specimenList.ended_date#">
						<cfelse>
							<cfset date=specimenList.began_date>
						</cfif>
						<cfif len(specimenList.startdayofyear) GT 0 AND len(specimenList.startdayofyear) GT 0>
							<cfset date="#date# day:#startdayofyear#">
							<cfif len(specimenList.enddayofyear) GT 0 AND len(specimenList.enddayofyear) GT 0>
								<cfset date="#date#-#enddayofyear#">
							</cfif>
						</cfif>
						<cfif len(specimenList.collecting_time) GT 0 AND len(specimenList.collecting_time) GT 0>
							<cfset date="#date# #collecting_time#">
						</cfif>
						<cfif len(specimenList.verbatim_date) GT 0>
							<cfset date="#date# [#specimenList.verbatim_date#]">
						</cfif>
						<cfset depth_elevation = "">
						<cfif len(min_depth) GT 0>
							<cfif min_depth EQ max_depth>
								<cfset depth_elevation = "Depth: #min_depth# #depth_units#">
							<cfelse>
								<cfset depth_elevation = "Depth: #min_depth#-#max_depth# #depth_units#">
							</cfif>
						</cfif>
						<cfif len(verbatimdepth) GT 0>
							<cfset depth_elevation = "#depth_elevation# [#verbatim_depth#] ">
						</cfif>
						<cfif len(minimum_elevation) GT 0>
							<cfif minimum_elevation EQ maximum_elevation>
								<cfset depth_elevation = "#depth_elevation#Elev: #minimum_elevation# #orig_elev_units#">
							<cfelse>
								<cfset depth_elevation = "#depth_elevation#Elev: #minimum_elevation#-#maximum_elevation# #orig_elev_units#">
							</cfif>
						</cfif>
						<cfif len(verbatimelevation) GT 0>
							<cfset depth_elevation = "#depth_elevation# #verbatim_elevation#">
						</cfif>
						<cfset georeference="">
						<cfif isDefined("dec_lat") AND len(dec_lat) GT 0>
							<cfif isDefined("verbatimcoordinates") AND len(verbatimcoordinates) GT 0>
								<cfset verbatimcoordinates = "[#verbatimcoordinates#]">
							</cfif>
							<cfset georeference = "#dec_lat#,#dec_long# #datum# [#verbatimcoordinates# #verbatimSRS#]">
						</cfif>
						<cfif isDefined("habitat_desc") AND len(habitat_desc) GT 0>
							<cfset habitat_desc = "habitat:#habitat_desc#">
						</cfif>
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
							<td>#phylorder# #family#</td>
							<td><i>#Scientific_Name#</i></td>
							<td>
								#higher_geog#
								(<a href="/localities/viewHigherGeography.cfm?geog_auth_rec_id=#geog_auth_rec_id#" target="_blank">#geog_auth_rec_id#</a>)
							</td>
							<td>
								#spec_locality# [#verbatim_locality#] #habitat_desc# 
								(<a href="/localities/viewLocality.cfm?locality_id=#locality_id#" target="_blank">#locality_id#</a>)
							</td>
							<td>
								<!--- TODO: Point to view collecting event page --->
								<cftry>
									<!--- assuming a git repository and readable by coldfusion, determine the checked out branch by reading HEAD --->
									<cfset gitBranch = FileReadLine(FileOpen("#Application.webDirectory#/.git/HEAD", "read"))>
								<cfcatch>
									<cfset gitBranch = "unknown">
								</cfcatch>
								</cftry>
								<cfif gitBranch EQ "unknown" OR findNoCase('master',gitBranch) GT 0 >
									<a href="/Locality.cfm?Action=editCollEvnt&collecting_event_id=904879=#collecting_event_id#" target="_blank">#collecting_event_id#</a>
								<cfelse>
									<a href="/localities/viewCollectingEvent.cfm?action=edit&collecting_event_id=#collecting_event_id#" target="_blank">#collecting_event_id#</a>
								</cfif>
							</td>
							<td>#date#</td>
							<td>
								#collecting_source# #collecting_method#
								#eventNumbers#
							</td>
							<td>
								#verbatim_locality# 
								#habitat_desc#
							</td>
							<td>#depth_elevation#</td>
							<td>#georeference# #plss# #verificationstatus#</td>
							<td>#geolAtts#</td>
						</tr>
					</cfoutput>
				</tbody>
			</table>
		</div>
	</div>
</div>

<cfinclude template="/shared/_footer.cfm">
