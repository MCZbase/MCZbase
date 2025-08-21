<!---
localities/component/pick.cfc

Functions supporting picking of a locality or collecting event from a list of 
search results for localities or collecting events.

Copyright 2025 President and Fellows of Harvard College

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
<cfcomponent>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<!--- pickLocalitySearch backing method for a locality picker dialog, 
 which returns a json list of up to 100 localities matching a specified 
 specific locality with optional additional filters.
 @param spec_locality: the specific locality to search for, case insensitive 
   substring match.
 @param geog_auth_rec_id: the geographic authority record id to filter by,
 @param higher_geog: the higher geographic locality to filter by, case insensitive
   substring match.
 @param higher_geog_pick: ignored.
 @param sovereign_nation: the sovereign nation to filter by, exact match.
 @return a json structure containing locality_id, spec_locality, higher_geog,
   sovereign_nation, minimum_elevation, maximum_elevation, orig_elev_units,
   depth_units, min_depth, max_depth, and vetted status, or on error an http 500
   error response.
--->
<cffunction name="pickLocalitySearch" access="remote" returntype="any" returnformat="json">
	<cfargument name="spec_locality" type="string" required="yes">
	<cfargument name="geog_auth_rec_id" type="string" required="no" default="">
	<cfargument name="higher_geog" type="string" required="no" default="">
	<cfargument name="higher_geog_pick" type="string" required="no" default="">
	<cfargument name="sovereign_nation" type="string" required="no" default="">

	<cfset var specLocalityTerm = "%#arguments.spec_locality#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result">
			SELECT 
				spec_locality, locality_id, higher_geog, sovereign_nation,
				minimum_elevation, maximum_elevation, orig_elev_units,
				depth_units, min_depth, max_depth,
				decode(locality.curated_fg, 1, 'Yes', 0, 'No', 'Unknown') as vetted
			FROM 
				locality
				join geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
			WHERE
				upper(spec_locality) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(specLocalityTerm)#">
				<cfif arguments.geog_auth_rec_id NEQ "">
					AND locality.geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.geog_auth_rec_id#">
				</cfif>
				<cfif arguments.higher_geog NEQ "">
					AND upper(higher_geog) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(arguments.higher_geog)#%">
				</cfif>
				<cfif arguments.sovereign_nation NEQ "">
					AND sovereign_nation = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.sovereign_nation#">
				</cfif>
			ORDER BY
				spec_locality, higher_geog
			FETCH FIRST 100 ROWS ONLY
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset depth = "">
			<cfif search.min_depth NEQ "">
				<cfset depth = search.min_depth>
				<cfif search.max_depth NEQ "">
					<cfset depth = depth & " - " & search.max_depth>
				</cfif>
				<cfset depth = depth & " " & search.depth_units>
			</cfif>
			<cfset elevation = "">
			<cfif search.minimum_elevation NEQ "">
				<cfset elevation = search.minimum_elevation>
				<cfif search.maximum_elevation NEQ "">
					<cfset elevation = elevation & " - " & search.maximum_elevation>
				</cfif>
				<cfset elevation = elevation & " " & search.orig_elev_units>
			</cfif>
			<cfset row["locality_id"] = "#search.locality_id#">
			<cfset row["spec_locality"] = "#search.spec_locality#" >
			<cfset row["higher_geog"] = "#search.higher_geog#">
			<cfset row["sovereign_nation"] = "#search.sovereign_nation#">
			<cfset row["depth"] = "#depth#">
			<cfset row["elevation"] = "#elevation#">
			<cfset row["minimum_elevation"] = "#search.minimum_elevation#">
			<cfset row["maximum_elevation"] = "#search.maximum_elevation#">
			<cfset row["orig_elev_units"] = "#search.orig_elev_units#">
			<cfset row["depth_units"] = "#search.depth_units#">
			<cfset row["min_depth"] = "#search.min_depth#">
			<cfset row["max_depth"] = "#search.max_depth#">
			<cfset row["vetted"] = "#search.vetted#">
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<cffunction name="getLocalityPickerHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="spec_locality_control" type="string" required="yes">
	<cfargument name="locality_id_control" type="string" required="yes">
	<cfargument name="enclosing_dialog_id" type="string" required="yes">
	<cfargument name="callback" type="string" required="no" default="">

	<cfoutput>
		<cftry> 
			<div class='container-fluid'>
				<div class='row'>
					<div class='col-12'>
						<div id='localityPickForm' class='search-box px-3 py-2'>
							<h1 class='h3 mt-2'>Search and Pick a Locality</h1>
								<form id='findLocalityForm' onsubmit='return searchforlocality(event);' >
									<input type='hidden' name='method' value='pickLocalitySearch'>
									<input type='hidden' name='returnformat' value='json'>
			
									<div class='form-row'>
										<div class='col-12 col-md-3 pb-2'>
											<label for='spec_locality' class='data-entry-label'>Specific Locality</label>
				 							<input type='text' name='spec_locality' id='spec_locality' value='' class='data-entry-input reqdClr' required>
										</div>
										<div class='col-12 col-md-2 pb-2'>
											<label for='higher_geog' class='data-entry-label'>Any Part of Higher Geography</label>
				 							<input type='text' name='higher_geog' id='higher_geog' value='' class='data-entry-input'>
											</script>
										</div>
										<div class='col-12 col-md-4 pb-2'>
											<label for='higher_geog_pick' class='data-entry-label'>Higher Geography (pick)</label>
				 							<input type='text' name='higher_geog_pick' id='higher_geog_pick' value='' class='data-entry-input'>
											<input type='hidden' name='geog_auth_rec_id' id='geog_auth_rec_id' value=''>
											<script>
												$(document).ready(function() {
													makeHigherGeogAutocomplete("higher_geog_pick","geog_auth_rec_id");
												});
											</script>
										</div>
										<div class='col-12 col-md-3 pb-2'>
											<label for='sovereign_nation' class='data-entry-label'>Sovereign Nation</label>
							 				<input type='text' name='sovereign_nation' id='sovereign_nation' value='' class='data-entry-input'>
											<script>
												$(document).ready(function() {
													makeSovereignNationAutocomplete("sovereign_nation");
												});
											</script>
										</div>
									</div>
									<div class='form-row mt-2'>
										<div class=''>
											<input type='submit' value='Search' class='btn-primary px-3 mb-2'>
										</div>
										<div class='ml-5'>
											<span ><input type='reset' value='Clear' class='btn-warning mb-2 mt-2 mt-sm-0 mr-1'></span>
										</div>
									</div>
								</div>
							</form>
						</div>
					</div>
				</div>
			</div>
			<script>
				function searchforlocality(event) { 
					event.preventDefault();
					jQuery.ajax({
						url: '/localities/component/pick.cfc',
						type: 'post',
						data: $('##findLocalityForm').serialize(),
						success: function (data) {
							var result = JSON.parse(data);
							// create a table populated with the results
							if (result.length == 0) {
								$('##localitySearchResults').html('<div class="alert alert-info">No localities found.</div>');
								return;
							} else { 
								var table = '<table class="table table-striped table-bordered"><thead><tr><th></th><th>Locality</th><th>Higher Geography</th><th>Sovereign Nation</th><th>Elevation</th><th>Depth</th><th>Vetted</th></tr></thead><tbody>';
								for (var i = 0; i < result.length; i++) {
									table += '<tr>';
									table += '<td><button type="button" class="btn btn-primary btn-sm" onClick=" doPick('+ result[i].locality_id  +','+i+')">Pick</button></td>';
									table += '<td id="spec_locality_'+i+'">' + result[i].spec_locality + '</td>';
									table += '<td>' + result[i].higher_geog + '</td>';
									table += '<td>' + result[i].sovereign_nation + '</td>';
									table += '<td>' + result[i].elevation + '</td>';
									table += '<td>' + result[i].depth + '</td>';
									table += '<td>' + result[i].vetted + '</td>';
									table += '</tr>';
								}
								table += '</tbody></table>';
								$('##localitySearchResults').html(table);
							}
						},
						error: function (jqXHR, textStatus, error) {
							handleFail(jqXHR,textStatus,error,"searching for localities to pick");
						}
					});
					return false; 
				};
				function doPick(locality_id, rowIndex) { 
					var spec_locality = $('##spec_locality_' + rowIndex).text();
					$('###arguments.spec_locality_control#').val(spec_locality);
					$('###arguments.locality_id_control#').val(locality_id);
					if (typeof window['#arguments.callback#'] === 'function') {
						window['#arguments.callback#']();
					}
					// close the dialog
					$("###arguments.enclosing_dialog_id#").dialog("close");
				};
			</script>
			<div id='localitySearchResults' class='container-fluid mt-1'></div>
		<cfcatch> 
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<h2 class="h3 text-danger mt-0">Error: #cfcatch.type# #error_message# in #function_called#</h2> 
			<div>#cfcatch.detail#</div>
		</cfcatch>
		</cftry>
	</cfoutput>
</cffunction>

<!--- pickCollectingEventSearch backing method for a collecting event picker dialog, 
 which returns a json list of up to 100 collecting events matching specified 
 search criteria with optional additional filters.
 @param spec_locality: the specific locality to search for, case insensitive substring match.
 @param verbatim_date: the verbatim date to search for, case insensitive substring match.
 @param collecting_method: the collecting method to search for, case insensitive substring match.
 @param habitat_desc: the habitat description to search for, case insensitive substring match.
 @param verbatimcoordinates: the verbatim coordinates to search for, case insensitive substring match.
 @param verbatim_locality: the verbatim locality to search for, case insensitive substring match.
 @param began_date: the began date to search for, exact match in yyyy-mm-dd format.
 @param ended_date: the ended date to search for, exact match in yyyy-mm-dd format.
 @return a json structure containing collecting_event_id, locality_id, spec_locality,
   verbatim_date, verbatim_locality, collecting_method, habitat_desc, began_date,
   ended_date, verbatimcoordinates, and coll_event_remarks, or on error an http 500
   error response.
--->
<cffunction name="pickCollectingEventSearch" access="remote" returntype="any" returnformat="json">
	<cfargument name="spec_locality" type="string" required="no" default="">
	<cfargument name="verbatim_date" type="string" required="no" default="">
	<cfargument name="collecting_method" type="string" required="no" default="">
	<cfargument name="habitat_desc" type="string" required="no" default="">
	<cfargument name="verbatimcoordinates" type="string" required="no" default="">
	<cfargument name="verbatim_locality" type="string" required="no" default="">
	<cfargument name="began_date" type="string" required="no" default="">
	<cfargument name="ended_date" type="string" required="no" default="">
	<cfargument name="higher_geog" type="string" required="no" default="">

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result">
			SELECT 
				ce.collecting_event_id, ce.locality_id, l.spec_locality,
				ce.verbatim_date, ce.verbatim_locality, ce.collecting_method,
				ce.habitat_desc, ce.began_date, ce.ended_date,
				ce.verbatimcoordinates, ce.coll_event_remarks,
				ce.collecting_time, ce.verbatimelevation, ce.verbatimdepth
			FROM 
				collecting_event ce
				join locality l on ce.locality_id = l.locality_id
				join geog_auth_rec on l.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
			WHERE
				1=1
				<cfif arguments.higher_geog NEQ "">
					AND upper(geog_auth_rec.higher_geog) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(arguments.higher_geog)#%">
				</cfif>
				<cfif arguments.spec_locality NEQ "">
					AND upper(l.spec_locality) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(arguments.spec_locality)#%">
				</cfif>
				<cfif arguments.verbatim_date NEQ "">
					AND upper(ce.verbatim_date) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(arguments.verbatim_date)#%">
				</cfif>
				<cfif arguments.collecting_method NEQ "">
					AND upper(ce.collecting_method) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(arguments.collecting_method)#%">
				</cfif>
				<cfif arguments.habitat_desc NEQ "">
					AND upper(ce.habitat_desc) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(arguments.habitat_desc)#%">
				</cfif>
				<cfif arguments.verbatimcoordinates NEQ "">
					AND upper(ce.verbatimcoordinates) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(arguments.verbatimcoordinates)#%">
				</cfif>
				<cfif arguments.verbatim_locality NEQ "">
					AND upper(ce.verbatim_locality) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(arguments.verbatim_locality)#%">
				</cfif>
				<cfif arguments.began_date NEQ "">
					AND ce.began_date = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.began_date#">
				</cfif>
				<cfif arguments.ended_date NEQ "">
					AND ce.ended_date = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.ended_date#">
				</cfif>
			ORDER BY
				l.spec_locality, ce.verbatim_date, ce.began_date
			FETCH FIRST 100 ROWS ONLY
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["collecting_event_id"] = "#search.collecting_event_id#">
			<cfset row["locality_id"] = "#search.locality_id#">
			<cfset row["spec_locality"] = "#search.spec_locality#" >
			<cfset row["verbatim_date"] = "#search.verbatim_date#">
			<cfset row["verbatim_locality"] = "#search.verbatim_locality#">
			<cfset row["collecting_method"] = "#search.collecting_method#">
			<cfset row["habitat_desc"] = "#search.habitat_desc#">
			<cfset row["began_date"] = "#search.began_date#">
			<cfset row["ended_date"] = "#search.ended_date#">
			<cfset row["verbatimcoordinates"] = "#search.verbatimcoordinates#">
			<cfset row["coll_event_remarks"] = "#search.coll_event_remarks#">
			<cfset row["collecting_time"] = "#search.collecting_time#">
			<cfset row["verbatimelevation"] = "#search.verbatimelevation#">
			<cfset row["verbatimdepth"] = "#search.verbatimdepth#">
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<cffunction name="getCollectingEventPickerHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collecting_event_id_control" type="string" required="yes">
	<cfargument name="enclosing_dialog_id" type="string" required="yes">
	<cfargument name="callback" type="string" required="no" default="">

	<cfoutput>
		<cftry> 
			<div class='container-fluid'>
				<div class='row'>
					<div class='col-12'>
						<div id='collectingEventPickForm' class='search-box px-3 py-2'>
							<h1 class='h3 mt-2'>Search and Pick a Collecting Event</h1>
							<p class='text-muted'>Search and then pick a collecting event from the results.  The search will return up to 100 matches for your search criteria.</p>
							<form id='findCollectingEventForm' onsubmit='return searchforcollectingevent(event);' >
								<input type='hidden' name='method' value='pickCollectingEventSearch'>
								<input type='hidden' name='returnformat' value='json'>
			
								<div class='form-row'>
									<div class='col-12 col-md-3 pb-2'>
										<label for='higher_geog' class='data-entry-label'>Higher Geography</label>
				 						<input type='text' name='higher_geog' id='higher_geog' value='' class='data-entry-input'>
									</div>
									<div class='col-12 col-md-3 pb-2'>
										<label for='spec_locality' class='data-entry-label'>Specific Locality</label>
				 						<input type='text' name='spec_locality' id='spec_locality' value='' class='data-entry-input'>
									</div>
									<div class='col-12 col-md-2 pb-2'>
										<label for='verbatim_date' class='data-entry-label'>Verbatim Date</label>
				 						<input type='text' name='verbatim_date' id='verbatim_date' value='' class='data-entry-input'>
									</div>
									<div class='col-12 col-md-4 pb-2'>
										<label for='collecting_method' class='data-entry-label'>Collecting Method</label>
						 				<input type='text' name='collecting_method' id='collecting_method' value='' class='data-entry-input'>
									</div>
								</div>
								<div class='form-row'>
									<div class='col-12 col-md-4 pb-2'>
										<label for='habitat_desc' class='data-entry-label'>Habitat Description</label>
				 						<input type='text' name='habitat_desc' id='habitat_desc' value='' class='data-entry-input'>
									</div>
									<div class='col-12 col-md-4 pb-2'>
										<label for='verbatimcoordinates' class='data-entry-label'>Verbatim Coordinates</label>
				 						<input type='text' name='verbatimcoordinates' id='verbatimcoordinates' value='' class='data-entry-input'>
									</div>
									<div class='col-12 col-md-4 pb-2'>
										<label for='verbatim_locality' class='data-entry-label'>Verbatim Locality</label>
						 				<input type='text' name='verbatim_locality' id='verbatim_locality' value='' class='data-entry-input'>
									</div>
								</div>
								<div class='form-row'>
									<div class='col-12 col-md-6 pb-2'>
										<label for='began_date' class='data-entry-label'>Began Date (yyyy-mm-dd)</label>
				 						<input type='text' name='began_date' id='began_date' value='' class='data-entry-input' placeholder='yyyy-mm-dd'>
									</div>
									<div class='col-12 col-md-6 pb-2'>
										<label for='ended_date' class='data-entry-label'>Ended Date (yyyy-mm-dd)</label>
				 						<input type='text' name='ended_date' id='ended_date' value='' class='data-entry-input' placeholder='yyyy-mm-dd'>
									</div>
								</div>
								<div class='form-row mt-2'>
									<div class=''>
										<input type='submit' value='Search' class='btn-primary px-3 mb-2'>
									</div>
									<div class='ml-5'>
										<span ><input type='reset' value='Clear' class='btn-warning mb-2 mt-2 mt-sm-0 mr-1'></span>
									</div>
								</div>
							</form>
						</div>
					</div>
				</div>
			</div>
			<script>
				function searchforcollectingevent(event) { 
					event.preventDefault();
					jQuery.ajax({
						url: '/localities/component/pick.cfc',
						type: 'post',
						data: $('##findCollectingEventForm').serialize(),
						success: function (data) {
							var result = JSON.parse(data);
							// create a table populated with the results
							if (result.length == 0) {
								$('##collectingEventSearchResults').html('<div class="alert alert-info">No collecting events found.</div>');
								return;
							} else { 
								var table = '<table class="table table-striped table-bordered table-responsive"><thead><tr><th></th><th>Locality</th><th>Verbatim Date</th><th>Date Range</th><th>Method</th><th>Habitat</th><th>Coordinates</th><th>Verbatim Locality</th></tr></thead><tbody>';
								for (var i = 0; i < result.length; i++) {
									var dateRange = '';
									if (result[i].began_date && result[i].ended_date) {
										dateRange = result[i].began_date + ' to ' + result[i].ended_date;
									} else if (result[i].began_date) {
										dateRange = result[i].began_date;
									} else if (result[i].ended_date) {
										dateRange = result[i].ended_date;
									}
									
									table += '<tr>';
									table += '<td><button type="button" class="btn btn-primary btn-sm" onClick="doPickCollectingEvent('+ result[i].collecting_event_id  +','+i+')">Pick</button></td>';
									table += '<td id="spec_locality_'+i+'">' + (result[i].spec_locality || '') + '</td>';
									table += '<td id="verbatim_date_'+i+'">' + (result[i].verbatim_date || '') + '</td>';
									table += '<td>' + dateRange + '</td>';
									table += '<td>' + (result[i].collecting_method || '') + '</td>';
									table += '<td>' + (result[i].habitat_desc || '') + '</td>';
									table += '<td>' + (result[i].verbatimcoordinates || '') + '</td>';
									table += '<td>' + (result[i].verbatim_locality || '') + '</td>';
									table += '</tr>';
								}
								table += '</tbody></table>';
								$('##collectingEventSearchResults').html(table);
							}
						},
						error: function (jqXHR, textStatus, error) {
							handleFail(jqXHR,textStatus,error,"searching for collecting events to pick");
						}
					});
					return false; 
				};
				function doPickCollectingEvent(collecting_event_id, rowIndex) { 
					$('###arguments.collecting_event_id_control#').val(collecting_event_id);
					if (typeof window['#arguments.callback#'] === 'function') {
						window['#arguments.callback#']();
					}
					// close the dialog
					$("###arguments.enclosing_dialog_id#").dialog("close");
				};
			</script>
			<div id='collectingEventSearchResults' class='container-fluid mt-1'></div>
		<cfcatch> 
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<h2 class="h3 text-danger mt-0">Error: #cfcatch.type# #error_message# in #function_called#</h2> 
			<div>#cfcatch.detail#</div>
		</cfcatch>
		</cftry>
	</cfoutput>
</cffunction>

</cfcomponent>
