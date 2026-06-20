<!---
encumbrances/component/functions.cfc

Backing methods to support creating, editing, and deleting encumbrance records.

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2026 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Architecture note — extending encumbrances to new object types
==============================================================
Encumbrances currently apply only to cataloged items (specimens) via the
coll_object_encumbrance junction table (encumbrance_id, collection_object_id).

The most likely near-term extension is locality-level encumbrances: an encumbrance
placed directly on a locality record that is inherited by all specimens collected at
that locality.  This would require:

  1. A new junction table:
       locality_encumbrance (encumbrance_id NUMBER, locality_id NUMBER)
     with foreign keys to encumbrance.encumbrance_id and locality.locality_id.

  2. A new encumbrance_action code (e.g. "mask locality") that signals the action
     should be applied at the locality level.  See ctencumbrance_action.

  3. Updates to the methods in this file (marked with TODO: locality_encumbrance below):
     - deleteEncumbrance: add a count check against locality_encumbrance before allowing
       deletion, in addition to the existing coll_object_encumbrance check.
     - getEncumbranceDetail: add locality_count to the returned data struct.
     - getEncumberedObjectsHtml: implement the "locality" cfcase block.

  4. Updates to encumbrances/component/search.cfc (marked there with TODO):
     - Add a locality_count subquery to renderEncumbranceSearchResults.
     - Add a "Localities" column to the results table.
     - Adjust the delete-guard condition to also require locality_count EQ 0.

  5. Updates to encumbrances/viewEncumbrance.cfm:
     - The tabbed section already has a "Localities" tab stub; implement it by calling
       getEncumberedObjectsHtml(encumbrance_id, "locality").

  6. Updates to localities/viewLocality.cfm and related pages:
     - Currently those pages check for encumbrances on specimens associated with the
       locality (bottom-up).  With locality-level encumbrances the check should also
       query locality_encumbrance directly (top-down).

  7. Inheritance logic for specimen display:
     - When resolving the effective encumbrances for a specimen, the query should
       UNION coll_object_encumbrance rows with rows derived from locality_encumbrance
       via the specimen-locality relationship.

Other future object-type extensions (media, agent, transaction) follow the same
pattern: new junction table + cfcase block here + column in search results + tab in
viewEncumbrance.cfm.

--->
<cfcomponent>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">
<cf_rolecheck>

<!---
 createEncumbrance inserts a new encumbrance record and returns the new encumbrance_id.

 @param encumberingAgentId  required agent_id for the encumbering agent.
 @param encumbrance         required descriptive name for the encumbrance.
 @param encumbrance_action  required action code from ctencumbrance_action.
 @param made_date           optional ISO date string for when the encumbrance was made.
 @param expiration_date     optional ISO date string for when the encumbrance expires.
 @param expiration_event    optional text description of the expiration event.
 @param remarks             optional remarks.
 @return struct with keys: status ("ok"|"error"), encumbrance_id (on success), message (on error).
--->
<cffunction name="createEncumbrance" access="remote" returntype="struct" returnformat="json">
	<cfargument name="encumberingAgentId" type="string" required="yes">
	<cfargument name="encumbrance" type="string" required="yes">
	<cfargument name="encumbrance_action" type="string" required="yes">
	<cfargument name="made_date" type="string" required="no" default="">
	<cfargument name="expiration_date" type="string" required="no" default="">
	<cfargument name="expiration_event" type="string" required="no" default="">
	<cfargument name="remarks" type="string" required="no" default="">

	<cfset data = StructNew()>
	<cftransaction>
		<cftry>
			<cfif len(trim(encumberingAgentId)) EQ 0>
				<cfthrow message="No Encumbering Agent provided. You must select an agent.">
			</cfif>
			<cfif NOT isNumeric(encumberingAgentId)>
				<cfthrow message="Invalid Encumbering Agent ID.">
			</cfif>
			<cfif len(trim(encumbrance_action)) EQ 0>
				<cfthrow message="No Encumbrance Action provided. You must specify an action.">
			</cfif>
			<cfif len(trim(encumbrance)) EQ 0>
				<cfthrow message="No Encumbrance Name provided. You must provide a descriptive name for the encumbrance.">
			</cfif>
			<cfif len(trim(expiration_date)) GT 0 AND len(trim(expiration_event)) GT 0>
				<cfthrow message="You may specify an expiration date or an expiration event, but not both.">
			</cfif>
			<cfquery name="nextEncumbrance" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT sq_encumbrance_id.nextval AS nextEncumbrance
				FROM dual
			</cfquery>
			<cfquery name="insertEncumbrance" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				INSERT INTO encumbrance (
					ENCUMBRANCE_ID,
					ENCUMBERING_AGENT_ID,
					ENCUMBRANCE,
					ENCUMBRANCE_ACTION
					<cfif len(trim(expiration_date)) GT 0>
						,EXPIRATION_DATE
					</cfif>
					<cfif len(trim(expiration_event)) GT 0>
						,EXPIRATION_EVENT
					</cfif>
					<cfif len(trim(made_date)) GT 0>
						,MADE_DATE
					</cfif>
					<cfif len(trim(remarks)) GT 0>
						,REMARKS
					</cfif>
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#nextEncumbrance.nextEncumbrance#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#encumberingAgentId#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(encumbrance)#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(encumbrance_action)#">
					<cfif len(trim(expiration_date)) GT 0>
						,<cfqueryparam cfsqltype="CF_SQL_DATE" value="#dateformat(trim(expiration_date),'yyyy-mm-dd')#">
					</cfif>
					<cfif len(trim(expiration_event)) GT 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(expiration_event)#">
					</cfif>
					<cfif len(trim(made_date)) GT 0>
						,<cfqueryparam cfsqltype="CF_SQL_DATE" value="#dateformat(trim(made_date),'yyyy-mm-dd')#">
					</cfif>
					<cfif len(trim(remarks)) GT 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(remarks)#">
					</cfif>
				)
			</cfquery>
			<cftransaction action="commit">
			<cfset data["status"] = "ok">
			<cfset data["encumbrance_id"] = nextEncumbrance.nextEncumbrance>
		<cfcatch>
			<cftransaction action="rollback">
			<cfif isDefined("cfcatch.queryError")><cfset queryError = cfcatch.queryError><cfelse><cfset queryError = ""></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript>reportError(function_called="#function_called#", error_message="#error_message#");</cfscript>
			<cfset data["status"] = "error">
			<cfset data["message"] = error_message>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn data>
</cffunction>

<!---
 saveEncumbrance updates an existing encumbrance record.

 @param encumbrance_id      required encumbrance_id of the record to update.
 @param encumberingAgentId  required agent_id for the encumbering agent.
 @param encumbrance         required descriptive name for the encumbrance.
 @param encumbrance_action  required action code from ctencumbrance_action.
 @param made_date           optional ISO date string (set empty to clear).
 @param expiration_date     optional ISO date string (set empty to clear).
 @param expiration_event    optional text description of the expiration event (set empty to clear).
 @param remarks             optional remarks (set empty to clear).
 @return struct with keys: status ("ok"|"error"), message (on error).
--->
<cffunction name="saveEncumbrance" access="remote" returntype="struct" returnformat="json">
	<cfargument name="encumbrance_id" type="string" required="yes">
	<cfargument name="encumberingAgentId" type="string" required="yes">
	<cfargument name="encumbrance" type="string" required="yes">
	<cfargument name="encumbrance_action" type="string" required="yes">
	<cfargument name="made_date" type="string" required="no" default="">
	<cfargument name="expiration_date" type="string" required="no" default="">
	<cfargument name="expiration_event" type="string" required="no" default="">
	<cfargument name="remarks" type="string" required="no" default="">

	<cfset data = StructNew()>
	<cftransaction>
		<cftry>
			<cfif len(trim(encumbrance_id)) EQ 0 OR NOT isNumeric(encumbrance_id)>
				<cfthrow message="Invalid or missing encumbrance_id.">
			</cfif>
			<cfif len(trim(encumberingAgentId)) EQ 0 OR NOT isNumeric(encumberingAgentId)>
				<cfthrow message="No Encumbering Agent provided. You must select an agent.">
			</cfif>
			<cfif len(trim(encumbrance_action)) EQ 0>
				<cfthrow message="No Encumbrance Action provided. You must specify an action.">
			</cfif>
			<cfif len(trim(encumbrance)) EQ 0>
				<cfthrow message="No Encumbrance Name provided. You must provide a descriptive name for the encumbrance.">
			</cfif>
			<cfif len(trim(expiration_date)) GT 0 AND len(trim(expiration_event)) GT 0>
				<cfthrow message="You may specify an expiration date or an expiration event, but not both.">
			</cfif>
			<cfquery name="updateEnc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE encumbrance
				SET
					ENCUMBERING_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#encumberingAgentId#">,
					ENCUMBRANCE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(encumbrance)#">,
					ENCUMBRANCE_ACTION = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(encumbrance_action)#">,
					EXPIRATION_DATE = <cfqueryparam cfsqltype="CF_SQL_DATE" value="#trim(expiration_date)#" null="#len(trim(expiration_date)) EQ 0#">,
					EXPIRATION_EVENT = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(expiration_event)#" null="#len(trim(expiration_event)) EQ 0#">,
					MADE_DATE = <cfqueryparam cfsqltype="CF_SQL_DATE" value="#trim(made_date)#" null="#len(trim(made_date)) EQ 0#">,
					REMARKS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(remarks)#" null="#len(trim(remarks)) EQ 0#">
				WHERE
					encumbrance_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#encumbrance_id#">
			</cfquery>
			<cftransaction action="commit">
			<cfset data["status"] = "ok">
		<cfcatch>
			<cftransaction action="rollback">
			<cfif isDefined("cfcatch.queryError")><cfset queryError = cfcatch.queryError><cfelse><cfset queryError = ""></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript>reportError(function_called="#function_called#", error_message="#error_message#");</cfscript>
			<cfset data["status"] = "error">
			<cfset data["message"] = error_message>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn data>
</cffunction>

<!---
 deleteEncumbrance removes an encumbrance record if it is not currently in use.

 The in-use guard currently checks only coll_object_encumbrance (cataloged items).

 TODO: locality_encumbrance — when the locality_encumbrance junction table is created,
 add a second count query here:
   SELECT count(*) AS loc_cnt FROM locality_encumbrance
   WHERE encumbrance_id = <cfqueryparam ...>
 Then set data["blocked"] = true and return an appropriate message if loc_cnt > 0.
 The blocked message should distinguish between "in use by specimens" and "in use by
 localities" so callers can direct the user to the correct management page.

 TODO: other future object types — add a parallel count check for each additional
 junction table (e.g. media_encumbrance, agent_encumbrance) before allowing deletion.

 @param encumbrance_id  required encumbrance_id to delete.
 @return struct with keys: status ("ok"|"blocked"|"error"), message, count (when blocked).
--->
<cffunction name="deleteEncumbrance" access="remote" returntype="struct" returnformat="json">
	<cfargument name="encumbrance_id" type="string" required="yes">

	<cfset data = StructNew()>
	<cftransaction>
		<cftry>
			<cfif len(trim(encumbrance_id)) EQ 0 OR NOT isNumeric(encumbrance_id)>
				<cfthrow message="Invalid or missing encumbrance_id.">
			</cfif>
			<!--- Count cataloged items directly linked to this encumbrance via coll_object_encumbrance.
			     TODO: locality_encumbrance — add a second count check here when that table exists. --->
			<cfquery name="isUsed" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT count(*) AS cnt
				FROM coll_object_encumbrance
				WHERE encumbrance_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#encumbrance_id#">
			</cfquery>
			<cfif isUsed.cnt GT 0>
				<cftransaction action="rollback">
				<cfset data["status"] = "blocked">
				<cfset data["count"] = isUsed.cnt>
				<cfset data["message"] = "This encumbrance is applied to #isUsed.cnt# specimen(s). Remove all specimens from this encumbrance before deleting it.">
			<cfelse>
				<cfquery name="deleteEnc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					DELETE FROM encumbrance
					WHERE encumbrance_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#encumbrance_id#">
				</cfquery>
				<cftransaction action="commit">
				<cfset data["status"] = "ok">
				<cfset data["message"] = "Encumbrance deleted successfully.">
			</cfif>
		<cfcatch>
			<cftransaction action="rollback">
			<cfif isDefined("cfcatch.queryError")><cfset queryError = cfcatch.queryError><cfelse><cfset queryError = ""></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript>reportError(function_called="#function_called#", error_message="#error_message#");</cfscript>
			<cfset data["status"] = "error">
			<cfset data["message"] = error_message>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn data>
</cffunction>

<!---
 getEncumbranceDetail fetches the full encumbrance record for a given encumbrance_id,
 including a count of directly linked cataloged items.

 TODO: locality_encumbrance — when the locality_encumbrance table exists, add a
 locality_count field to the returned data struct by including a second COUNT subquery
 (or LEFT JOIN) against locality_encumbrance in the main query.  The view page
 (viewEncumbrance.cfm) already anticipates this field; it will display the locality
 count in the Localities tab header once locality_count is present in the data.

 @param encumbrance_id  required encumbrance_id to look up.
 @return struct with keys: status ("ok"|"notfound"|"error"),
         data (struct on success including object_count for specimens),
         message (on error/notfound).
--->
<cffunction name="getEncumbranceDetail" access="remote" returntype="struct" returnformat="json">
	<cfargument name="encumbrance_id" type="string" required="yes">

	<cfset data = StructNew()>
	<cftry>
		<cfif len(trim(encumbrance_id)) EQ 0 OR NOT isNumeric(encumbrance_id)>
			<cfthrow message="Invalid or missing encumbrance_id.">
		</cfif>
		<!--- object_count reflects coll_object_encumbrance rows only.
		     TODO: locality_encumbrance — add locality_count here alongside object_count. --->
		<cfquery name="encDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT
				encumbrance.encumbrance_id,
				encumbrance.encumbering_agent_id,
				encumbrance.encumbrance,
				encumbrance.encumbrance_action,
				encumbrance.made_date,
				encumbrance.expiration_date,
				encumbrance.expiration_event,
				encumbrance.remarks,
				preferred_agent_name.agent_name,
				count(coll_object_encumbrance.collection_object_id) AS object_count
			FROM
				encumbrance
				JOIN preferred_agent_name
					ON encumbrance.encumbering_agent_id = preferred_agent_name.agent_id
				LEFT JOIN coll_object_encumbrance
					ON encumbrance.encumbrance_id = coll_object_encumbrance.encumbrance_id
			WHERE
				encumbrance.encumbrance_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#encumbrance_id#">
			GROUP BY
				encumbrance.encumbrance_id,
				encumbrance.encumbering_agent_id,
				encumbrance.encumbrance,
				encumbrance.encumbrance_action,
				encumbrance.made_date,
				encumbrance.expiration_date,
				encumbrance.expiration_event,
				encumbrance.remarks,
				preferred_agent_name.agent_name
		</cfquery>
		<cfif encDetails.recordcount EQ 0>
			<cfset data["status"] = "notfound">
			<cfset data["message"] = "Encumbrance not found (ID: #encodeForHTML(encumbrance_id)#).">
		<cfelse>
			<cfset rec = StructNew()>
			<cfset rec["encumbrance_id"] = encDetails.encumbrance_id>
			<cfset rec["encumbering_agent_id"] = encDetails.encumbering_agent_id>
			<cfset rec["agent_name"] = encDetails.agent_name>
			<cfset rec["encumbrance"] = encDetails.encumbrance>
			<cfset rec["encumbrance_action"] = encDetails.encumbrance_action>
			<cfset rec["made_date"] = "">
			<cfif isDate(encDetails.made_date)>
				<cfset rec["made_date"] = dateformat(encDetails.made_date,"yyyy-mm-dd")>
			</cfif>
			<cfset rec["expiration_date"] = "">
			<cfif isDate(encDetails.expiration_date)>
				<cfset rec["expiration_date"] = dateformat(encDetails.expiration_date,"yyyy-mm-dd")>
			</cfif>
			<cfset rec["expiration_event"] = encDetails.expiration_event>
			<cfset rec["remarks"] = encDetails.remarks>
			<!--- object_count: number of cataloged items in coll_object_encumbrance for this encumbrance.
			     TODO: locality_encumbrance — add rec["locality_count"] here when that table exists. --->
			<cfset rec["object_count"] = encDetails.object_count>
			<cfset data["status"] = "ok">
			<cfset data["data"] = rec>
		</cfif>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError")><cfset queryError = cfcatch.queryError><cfelse><cfset queryError = ""></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript>reportError(function_called="#function_called#", error_message="#error_message#");</cfscript>
		<cfset data["status"] = "error">
		<cfset data["message"] = error_message>
	</cfcatch>
	</cftry>
	<cfreturn data>
</cffunction>

<!---
 getEncumberedObjectsHtml returns an HTML table of objects associated with a given
 encumbrance, suitable for the tabbed sections in viewEncumbrance.cfm.

 The targetType parameter selects which object type to display.  Currently only
 "specimen" (coll_object_encumbrance) is implemented.  Each future object type
 requires its own junction table and a corresponding <cfcase> block below.

 Locality encumbrance design notes
 ----------------------------------
 When locality_encumbrance (encumbrance_id, locality_id) is created:

   1. Implement the "locality" cfcase block below.  The query should JOIN
      locality_encumbrance to locality, geog_auth_rec, and collecting_event to
      display: locality_id, specific_locality, country, state_prov, county,
      higher_geog, and a count of cataloged_items at that locality (so users can
      understand the inherited specimen scope before removing the encumbrance).

   2. Locality encumbrances are inherited by specimens: a specimen at an encumbered
      locality inherits the encumbrance action even if no row exists in
      coll_object_encumbrance for that specimen.  This inheritance is a display/
      access-control concern; it does not add rows to coll_object_encumbrance.
      The "specimen" cfcase here should NOT attempt to show inherited specimens —
      that would double-count with the locality tab.  Instead, the view page should
      note in the Localities tab that each listed locality encumbers all specimens
      collected there.

   3. The locality tab in viewEncumbrance.cfm should link each locality_id to
      /localities/viewLocality.cfm?locality_id=... so curators can navigate directly
      to the locality record to review or add related specimens.

 @param encumbrance_id  required encumbrance_id to look up.
 @param targetType      object-type selector: "specimen" (default), "locality" (stub),
                        reserved for future: "media", "agent", "transaction".
 @return HTML string containing the encumbered objects table or a no-items message.
--->
<cffunction name="getEncumberedObjectsHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="encumbrance_id" type="string" required="yes">
	<cfargument name="targetType" type="string" required="no" default="specimen">
	<!--- When editMode is true, a Remove button column is added to the specimens table.
	     The remove button calls removeSpecimenFromEncumbrance(encumbranceId, collectionObjectId)
	     which is defined in encumbrances/js/encumbrances.js. --->
	<cfargument name="editMode" type="boolean" required="no" default="false">

	<cftry>
		<cfif len(trim(encumbrance_id)) EQ 0 OR NOT isNumeric(encumbrance_id)>
			<cfthrow message="Invalid or missing encumbrance_id.">
		</cfif>
		<cfswitch expression="#lcase(trim(targetType))#">

			<!--- ============================================================
			     specimen: cataloged items directly linked via coll_object_encumbrance.
			     Does not include specimens that inherit an encumbrance from a
			     locality-level encumbrance; those appear only in the locality tab.
			     ============================================================ --->
			<cfdefaultcase>
				<cfquery name="encObjects" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT
						cataloged_item.collection_object_id,
						cataloged_item.cat_num,
						collection.institution_acronym,
						collection.collection_cde,
						identification.scientific_name,
						geog_auth_rec.country,
						geog_auth_rec.state_prov,
						geog_auth_rec.county
					FROM
						coll_object_encumbrance
						JOIN cataloged_item
							ON coll_object_encumbrance.collection_object_id = cataloged_item.collection_object_id
						JOIN collection
							ON cataloged_item.collection_id = collection.collection_id
						LEFT JOIN identification
							ON cataloged_item.collection_object_id = identification.collection_object_id
							AND identification.accepted_id_fg = 1
						LEFT JOIN collecting_event
							ON cataloged_item.collecting_event_id = collecting_event.collecting_event_id
						LEFT JOIN locality
							ON collecting_event.locality_id = locality.locality_id
						LEFT JOIN geog_auth_rec
							ON locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
					WHERE
						coll_object_encumbrance.encumbrance_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#encumbrance_id#">
					ORDER BY
						collection.institution_acronym, collection.collection_cde, cataloged_item.cat_num
				</cfquery>
				<cfoutput>
					<cfif encObjects.recordcount EQ 0>
						<p class="text-muted">No specimens are directly linked to this encumbrance via coll_object_encumbrance.</p>
					<cfelse>
						<p class="text-muted mb-2">
							<small>#encObjects.recordcount# specimen(s) directly encumbered.</small>
						</p>
						<table class="table table-sm table-striped table-responsive d-xl-table">
							<thead class="thead-light">
								<tr>
									<th scope="col">Catalog Number</th>
									<th scope="col">Scientific Name</th>
									<th scope="col">Country</th>
									<th scope="col">State/Province</th>
									<th scope="col">County</th>
									<cfif editMode><th scope="col"></th></cfif>
								</tr>
							</thead>
							<tbody>
								<cfloop query="encObjects">
									<tr>
										<td>
											<a href="/specimens/Specimen.cfm?collection_object_id=#encObjects.collection_object_id#">
												#encodeForHTML(encObjects.institution_acronym)#&nbsp;#encodeForHTML(encObjects.collection_cde)#&nbsp;#encodeForHTML(encObjects.cat_num)#
											</a>
										</td>
										<td><em>#encodeForHTML(encObjects.scientific_name)#</em></td>
										<td>#encodeForHTML(encObjects.country)#</td>
										<td>#encodeForHTML(encObjects.state_prov)#</td>
										<td>#encodeForHTML(encObjects.county)#</td>
										<cfif editMode>
											<td>
												<button type="button" class="btn btn-xs btn-warning"
													aria-label="Remove this specimen from the encumbrance"
													onclick="removeSpecimenFromEncumbrance('#encumbrance_id#','#encObjects.collection_object_id#')">
													Remove
												</button>
											</td>
										</cfif>
									</tr>
								</cfloop>
							</tbody>
						</table>
					</cfif>
				</cfoutput>
			</cfdefaultcase>

			<!--- ============================================================
			     locality: localities directly linked via locality_encumbrance.
			
			     TODO: Implement this block when the locality_encumbrance table
			     (encumbrance_id, locality_id) has been created.
			
			     Suggested query structure:
			       SELECT
			         locality.locality_id,
			         locality.specific_locality,
			         geog_auth_rec.higher_geog,
			         geog_auth_rec.country,
			         geog_auth_rec.state_prov,
			         geog_auth_rec.county,
			         count(cataloged_item.collection_object_id) AS specimen_count
			       FROM locality_encumbrance
			         JOIN locality ON locality_encumbrance.locality_id = locality.locality_id
			         LEFT JOIN geog_auth_rec ON locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
			         LEFT JOIN collecting_event ON locality.locality_id = collecting_event.locality_id
			         LEFT JOIN cataloged_item ON collecting_event.collecting_event_id = cataloged_item.collecting_event_id
			       WHERE locality_encumbrance.encumbrance_id = <cfqueryparam ...>
			       GROUP BY locality.locality_id, locality.specific_locality,
			                geog_auth_rec.higher_geog, geog_auth_rec.country,
			                geog_auth_rec.state_prov, geog_auth_rec.county
			       ORDER BY geog_auth_rec.country, geog_auth_rec.state_prov,
			                geog_auth_rec.county, locality.specific_locality
			
			     Render a table with columns:
			       Locality ID (linked to /localities/viewLocality.cfm?locality_id=...)
			       Specific Locality
			       Higher Geography
			       Country / State / County
			       Specimens at Locality (specimen_count, with note that these
			         inherit the encumbrance action from the locality)
			
			     The table header note should explain the inheritance model:
			       "All specimens collected at these localities inherit this
			        encumbrance. They are not listed in the Specimens tab unless
			        they are also directly encumbered via coll_object_encumbrance."
			     ============================================================ --->
			<cfcase value="locality">
				<cfoutput>
					<p class="text-muted">
						Locality-level encumbrances are not yet implemented.
						This tab will list localities directly linked to this encumbrance
						once the <code>locality_encumbrance</code> junction table has been created.
					</p>
				</cfoutput>
			</cfcase>

			<!--- ============================================================
			     TODO: add <cfcase value="media"> here when a media_encumbrance
			     junction table (encumbrance_id, media_id) is created.
			     ============================================================ --->

			<!--- ============================================================
			     TODO: add <cfcase value="agent"> here when an agent_encumbrance
			     junction table (encumbrance_id, agent_id) is created.
			     ============================================================ --->

			<!--- ============================================================
			     TODO: add <cfcase value="transaction"> here when a
			     transaction_encumbrance junction table is created.
			     ============================================================ --->

		</cfswitch>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfoutput>
			<h2 class="h3">Error in #function_called#:</h2>
			<div>#error_message#</div>
		</cfoutput>
	</cfcatch>
	</cftry>
</cffunction>

<!---
 addSpecimenToEncumbrance links a cataloged item to an encumbrance via coll_object_encumbrance.
 If the item is already linked, returns status "duplicate" rather than raising an error.

 @param encumbrance_id       required encumbrance_id to add the specimen to.
 @param collection_object_id required collection_object_id of the cataloged item.
 @return struct with keys: status ("ok"|"duplicate"|"error"), message.
--->
<cffunction name="addSpecimenToEncumbrance" access="remote" returntype="struct" returnformat="json">
	<cfargument name="encumbrance_id" type="string" required="yes">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfset data = StructNew()>
	<cftransaction>
		<cftry>
			<cfif len(trim(encumbrance_id)) EQ 0 OR NOT isNumeric(encumbrance_id)>
				<cfthrow message="Invalid or missing encumbrance_id.">
			</cfif>
			<cfif len(trim(collection_object_id)) EQ 0 OR NOT isNumeric(collection_object_id)>
				<cfthrow message="Invalid or missing collection_object_id. Please select a cataloged item from the autocomplete list.">
			</cfif>
			<!--- Check whether the pairing already exists to avoid a duplicate key error. --->
			<cfquery name="checkExists" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT count(*) AS cnt
				FROM coll_object_encumbrance
				WHERE encumbrance_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#encumbrance_id#">
				  AND collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
			</cfquery>
			<cfif checkExists.cnt GT 0>
				<cftransaction action="rollback">
				<cfset data["status"] = "duplicate">
				<cfset data["message"] = "This cataloged item is already linked to this encumbrance.">
			<cfelse>
				<cfquery name="insertLink" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					INSERT INTO coll_object_encumbrance (
						encumbrance_id,
						collection_object_id
					) VALUES (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#encumbrance_id#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
					)
				</cfquery>
				<cftransaction action="commit">
				<cfset data["status"] = "ok">
				<cfset data["message"] = "Cataloged item added to encumbrance.">
			</cfif>
		<cfcatch>
			<cftransaction action="rollback">
			<cfif isDefined("cfcatch.queryError")><cfset queryError = cfcatch.queryError><cfelse><cfset queryError = ""></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript>reportError(function_called="#function_called#", error_message="#error_message#");</cfscript>
			<cfset data["status"] = "error">
			<cfset data["message"] = error_message>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn data>
</cffunction>

<!---
 removeSpecimenFromEncumbrance removes a cataloged item from an encumbrance via coll_object_encumbrance.

 @param encumbrance_id       required encumbrance_id to remove the specimen from.
 @param collection_object_id required collection_object_id of the cataloged item to remove.
 @return struct with keys: status ("ok"|"error"), message.
--->
<cffunction name="removeSpecimenFromEncumbrance" access="remote" returntype="struct" returnformat="json">
	<cfargument name="encumbrance_id" type="string" required="yes">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfset data = StructNew()>
	<cftransaction>
		<cftry>
			<cfif len(trim(encumbrance_id)) EQ 0 OR NOT isNumeric(encumbrance_id)>
				<cfthrow message="Invalid or missing encumbrance_id.">
			</cfif>
			<cfif len(trim(collection_object_id)) EQ 0 OR NOT isNumeric(collection_object_id)>
				<cfthrow message="Invalid or missing collection_object_id.">
			</cfif>
			<cfquery name="removeLink" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				DELETE FROM coll_object_encumbrance
				WHERE encumbrance_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#encumbrance_id#">
				  AND collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
			</cfquery>
			<cftransaction action="commit">
			<cfset data["status"] = "ok">
			<cfset data["message"] = "Cataloged item removed from encumbrance.">
		<cfcatch>
			<cftransaction action="rollback">
			<cfif isDefined("cfcatch.queryError")><cfset queryError = cfcatch.queryError><cfelse><cfset queryError = ""></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript>reportError(function_called="#function_called#", error_message="#error_message#");</cfscript>
			<cfset data["status"] = "error">
			<cfset data["message"] = error_message>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn data>
</cffunction>

</cfcomponent>
