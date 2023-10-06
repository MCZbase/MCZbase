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

<cfinclude template="/localities/component/functions.cfc" runonce="true">
<cfinclude template="/localities/component/public.cfc" runonce="true">

<cfswitch expression="#action#">
	<cfcase value="edit">
		<cfquery name="lookupEvent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT collecting_event_id, locality_id,
				began_date, ended_date,
				collecting_time, collecting_method,
				verbatim_date
			FROM collecting_event
			WHERE
				collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
		</cfquery>
		<cfquery name="lookupLocality"	 datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT spec_locality, geog_auth_rec_id 
			FROM locality
			WHERE 
				locality_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookupEvent.locality_id#">
		</cfquery>
		<cfquery name="getGeo" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT higher_geog 
			FROM geog_auth_rec 
			WHERE
				geog_auth_rec_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookupLocality.geog_auth_rec_id#">
		</cfquery>
		<cfset summary = "[#lookupEvent.collecting_event_id#]" >
		<!--- Create summary for event for dialogs --->
		<cfset datebit = "">
		<cfif len(lookupEvent.began_date) GT 0>
			<cfif lookupEvent.began_date EQ lookupEvent.ended_date>
				<cfset datebit = lookupEvent.began_date>
			<cfelse>
				<cfset datebit = "#lookupEvent.began_date#/#lookupEvent.ended_date#">
			</cfif>
		</cfif>
		<cfif len(lookupEvent.collecting_time) GT 0>
			<cfset datebit="#datebit# #lookupEvent.collecting_time#">
		</cfif>
		<cfif len(lookupEvent.verbatim_date) GT 0>
			<cfset datebit = "#datebit# [#lookupEvent.verbatim_date#]">
		</cfif>
		<cfset onelinesummary = "#datebit# #lookupEvent.collecting_method# (#lookupEvent.collecting_event_id#)" >
		<cfif lookupEvent.recordcount EQ 1>
			<cfset extra="(#lookupEvent.collecting_event_id#)">
			<cfoutput>
				<main class="container-fluid container-xl my-2" id="content">
					<section class="row">
						<div class="col-12 mt-2 mb-5">
							<h1 class="h2 mt-3 pl-1 ml-2" id="formheading">Edit Collecting Event#extra#</h1>
							<div class="border-top border-right border-left border-bottom border-success rounded px-3 my-3 py-3">
								<cfset blockRelated = getCollectingEventUsesHtml(collecting_event_id = "#collecting_event_id#")>
								<div id="relatedTo">#blockRelated#</div>
								<cfset summary = getCollectingEventSummary(collecting_event_id="#collecting_event_id#")>
								<div id="summary" class="small95 px-2 pb-2"><span class="sr-only">Summary: </span>#summary#</div>
							</div>
							<div class="border rounded px-2 my-2 pt-3 pb-2" arial-labeledby="formheading">
								<cfset blockform = getCollectingEventFormHtml(collecting_event_id = "#collecting_event_id#",mode="edit")>
								<form name="editCollectingEventForm" id="editCollectingEvent">
									<input type="hidden" name="method" value="updateCollectingEvent">
									<input type="hidden" name="returnformat" value="json">
									#blockform#
									<input type="button" class="btn btn-primary btn-xs" value="Save" onClick=" saveEvent(); ">
									<output id="editCollEventStatus"></output>
								</form>
								<script>
									function saveEvent(){ 
										if ($('##editCollectingEventForm')[0].checkValidity()) { 
											saveEdits();
										} else { 
											messageDialog('Error: Unable to save changes, required field missing a value.' ,'Error: Required fields not filled in.');
										}
									} 
									$(document).ready(function(){
										$('##editCollectingEventForm').submit( function(event){ event.preventDefault(); } );
									});
									function handleChange(){
										$('##editCollEventStatus').html('Unsaved changes.');
										$('##editCollEventStatus').addClass('text-danger');
										$('##editCollEventStatus').removeClass('text-success');
										$('##editCollEventStatus').removeClass('text-warning');
									};
									$(document).ready(function() {
										monitorForChanges('editCollectingEventForm',handleChange);
									});
									function saveEdits(){ 
										$('##editCollEventStatus').html('Saving....');
										$('##editCollEventStatus').addClass('text-warning');
										$('##editCollEventStatus').removeClass('text-success');
										$('##editCollEventStatus').removeClass('text-danger');
										jQuery.ajax({
											url : "/transactions/component/functions.cfc",
											type : "post",
											dataType : "json",
											data : $('##editCollectingEventForm').serialize(),
											success : function (data) {
												$('##editCollEventStatus').html('Saved.');
												$('##editCollEventStatus').addClass('text-success');
												$('##editCollEventStatus').removeClass('text-danger');
												$('##editCollEventStatus').removeClass('text-warning');
												loadAgentTable("agentTableContainerDiv",#transaction_id#,"editLoanForm",handleChange);
											},
											error: function(jqXHR,textStatus,error){
												$('##editCollEventStatus').html('Error.');
												$('##editCollEventStatus').addClass('text-danger');
												$('##editCollEventStatus').removeClass('text-success');
												$('##editCollEventStatus').removeClass('text-warning');
												handleFail(jqXHR,textStatus,error,'saving loan record');
											}
										});
									};
								</script>
							</div>
						</div>
						<div class="col-12 px-0 pr-md-3 pl-md-0 ">
							<div class="border rounded px-2 my-2 pt-3 pb-2" arial-labeledby="formheading">
								<cfset blocknumbers = getEditCollectingEventNumbersHtml(collecting_event_id="#collecting_event_id#")>
								<div id="collEventNumbersDiv">#blocknumbers#</div>
							</div>
						</div>
						<div class="col-12 px-0 pr-md-3 pl-md-0 ">
							<div class="border bg-light rounded p-3 my-2">
								<cfset media = getCollectingEventMediaHtml(collecting_event_id="#collecting_event_id#")>
								<div id="mediaDiv" class="row">#media#</div>
								<div id="addMediaDiv">
									<cfquery name="relations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
										SELECT media_relationship as relation 
										FROM ctmedia_relationship 
										WHERE media_relationship like '% collecting_event'
										ORDER BY media_relationship
									</cfquery>
									<cfloop query="relations">
										<cfset onelinesummary = replace(replace(onelinesummary,'"','','all'),"'","","all")>
										<input type="button" value="Link Existing Media as #relations.relation#" class="btn btn-xs btn-secondary mt-2 mt-xl-0" onClick=" openlinkmediadialog('mediaDialogDiv', 'Collecting Event: #onelinesummary#', '#collecting_event_id#', '#relations.relation#', reloadMedia); ">
										<input type="button" value="Add New Media as #relations.relation#" class="btn btn-xs btn-secondary mt-2 mt-xl-0" onClick=" opencreatemediadialog('mediaDialogDiv', 'Collecting Event: #onelinesummary#', '#collecting_event_id#', '#relations.relation#', reloadMedia); ">
									</cfloop>
								</div>
								<div id="mediaDialogDiv"></div>
							</div>
						</div>
						<div class="col-12 px-0 pr-md-3 pl-md-0 ">
							<div class="border bg-light rounded p-3 my-2">
								<h2 class="h3 mt-3 pl-1 ml-2" id="formheading">Collectors in this Collecting Event</h2>
								<cfquery name="getCollectors" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getCollectors_result">
									SELECT
										count(cataloged_item.collection_object_id) ct, 
										agent.agent_id,
										MCZBASE.get_agentnameoftype(agent.agent_id) as name,
										birth_date, death_date
									FROM 
										cataloged_item
										join collector on cataloged_item.collection_object_id = collector.collection_object_id
										join agent on collector.agent_id = agent.agent_id
										left join person on agent.agent_id = person.person_id
									WHERE 
										collector_role = 'c'
										AND collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
									GROUP BY
										agent.agent_id,
										birth_date, death_date
									ORDER BY 
										MCZBASE.get_agentnameoftype(agent.agent_id)
								</cfquery>
								<ul>
									<cfif getCollectors.recordcount EQ 0>
										<li>None</li>
									</cfif>
									<cfloop query="getCollectors">
										<li><a href="/agents/Agent.cfm?agent_id=#agent_id#" target="_blank">#getCollectors.name#</a> (#birth_date#-#death_date#) #ct#</li>
									</cfloop>
								</ul>
							</div>
						</div>
					</section>
					<script>
						function reloadSummary() { 
							TODO: Reload Summary block.
						}
						function reloadNumbers()  {
							loadCollEventNumbersHTML('#collecting_event_id#','collEventNumbersDiv');
						}
						function reloadMedia()  {
							loadCollEventMediaHTML('#collecting_event_id#','mediaDiv');
						}
					</script>
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
			<cfset blockform = getCollectingEventFormHtml(geog_auth_rec_id = "#geog_auth_rec_id#",mode="create")>
		<cfelseif isDefined("clone_from_locality_id") and len(clone_from_locality_id) GT 0>
			<cfset extra = " cloned from #encodeForHtml(clone_from_locality_id)#">
				<cfset blockform = getCollectingEventFormHtml(clone_from_locality_id = "#clone_from_locality_id#",mode="create")>
		<cfelse>
			<cfset blockform = getCollectingEventFormHtml(mode="create")>
		</cfif>
		<cfoutput>
			<main class="container-fluid container-xl my-2" id="content">
				<section class="row">
					<div class="col-12 mt-2 mb-5">
						<h1 class="h2 mt-3 pl-1 ml-2" id="formheading">Create New Collecting Event#extra#</h1>
						<div class="border rounded px-2 my-2 pt-3 pb-2" arial-labeledby="formheading">
							<form name="createCollectingEvent" id="createCollectingEventForm" method="post" action="/localities/CollectingEvent.cfm">
								<input type="hidden" name="Action" value="makenewCollectingEvent">
								#blockform#
								<div class="col-12 col-md-3 pt-2">
									<input type="button" value="Save" class="btn btn-xs btn-primary mr-2" onClick="saveCollectingEvent();" id="submitButton" >
									<output id="createFeedback" class="text-danger">&nbsp;</output>	
								</div>
							</form>
							<script>
								function saveCollectingEvent() { 
									if (checkFormValidity($('##createCollectingEventForm')[0])) { 
										$("##createCollectingEventForm").submit();
									} 
								} 
							</script>
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
