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
	 <cfquery name="getLoc"	 datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select  spec_locality, geog_auth_rec_id from locality
		where locality_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
	</cfquery>
	<cfquery name="getGeo" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select higher_geog from geog_auth_rec where
		geog_auth_rec_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getLoc.geog_auth_rec_id#">
	</cfquery>
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
						<cfthrow message="Error deleting collecting event, other than one event affected."
						<cftransaction action="rollback">
					</cfif>
				</cftransaction>
			</cfif>
		</cfoutput>
	</cfcase>
</cfswitch>

<cfinclude template = "/shared/_footer.cfm">
