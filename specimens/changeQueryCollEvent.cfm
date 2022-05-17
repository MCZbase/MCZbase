<cfset pageTitle = "Change Collecting Events for Search Result">
<cfinclude template="/shared/_header.cfm">

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
		collecting_event.verbatim_date,
		collecting_event.verbatim_locality,
		collecting_event.verbatimdepth,
		collecting_event.verbatimelevation,
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
	<cfthrow message = "No records found on which to change collecting events with record_id #encodeForHtml(result_id)# in user_search_table.  Did someone else send you a link to this result set?">
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
			<div class="container-lg">
				<div class="search-box">
					<div class="search-box-header">
						<h1 class="h3 text-white my-1">Find new collecting event for cataloged items [in #encodeForHtml(result_id)#]</h1>
					</div>
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
						<cfinclude template="/localities/searchLocationForm.cfm">
					</form>
				</div>
			</div>
		</cfoutput>
	</cfcase>

	<cfcase value ="updateCollectingEvent">
		<cfoutput>
			<cfset failed=false>
			<cftransaction>
				<cftry>
					<cfquery name="collObjects" dbtype="query">
						select distinct collection_object_id from specimenList
					</cfquery>
					<cfset collObjIdsList = valuelist(collObjects.collection_object_id)>
					<cfoutput>
						<cfloop list="#collEventIdsList#" index = "CEID">
							<cfquery name="updateCollEvent" datasource="uam_god">
								UPDATE cataloged_item 
								SET collecting_event_id = #collecting_event_id#
								WHERE collection_object_id = in (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collObjIdsList#" list="yes">)
							</cfquery>
						</cfloop>
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
				<cfset returnURL = returnURL & "&fiterOrder=#encodeForURL(filterOrder)#">
			</cfif>
			<cfif isdefined("filterFamily")>
				<cfset returnURL = returnURL & "&filterFamily=#encodeForURL(filterFamily)#">
			</cfif>
			<cfif failed>
				<div class="container-fluid">
					<div class="row">
						<div class="col-12 mt-3">
							<h2 class="h2">Changing collecting event for cataloged items [in #encodeForHtml(result_id)#]</h2>
							<div><a href="#returnURL#"><i class="fa fa-arrow-left"></i> Back to Manage Locality</a></div>
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
			<cfset returnURL = returnURL & "&fiterOrder=#encodeForURL(filterOrder)#">
		</cfif>
		<cfif isdefined("filterFamily")>
			<cfset returnURL = returnURL & "&filterFamily=#encodeForURL(filterFamily)#">
		</cfif>
		<cfset actionWord = "That Have Been">
		<cfoutput>
			<div class="container-fluid">
				<div class="row mx-0">
					<div class="col-12 px-4 mt-3">
						<h2 class="h2">Changed collecting event for all #specimenList.recordcount# cataloged items [in #encodeForHtml(result_id)#]</h2>
						<ul class="col-12 list-group list-group-horizontal">
							<li class="list-group-item d-flex justify-content-between align-items-center">
								<a href="#returnURL#"><i class="fa fa-arrow-left"></i> Back to Manage Locality  <!---<span class="badge badge-primary badge-pill">1</span>--->
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
		FROM localityResults
		GROUP BY
			collecting_event_id,
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
	<div class="container-fluid">
		<div class="row mx-1">
			<div class="col-12 px-4 mt-3">
				<h2 class="h2 px-3">Change collecting event for all cataloged items [in #encodeForHtml(result_id)#]</h2>
				<table class="table table-responsive-lg">
					<thead class="thead-light">
						<tr>
							<th>Geog ID</th>
							<th>&nbsp;</th>
							<th>Locality ID</th>
							<th>Spec Locality</th>
							<th>Geog</th>
							<th>Depth/Elevation</th>
							<th style="width: 11%;">Georeference</th>
							<th>Geology</th>
						</tr>
					</thead>
					<tbody>
						<cfset i = 1>
						<cfloop query="localityResults">
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
							<tr>
								<td> <a href="Locality.cfm?Action=editGeog&geog_auth_rec_id=#geog_auth_rec_id#">#geog_auth_rec_id#</a></td>
								<td><a href="editLocality.cfm?locality_id=#locality_id#">#locality_id#</a></td>
								<td>
									<form name="coll#i#" method="post" action="/specimens/changeQueryCollEvent.cfm">
										<input type="hidden" name="result_id" value="#result_id#">
										<input type="hidden" name="newlocality_id" value="#locality_id#">
										<input type="hidden" name="action" value="updateCollectingEvent">
										<cfif isdefined("filterOrder")>
											<input type="hidden" name="filterOrder" value="#filterOrder#">
										</cfif>
										<cfif isdefined("filterFamily")>
											<input type="hidden" name="filterFamily" value="#filterFamily#">
										</cfif>
										<input type="submit"
											value="Change ALL to this Collecting Event"
											class="btn btn-warning btn-xs">
									</form>
								</td>
								<td>#spec_locality#</td>
								<td>#higher_geog#</td>
								<td>#depth_elevation#</td>
								<td>#georeference#</td>
								<td>#geolAtts#</td>
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
		<cfset returnURL = returnURL & "&fiterOrder=#encodeForURL(filterOrder)#">
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
					<h2 class="h3 pt-0 mt-0 mb-1 px-4">Cataloged Items #actionWord# Changed: #specimenList.recordcount#</h2>
				</cfif>
			</div>
		</div>
	</div>
</cfoutput>
<div class="container-fluid">
	<div class="row mx-0">
		<div class="col-12">
			<table class="table table-responsive-lg">
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
						<th>Verbatim Locality</th>
						<th>Date Collected</th>
						<th>higher_geog</th>
						<th>Depth/Elevation</th>
						<th>Geology</th>
					</tr>
				</thead>
				<tbody>
					<cfoutput query="specimenList" group="collection_object_id">
						<cfset depth_elevation = "">
						<cfif len(min_depth) GT 0>
							<cfif min_depth EQ max_depth>
								<cfset depth_elevation = "Depth: #min_depth# #depth_units#">
							<cfelse>
								<cfset depth_elevation = "Depth: #min_depth#-#max_depth# #depth_units#">
							</cfif>
						</cfif>
						<cfif len(verbatimdepth) GT 0>
							<cfset depth_elevation = "#depth_elevation# #verbatim_depth# ">
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
							<td>#verbatim_locality#</td>
							<td>#verbatim_date#</td>
							<td>#higher_geog#</td>
							<td>#depth_elevation#</td>
							<td>#geolAtts#</td>
						</tr>
					</cfoutput>
				</tbody>
			</table>
		</div>
	</div>
</div>

<cfinclude template="/shared/_footer.cfm">
