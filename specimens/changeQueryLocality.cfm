<cfset pageTitle = "Change Localities for Search Result">
<cfinclude template="/shared/_header.cfm">

<cfif not isDefined("result_id") OR len(result_id) EQ 0>
	<cfthrow message = "No result_id provided for result set on which to change localities.">
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

<!--- actions entryPoint, findLocality, updateLocality, and updateComplete, determine top portion of page --->

<!--- normal call sequence is entryPoint (list to change with locality search form), 
  findLocality (run locality search, list localities to pick from), updateLocality (apply change), and 
  updateComplete (report on sucessfull update) --->

<cfswitch expression="#action#">
	<cfcase value="entryPoint">
		<cfset title = "Change Locality">
		<cfset showLocality=1>
		<cfset showEvent=0>
		<cfoutput>
			<div class="container-lg">
				<div class="col-12">
					<h1 class="h3 mt-3 px-3">Find new locality for cataloged items [in #encodeForHtml(result_id)#]</h1>
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
			</div>
		</cfoutput>
	</cfcase>

	<cfcase value ="updateLocality">
		<cfoutput>
			<cfset failed=false>
			<cftransaction>
				<cftry>
					<cfquery name="collEvents" dbtype="query">
						select distinct collecting_event_id from specimenList
					</cfquery>
					<cfset collEventIdsList = valuelist(collEvents.collecting_event_id)>
					<cfquery name="collObjects" dbtype="query">
						select distinct collection_object_id from specimenList
					</cfquery>
					<cfset collObjIdsList = valuelist(collObjects.collection_object_id)>
					<cfoutput>
						<cfloop list="#collEventIdsList#" index = "CEID">
							<!--- Loop through each current collecting event in the result set --->
							<cfquery name="checkCollEvent" datasource="uam_god">
								SELECT collection_object_id 
								FROM cataloged_item
								WHERE 
									collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#CEID#">
									AND collection_object_id not in (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collObjIdsList#" list="yes">)
							</cfquery>
							<cfif checkCollEvent.RecordCount is 0>
								<!--- a collecting event to be updated contains only cataloged items in the result set, update directly --->
								<cfquery name="updateCollEvent" datasource="uam_god">
									UPDATE collecting_event 
									SET locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#newLocality_Id#">
									WHERE collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#CEID#">
								</cfquery>
							<cfelse>
								<!--- a collecting event to be updated contains cataloged items not in result set, clone, then update and use clone. --->
								<cfquery name="getID" datasource = "uam_god">
									SELECT sq_collecting_event_id.nextval as newID 
									FROM dual
								</cfquery>
								<cfset newCollEventID = getId.newId>
								<!--- Clone then update, so that newLocality_Id can be passed as a cfqueryparam --->
								<cfquery name="cloneCE" datasource="uam_god">
									INSERT INTO collecting_event(COLLECTING_EVENT_ID,LOCALITY_ID,DATE_BEGAN_DATE,DATE_ENDED_DATE,VERBATIM_DATE,VERBATIM_LOCALITY,COLL_EVENT_REMARKS,VALID_DISTRIBUTION_FG,COLLECTING_SOURCE,COLLECTING_METHOD,HABITAT_DESC,DATE_DETERMINED_BY_AGENT_ID,FISH_FIELD_NUMBER,BEGAN_DATE,ENDED_DATE,COLLECTING_TIME,VERBATIMCOORDINATES,VERBATIMLATITUDE,VERBATIMLONGITUDE,VERBATIMCOORDINATESYSTEM,VERBATIMSRS, STARTDAYOFYEAR,ENDDAYOFYEAR)
										SELECT  #newCollEventID#, LOCALITY_ID, DATE_BEGAN_DATE,DATE_ENDED_DATE,VERBATIM_DATE,VERBATIM_LOCALITY,COLL_EVENT_REMARKS,VALID_DISTRIBUTION_FG,COLLECTING_SOURCE,COLLECTING_METHOD,HABITAT_DESC,DATE_DETERMINED_BY_AGENT_ID,FISH_FIELD_NUMBER,BEGAN_DATE,ENDED_DATE,COLLECTING_TIME,VERBATIMCOORDINATES,VERBATIMLATITUDE,VERBATIMLONGITUDE,VERBATIMCOORDINATESYSTEM,VERBATIMSRS,STARTDAYOFYEAR,ENDDAYOFYEAR
										FROM collecting_event 
										WHERE collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#CEID#">
								</cfquery>
								<cfquery name="updateCollEvent" datasource="uam_god">
									UPDATE collecting_event 
									SET locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#newLocality_Id#">
									WHERE collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#newCollEventID#">
								</cfquery>
								<cfquery name="updateSpecs" datasource="uam_god" result="updateSpecs_result">
									UPDATE cataloged_item 
									SET collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#newCollEventID#">
									WHERE collection_object_id in	(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collObjIdsList#">)
										AND collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#CEID#">
								</cfquery>
							</cfif>
						</cfloop>
					</cfoutput>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="rollback">
					<cfset failed=true>
					<cfset error_message = cfcatchToErrorMessage(cfcatch)>
					<h3 class="h3">Update failed</h3>
					<div>Error setting locality for cataloged items in search result: #error_message#</div>
				</cfcatch>
				</cftry>
			</cftransaction>
			<cfset returnURL = "/specimens/changeQueryLocality.cfm?result_id=#encodeForURL(result_id)#">
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
							<h2 class="h2">Changing locality for cataloged items [in #encodeForHtml(result_id)#]</h2>
							<div><a href="#returnURL#">Back to Manage Locality</a></div>
						</div>
					</div>
				</div>
			<cfelse>
				<cflocation url="#returnURL#&action=updateComplete">
			</cfif>
		</cfoutput>
	</cfcase>

	<cfcase value="updateComplete">
		<cfset returnURL = "/specimens/changeQueryLocality.cfm?result_id=#encodeForURL(result_id)#">
		<cfif isdefined("filterOrder")>
			<cfset returnURL = returnURL & "&fiterOrder=#encodeForURL(filterOrder)#">
		</cfif>
		<cfif isdefined("filterFamily")>
			<cfset returnURL = returnURL & "&filterFamily=#encodeForURL(filterFamily)#">
		</cfif>
		<cfset actionWord = "That Have Been">
		<cfoutput>
			<div class="container-lg">
				<div class="row mx-0">
					<div class="col-12 mt-3">
						<h2 class="h2">Changed locality for all #specimenList.recordcount# cataloged items [in #encodeForHtml(result_id)#]</h2>
						<ul class="col-12 list-group">
							<li class="list-group-item d-flex justify-content-between align-items-center"><a class="btn btn-xs btn-primary" href="#returnURL#"><i class="fa-solid arrow-left"></i> Back to Manage Locality  <span class="badge badge-primary badge-pill">123</span></a></li>
							<li class="list-group-item d-flex justify-content-between align-items-center"><a class="btn btn-xs btn-secondary" href="/specimens/manageSpecimens.cfm?result_id=#encodeForURL(result_id)#"><i class="fa-solid arrow-left"></i> Back to Manage Results <span class="badge badge-primary badge-pill">456</span></a></li>
						</ul>
					</div>
				</div>
			</div>
		</cfoutput>
	</cfcase>

	<cfcase value="findLocality">
	<cfoutput>
	<cf_findLocality>
	<cfquery name="localityResults" dbtype="query">
		SELECT
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
		<div class="row mx-0">
			<div class="col-12 mt-3">
				<h2 class="h2 px-3">Change locality for all cataloged items [in #encodeForHtml(result_id)#]</h2>
				<table class="table">
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
								value="Change ALL to this Locality"
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
	<div class="container-lg">
		<div class="row mx-0">
			<div class="col-12 px-3 mt-3">
				<h2 class="h3 mb-1">Cataloged Items #actionWord# Changed: #specimenList.recordcount#</h2>
				<cfif orders.recordcount GT 1 AND families.recordcount GT 1>
					<form name="filterResults">
						<div class="form-row mb-2">
							<input type="hidden" name="result_id" value="#result_id#">
							<input type="hidden" name="action" value="entryPoint" id="action">
							<div class="col-12 col-md-5 my-2">
								<label for="filterOrder" class="data-entry-label">Filter by Order:</label>
								<select id="filterOrder" name="filterOrder" class="data-entry-select">
									<option></option>
									<cfloop query="orders">
										<option <cfif isdefined("filterOrder") and #phylorder# EQ #filterOrder#>selected</cfif>>#orders.phylorder#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-5 my-2">
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
							<div class="col-12 col-md-2 my-2">
								<label for="filter records" class="data-entry-label" style="color: transparent">Filter</label>
								<input type="submit" class="btn btn-xs btn-primary" value="Filter Records" onClick='document.getElementById("action").value="entryPoint";document.forms["filterResults"].submit();'></input>
							</div>
						</div>
					</form>
				</cfif>
			</div>
		</div>
	</div>
</cfoutput>
<div class="container-fluid">
	<div class="row mx-0">
		<div class="col-12">
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
						<cfif len(minimum_elevation) GT 0>
							<cfif minimum_elevation EQ maximum_elevation>
								<cfset depth_elevation = "Depth: #minimum_elevation# #orig_elev_units#">
							<cfelse>
								<cfset depth_elevation = "Depth: #minimum_elevation#-#maximum_elevation# #orig_elev_units#">
							</cfif>
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
