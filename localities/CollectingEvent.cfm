<!---
localities/CollectingEvent.cfm

Create and edit collecting event records.

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2023 President and Fellows of Harvard College

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

<cfif not isdefined("action")>
	<cfif not isdefined("collecting_event_id")>
		<cfset action="new">
	<cfelse>
		<cfset action="edit">
	</cfif>
</cfif>
<cfswitch expression="#action#">
	<cfcase value="edit">
		<cfset pageTitle="Edit Collecting Event">
	</cfcase>
	<cfcase value="new">
		<cfset pageTitle="New Collecting Event">
	</cfcase>
	<cfcase value="makenewCollectingEvent">
		<cfset pageTitle="Creating New Collecting Event">
	</cfcase>
	<cfcase value="delete">
		<cfset pageTitle="Deleting Collecting Event">
	</cfcase>
	<cfdefaultcase>
		<cfthrow message="Error: Unknown Action">
	</cfdefaultcase>
</cfswitch>
<cfset pageHasTabs="false">
<cfinclude template = "/shared/_header.cfm">

<cfswitch expression="#action#">
	<cfcase value="edit">
		<cfquery name="getLoc"	 datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT spec_locality, geog_auth_rec_id 
			FROM locality
			WHERE 
				locality_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
		</cfquery>
		<cfquery name="getGeo" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT higher_geog 
			FROM geog_auth_rec 
			WHERE
				geog_auth_rec_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getLoc.geog_auth_rec_id#">
		</cfquery>
		<cfquery name="lookupEvent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT collecting_event_id 
			FROM collecting_event
			WHERE
				collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
		</cfquery>
		<cfif lookupEvent.recordcount EQ 1>
			<cfset extra="(#lookupEvent.collecting_event_id#)">
			<cfoutput>
				<main class="container-fluid container-xl my-2" id="content">
					<section class="row">
						<div class="col-12 mt-2 mb-5">
							<h1 class="h2 mt-3 pl-1 ml-2" id="formheading">Edit Collecting Event#extra#</h1>
							<div class="border rounded px-2 my-2 pt-3 pb-2" arial-labeledby="formheading">
								<form name="editCollectingEventForm" id="editCollectingEvent">
									#blockform#
									<input type="button" class="btn btn-primary btn-xs" value="Save" onClick=" saveEvent(); ">
									<output id="editCollEventStatus"></output>
								</form>
								<script>
									function saveEvent(){ 
										if ($('##editCollectingEventForm')[0].checkValidity()) { 
											console.log("TODO: implement");
										} else { 
											messageDialog('Error: Unable to save changes, required field missing a value.' ,'Error: Required fields not filled in.');
										}
									} 
									$(document).ready(function(){
										$('##editCollectingEventForm').submit( function(event){ event.preventDefault(); } );
									});
								</script>
							</div>
						</div>
					</section>
				</main>
			</cfoutput>
		<cfelse>
			<cfthrow message="Collecting event [#encodeForHtml(collecting_event_id)#] not found.">
		</cfif>
	</cfcase>
	<cfcase value="new">
		<cfset extra = "">
		<cfif isDefined("locality_id") AND len(locality_id) GT 0 AND NOT (isDefined("clone_from_collecting_event_id") and len(clone_from_collecting_event_id) GT 0)>
			<cfquery name="lookupLocality" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT higher_geog, spec_locality
				FROM 
					locality
					join geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
				WHERE 
					locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
			</cfquery>
			<cfloop query="lookupLocality">
				<cfset extra = " within #lookupLocality.higher_geog# #lookupLocality.spec_locality#">
			</cfloop>
		<cfset blockform = getCreateCollectingEventHtml(geog_auth_rec_id = "#geog_auth_rec_id#")>
		<cfelseif isDefined("clone_from_locality_id") and len(clone_from_locality_id) GT 0>
			<cfset extra = " cloned from #encodeForHtml(clone_from_locality_id)#">
				<cfset blockform = getCreateCollectingEventHtml(clone_from_locality_id = "#clone_from_locality_id#")>
		<cfelse>
			<cfset blockform = getCreateCollectingEventHtml()>
		</cfif>
		<cfoutput>
			<main class="container-fluid container-xl my-2" id="content">
				<section class="row">
					<div class="col-12 mt-2 mb-5">
						<h1 class="h2 mt-3 pl-1 ml-2" id="formheading">Create New Collecting Event#extra#</h1>
						<div class="border rounded px-2 my-2 pt-3 pb-2" arial-labeledby="formheading">
							<form name="createCollectingEvent" method="post" action="/localities/CollectingEvent.cfm">
								<input type="hidden" name="Action" value="makenewCollectingEvent">
								#blockform#
							</form>
						</div>
					</div>
				</section>
			</main>
		</cfoutput>
	</cfcase>
	<cfcase value="delete">
		<cfif not isDefined("collecting_event_id") OR len(collecting_event_id) EQ 0>
			<cfthrow message = "Error: No collecting_event_id provided to delete.">
		</cfif>
		<cfoutput>
			<cfquery name="hasSpecimens" datasource="uam_god">
				SELECT count(collection_object_id) ct from cataloged_item
				WHERE collecting_event_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
			</cfquery>
			<cfif #hasSpecimens.ct# gt 0>
				<cfquery name="lookupVisible" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT count(collection_object_id) ct from cataloged_item
					WHERE collecting_event_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
				</cfquery>
				<h2 class="h2">Unable to delete.</h2>
				<div>
					There are #hasSpecimens.ct# cataloged items associated with this collecting event. It cannot be deleted. 
					<cfif lookupVisible.ct EQ 0>
						You are not able see them as they are not in a collection to which you have access.
					<cfelseif lookupVisible.ct NEQ hasSpecimens.ct>
						Of these #hasSpecimens.ct# cataloged items, only #lookupVisible.ct# are in a collection to which you have access.
					</cfif>
					<a href="/localities/CollectingEvent.cfm?Action=editCollEvent&collecting_event_id=#collecting_event_id#">Return</a> to editing.
				</div>
			<cfelseif hasSpecimens.ct EQ 0>
				<cftransaction>
					<cfquery name="deleteCollEvent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteCollEvent_result">
						DELETE from collecting_event
						WHERE collecting_event_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
					</cfquery>
					<cfif deleteCollEvent_result.recordcount EQ 1>
						<h2>Successfully deleted collecting event.</h2>
						<cftransaction action="commit">
					<cfelse>
						<cfthrow message="Error deleting collecting event, other than one event affected.">
						<cftransaction action="rollback">
					</cfif>
				</cftransaction>
			</cfif>
		</cfoutput>
	</cfcase>
	<cfcase value="makenewCollectingEvent">
		<cftransaction>
			<cfquery name="nextColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT sq_collecting_event_id.nextval nextColl FROM dual
			</cfquery>
			<cfquery name="newCollEvent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO collecting_event (
					collecting_event_id,
					LOCALITY_ID,
					BEGAN_DATE,
					ENDED_DATE,
					VERBATIM_DATE,
					COLLECTING_SOURCE,
					VERBATIM_LOCALITY,
					verbatimdepth,
					verbatimelevation,
					COLL_EVENT_REMARKS,
					COLLECTING_METHOD,
					HABITAT_DESC,
					collecting_time,
					VERBATIMCOORDINATES,
					VERBATIMLATITUDE,
					VERBATIMLONGITUDE,
					VERBATIMCOORDINATESYSTEM,
					VERBATIMSRS,
					STARTDAYOFYEAR,
					ENDDAYOFYEAR
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#nextColl.nextColl#">
					,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LOCALITY_ID#">
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#BEGAN_DATE#">
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ENDED_DATE#">
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VERBATIM_DATE#">
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#COLLECTING_SOURCE#">
					<cfif len(#VERBATIM_LOCALITY#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VERBATIM_LOCALITY#">
					<cfelse>
						,NULL
					</cfif>
					<cfif len(#VERBATIMDEPTH#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VERBATIMDEPTH#">
					<cfelse>
						,NULL
					</cfif>
					<cfif len(#VERBATIMELEVATION#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VERBATIMELEVATION#">
					<cfelse>
						,NULL
					</cfif>
					<cfif len(#COLL_EVENT_REMARKS#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#COLL_EVENT_REMARKS#">
					<cfelse>
						,NULL
					</cfif>
					<cfif len(#COLLECTING_METHOD#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#COLLECTING_METHOD#">
					<cfelse>
						,NULL
					</cfif>
					<cfif len(#HABITAT_DESC#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#HABITAT_DESC#">
					<cfelse>
						,NULL
					</cfif>
					<cfif len(#collecting_time#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collecting_time#">
					<cfelse>
						,NULL
					</cfif>
					<cfif len(#VERBATIMCOORDINATES#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VERBATIMCOORDINATES#">
					<cfelse>
						,NULL
					</cfif>
					<cfif len(#VERBATIMLATITUDE#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VERBATIMLATITUDE#">
					<cfelse>
						,NULL
					</cfif>
					<cfif len(#VERBATIMLONGITUDE#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VERBATIMLONGITUDE#">
					<cfelse>
						,NULL
					</cfif>
					<cfif len(#VERBATIMCOORDINATESYSTEM#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VERBATIMCOORDINATESYSTEM#">
					<cfelse>
						,NULL
					</cfif>
					<cfif len(#VERBATIMSRS#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VERBATIMSRS#">
					<cfelse>
						,NULL
					</cfif>
					<cfif len(#STARTDAYOFYEAR#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#STARTDAYOFYEAR#">
					<cfelse>
						,NULL
					</cfif>
					<cfif len(#ENDDAYOFYEAR#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ENDDAYOFYEAR#">
					<cfelse>
						,NULL
					</cfif>
				)
			</cfquery>
		<cftransaction>
		<cflocation addtoken="no" url="/Locality.cfm?Action=editCollEvnt&collecting_event_id=#nextColl.nextColl#">
	</cfcase>
</cfswitch>

<cfinclude template = "/shared/_footer.cfm">
