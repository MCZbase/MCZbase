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
		<cfif lookupEvent.recordcount EQ 0>
			<cfoutput>
				<main class="container-fluid container-xl my-2" id="content">
					<section class="row">
						<div class="col-12 mt-2 mb-1">
							<h1 class="h2 mt-3 pl-1 ml-2" id="formheading">
								Collecting event (#encodeForHtml(collecting_event_id)#) not found.
							</h1>
						</div>
					</section>
				</main>
			</cfoutput>
			<cfinclude template = "/shared/_footer.cfm">
			<cfabort>
		</cfif>
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
			<cfset extra=" (#lookupEvent.collecting_event_id#)">
			<cfoutput>
				<main class="container-fluid my-2" id="content">
					<section class="row">
						<div class="col-12 mt-2 mb-1">
							<div class="col-12 col-md-10 col-xl-9 pl-xl-0 float-left">
								<h1 class="h2 mt-3 pl-1 ml-2" id="formheading">
									Edit Collecting Event#extra#
									<a role="button" href="/localities/viewCollectingEvent.cfm?collecting_event_id=#encodeForURL(collecting_event_id)#" class="btn btn-primary btn-xs float-right mr-1">View</a>
								</h1>
								<div class="border-top border-right border-left border-bottom border-success rounded px-3 my-3 pt-3 pb-2">
									<cfquery name="collectingEventUses" datasource="uam_god">
										SELECT
											count(cataloged_item.cat_num) numOfSpecs,
											collection.collection,
											collection.collection_cde,
											collection.collection_id,
											locality_id
										from
											collecting_event
											join cataloged_item on cataloged_item.collecting_event_id = collecting_event.collecting_event_id 
											left join collection on cataloged_item.collection_id = collection.collection_id
										WHERE
											collecting_event.collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
										GROUP BY
											collection.collection,
											collection.collection_cde,
											collection.collection_id,
											locality_id
									</cfquery>
									<div>
										<cfif #collectingEventUses.recordcount# is 0>
											<h2 class="h4 px-1">
												This CollectingEvent (#collecting_event_id#) contains no specimens. 
												Please delete it if you don&apos;t have plans for it!
											</h2>
											<cfquery name="deleteBlocks" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
												SELECT 
													count(*) ct, 'media' as block
												FROM media_relations
												WHERE
													related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
													and media_relationship like '% collecting_event'
													and media_id is not null
												UNION
												SELECT
													count(*) ct, 'number' as block
												FROM
													coll_event_number
												WHERE
													collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
													and coll_event_number_id is not null
											</cfquery>
											<cfset hasBlock = false>
											<cfloop query="deleteBlocks">
												<cfif deleteBlocks.ct GT 0>
													<cfset hasBlock = true>
												</cfif>
											</cfloop>
											<cfif NOT hasBlock>
												<button type="button" class="btn btn-xs btn-danger" 
													onClick="confirmDialog('Delete this collecting event?', 'Confirm Delete Collecting Event', function() { location.assign('/localities/CollectingEvent.cfm?action=delete&collecting_event_id=#encodeForUrl(collecting_event_id)#'); } );" 
												>
													Delete Collecting Event
												</button>
											<cfelse>
												<div>
													Related media or collecting event numbers will have to be deleted first. (
													<cfset separator="">
													<cfloop query="deleteBlocks">
														#separator##block#:#ct#
														<cfset separator="; ">
													</cfloop>	
													)
												</div>
											</cfif>
										<cfelseif #collectingEventUses.recordcount# is 1>
											<h2 class="h4 px-1">
												This CollectingEvent (#collecting_event_id#) contains 
												<a href="/Specimens.cfm?execute=true&builderMaxRows=1&action=builderSearch&nestdepth1=1&field1=COLLECTING_EVENT%3ACE_COLLECTING_EVENT_ID&searchText1=#collecting_event_id#">
													#collectingEventUses.numOfSpecs# #collectingEventUses.collection_cde# specimens
												</a>
												see <a href="/localities/CollectingEvents.cfm?execute=true&locality_id=#collectingEventUses.locality_id#&include_counts=true&include_ce_counts=true">other collecting events at this locality</a>.
											</h2>
										<cfelse>
											<cfset totalSpecimens=0>
											<cfloop query="collectingEventUses">
												<cfset totalSpecimens=totalSpecimens+collectingEventUses.numOfSpecs>
											</cfloop>
											<h2 class="h4 px-2">
												This CollectingEvent (#collecting_event_id#)
												contains the following <a href="/Specimens.cfm?execute=true&builderMaxRows=1&action=builderSearch&nestdepth1=1&field1=COLLECTING_EVENT%3ACE_COLLECTING_EVENT_ID&searchText1=#collecting_event_id#">#totalSpecimens# specimens</a>
											</h2>
											<ul class="px-2 pl-xl-4 ml-xl-1 small95">
												<cfloop query="collectingEventUses">
													<li>
														<cfif numOfSpecs EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
														<a href="/Specimens.cfm?execute=true&builderMaxRows=2&action=builderSearch&nestdepth1=1&field1=COLLECTING_EVENT%3ACE_COLLECTING_EVENT_ID&searchText1=#collecting_event_id#&nestdepth2=2&JoinOperator2=and&field2=CATALOGED_ITEM%3ACOLLECTION_CDE&searchText2=%3D#collectingEventUses.collection_cde#">
															#numOfSpecs# #collection_cde# specimen#plural#
														</a>
													</li>
												</cfloop>
											</ul>
										</cfif>
									</div>
								</div>
								<div class="border-top border-right border-left border-bottom border-success rounded px-3 my-3 pt-2 pb-1">
									<cfset summary = getCollectingEventSummary(collecting_event_id="#collecting_event_id#")>
									<div id="summary" class="p-2"><span class="sr-only">Summary: </span>#summary#</div>
								</div>
								<div class="border rounded px-2 my-2 p-2" arial-labeledby="formheading">
									<cfset blockform = getCollectingEventFormHtml(collecting_event_id = "#collecting_event_id#",mode="edit")>
									<form name="editCollectingEventForm" id="editCollectingEventForm">
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
												url : "/localities/component/functions.cfc",
												type : "post",
												dataType : "json",
												data : $('##editCollectingEventForm').serialize(),
												success : function (data) {
													$('##editCollEventStatus').html('Saved.');
													$('##editCollEventStatus').addClass('text-success');
													$('##editCollEventStatus').removeClass('text-danger');
													$('##editCollEventStatus').removeClass('text-warning');
													reloadSummary();
												},
												error: function(jqXHR,textStatus,error){
													$('##editCollEventStatus').html('Error.');
													$('##editCollEventStatus').addClass('text-danger');
													$('##editCollEventStatus').removeClass('text-success');
													$('##editCollEventStatus').removeClass('text-warning');
													handleFail(jqXHR,textStatus,error,'saving collecting event record');
												}
											});
										};
									</script>
								</div>
								<div class="border rounded p-2 my-1 ">
									<a class="btn btn-xs btn-secondary" target="_blank" href="/localities/CollectingEvent.cfm?action=new&clone_from_collecting_event_id=#collecting_event_id#">Clone</a>
								</div>
							</div>
							<section class="col-12 px-md-0 col-md-2 col-xl-3 float-left">
								<!--- map --->
								<div class="col-12 px-1 bg-light pt-0 pb-1 mt-2 mb-2 border rounded">
									<cfset map = getLocalityMapHtml(locality_id="#lookupEvent.locality_id#",extraText="For Locality")>
									<div id="mapDiv">#map#</div>
								</div>
							</section>
						</div>
						<div class="col-12 form-row">
							<div class="col-12">
								<div class="border rounded px-2 p-3 my-2" arial-labeledby="formheading">
									<cfset blocknumbers = getEditCollectingEventNumbersHtml(collecting_event_id="#collecting_event_id#")>
									<div id="collEventNumbersDiv">#blocknumbers#</div>
								</div>
							</div>
							<div class="col-12">
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
											<input type="button" value="Link Existing Media as #relations.relation#" class="btn btn-xs btn-secondary mt-2 mt-xl-0" onClick=" openlinkmediadialog('mediaDialogDiv', 'Collecting Event: #onelinesummary#', '#collecting_event_id#', '#relations.relation#', reloadMediaRelationships); ">
											<input type="button" value="Add New Media as #relations.relation#" class="btn btn-xs btn-secondary mt-2 mt-xl-0" onClick=" opencreatemediadialog('mediaDialogDiv', 'Collecting Event: #onelinesummary#', '#collecting_event_id#', '#relations.relation#', reloadMediaRelationships); ">
										</cfloop>
									</div>
									<div id="mediaDialogDiv"></div>
								</div>
							</div>
							<div class="col-12">
								<div class="border bg-light rounded p-3 my-2">
									<h3 class="h4" id="formheading">Collectors in this Collecting Event</h2>
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
						</div>
					</section>
					<script>
						function reloadSummary() { 
							loadCollEventSummaryHTML('#collecting_event_id#','summary');
							reloadMap();
						}
						function reloadNumbers()  {
							loadCollEventNumbersHTML('#collecting_event_id#','collEventNumbersDiv');
						}
						function reloadMediaRelationships()  {
							loadCollEventMediaHTML('#collecting_event_id#','mediaDiv');
						}
						function reloadMap()  {
							loadLocalityMapHTML($("##locality_id").val(),'mapDiv');
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
		<cfelseif isDefined("clone_from_collecting_event_id") and len(clone_from_collecting_event_id) GT 0>
			<cfset extra = " cloned from #encodeForHtml(clone_from_collecting_event_id)#">
				<cfset blockform = getCollectingEventFormHtml(clone_from_collecting_event_id = "#clone_from_collecting_event_id#",mode="create")>
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
				<!--- check if something else would block deletion --->
				<cfquery name="deleteBlocks" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT 
						count(*) ct, 'media' as block
					FROM media_relations
					WHERE
						related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
						and media_relationship like '% collecting_event'
						and media_id is not null
					UNION
					SELECT
						count(*) ct, 'number' as block
					FROM
						coll_event_number
					WHERE
						collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
						and coll_event_number_id is not null
				</cfquery>
				<cfset hasBlock = false>
				<cfloop query="deleteBlocks">
					<cfif deleteBlocks.ct GT 0>
						<cfset hasBlock = true>
					</cfif>
				</cfloop>
				<cfif hasBlock>
					<h2 class="h2">Unable to delete.</h2>
					<div>Collecting Event has related media or collector numbers.  These must be removed before the collecting event can be deleted.</div>
				<cfelse>
					<cftransaction>
						<cfquery name="deleteCollEvent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteCollEvent_result">
							DELETE from collecting_event
							WHERE collecting_event_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
						</cfquery>
						<cfif deleteCollEvent_result.recordcount EQ 1>
							<h2>Successfully deleted collecting event.</h2>
							<ul>
								<li><a href="/localities/CollectingEvents.cfm">Search for Collecting Events</a>.</li>
								<li><a href="/localities/CollectingEvent.cfm?action=new">Create a new Collecting Event</a>.</li>
							</ul>
							<cftransaction action="commit">
						<cfelse>
							<cfthrow message="Error deleting collecting event, other than one event affected.">
							<cftransaction action="rollback">
						</cfif>
					</cftransaction>
				</cfif>
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
					ENDDAYOFYEAR,
					fish_field_number,
					date_determined_by_agent_id
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
					<cfif len(#fish_field_number#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#fish_field_number#">
					<cfelse>
						,NULL
					</cfif>
					<cfif len(#date_determined_by_agent_id#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#date_determined_by_agent_id#">
					<cfelse>
						,NULL
					</cfif>
				)
			</cfquery>
		<cftransaction>
		<cflocation addtoken="no" url="/localities/CollectingEvent.cfm?collecting_event_id=#nextColl.nextColl#">
	</cfcase>
</cfswitch>

<cfinclude template = "/shared/_footer.cfm">
