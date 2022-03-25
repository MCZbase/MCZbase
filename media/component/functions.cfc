<!---
/media/component/functions.cfc

Copyright 2020 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	 http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Backing methods for managing media

--->
<cfcomponent>
<cf_rolecheck>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<!--- ** method createMedia creates a new media record. 
  * @param media_uri the media_uri to create, must be unique, will produce error if a media record 
  *  with the provided media_uri exists.
  * @param media_type media type for the media record to create, required.
  * @param mime_type mime type for the record to create, required.
  * other parameters are optional, including an arbitrary number of relationship and label parameter sets.
  ** --->
<cffunction name="createMedia" access="remote" returntype="string" returnformat="plain">
	<cfargument name="media_uri" type="string" required="yes">
	<cfargument name="media_type" type="string" required="yes">
	<cfargument name="mime_type" type="string" required="yes">
	<cfargument name="description" type="string" required="yes">
	<cfargument name="preview_uri" type="string" required="no">
	<cfargument name="media_license_id" type="string" required="no">
	<cfargument name="number_of_relations" type="string" required="no">
	<cfargument name="number_of_labels" type="string" required="no">
	<cfargument name="mask_media_fg" type="string" required="no">

	<cfoutput>
		<cftransaction>
			<cftry>
				<cfquery name="mid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select sq_media_id.nextval nv from dual
				</cfquery>
				<cfset media_id=mid.nv>
				<cfquery name="makeMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					insert into media (
							media_id,
							media_uri,
							mime_type,
							media_type,
							preview_uri,
							mask_media_fg
						 	<cfif len(media_license_id) gt 0>
								,media_license_id
							</cfif>
						) values (
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_uri#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#mime_type#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_type#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#preview_uri#">
						 	<cfif len(mask_media_fg) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#mask_media_fg#">
							<cfelse>
								,0
							</cfif>
							<cfif len(media_license_id) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_license_id#">
							</cfif>
						)
				</cfquery>
				<cfquery name="makeDescriptionRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					insert into media_labels (
						media_id,
						media_label,
						label_value
					) values (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
						'description',
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#">
					)
				</cfquery>
				<cfloop from="1" to="#number_of_relations#" index="n">
					<cfset thisRelationship = #evaluate("relationship__" & n)#>
					<cfset thisRelatedId = #evaluate("related_id__" & n)#>
					<cfset thisTableName=ListLast(thisRelationship," ")>
					<cfif len(#thisRelationship#) gt 0 and len(#thisRelatedId#) gt 0>
						<cfquery name="makeRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							insert into media_relations (
								media_id,
								media_relationship,
								related_primary_key
							) values (
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisRelationship#">,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisRelatedId#">
							)
						</cfquery>
					</cfif>
				</cfloop>
				<cfloop from="1" to="#number_of_labels#" index="n">
					<cfset thisLabel = #evaluate("label__" & n)#>
					<cfset thisLabelValue = #evaluate("label_value__" & n)#>
					<cfif len(#thisLabel#) gt 0 and len(#thisLabelValue#) gt 0>
						<cfquery name="makeRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							insert into media_labels (
								media_id,
								media_label,
								label_value
							) values (
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisLabel#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisLabelValue#">
							)
						</cfquery>
					</cfif>
				</cfloop>
			<cfcatch>
				<cftransaction action="rollback">
				<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ""></cfif>
				<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfheader statusCode="500" statusText="#message#">
				<cfoutput>
					<div class="container">
						<div class="row">
							<div class="alert alert-danger" role="alert">
								<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
								<cfif cfcatch.detail contains "ORA-00001: unique constraint (MCZBASE.U_MEDIA_URI)" >
									<h2>A media record for that resource already exists in MCZbase.</h2>
								<cfelse>
									<h2>Internal Server Error.</h2>
								</cfif>
								<p>#message#</p>
								<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
							</div>
						</div>
					</div>
				</cfoutput>
				<cfabort>
			</cfcatch>
			</cftry>
		</cftransaction>
		<h2>New Media Record Saved</h2>
		<div id='savedLinkDiv'>
			<a href='/media/#media_id#' target='_blank'>Media Details</a>
		</div>
		<cfif len(#thisRelationship#) gt 0 and len(#thisRelatedId#) gt 0>
			<div>Created with relationship: #thisRelationship#</div>
		</cfif>
		<script language='javascript' type='text/javascript'>
			$('##savedLinkDiv').removeClass('ui-widget-content');
		</script>
	</cfoutput>
</cffunction>

<!--- backing for a media autocomplete control --->
<cffunction name="getMediaAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>

	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			select distinct
				media.media_id,
				mime_type,
				media_type,
				substr(media_uri,instr(media_uri,'/',-1)) as filename
				mczbase.get_medialabel(media.media_id,'description') as description
			from 
				media left join media_label on media.media_id = media_label.media_id
			where upper(deacc_number) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(term)#%">
				or media_label.label_value like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#term#%">
			order by media_uri
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.media_id#">
			<cfset row["value"] = "#search.filename#" >
			<cfset row["meta"] = "#search.filename# (#search.mime_type# #search.media_type# #search.description#)" >
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

<!---
Given a habitat and a taxon_name_id, add a row from the taxon_habitat table.
@param taxon_habitat a text string representing a habitat.
@param taxon_name_id the PK of the taxon name for which to add the matching common name.
@return a json structure the status and the id of the new taxon_habitat row.
--->
<cffunction name="newRelationship" access="remote" returntype="any" returnformat="json">
	<cfargument name="media_relationship" type="string" required="yes">
	<cfargument name="media_id" type="numeric" required="yes">
	<cftry>
		<cftransaction>
			<cfquery name="newRelationship" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="newRelationship_result">
				INSERT INTO media_relations 
					(media_relationship, media_id)
				VALUES 
					(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_relationship#">, 
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">)
			</cfquery>
			<cfif newRelationship_result.recordcount eq 1>
				<cfquery name="savePK" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="pkResult">
					select media_relations_id from media_relations
					where ROWIDTOCHAR(rowid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newRelationship_result.GENERATEDKEY#">
				</cfquery>
			<cfelse>
				<cftransaction action="rollback">
				<cfthrow message="Other than one row (#newRelationship_result.recordcount#) would be added, insert canceled and rolled back">
			</cfif>
		</cftransaction>
		<cfset row = StructNew()>
		<cfset row["status"] = "added">
		<cfset row["id"] = "#savePK.media_relations_id#">
		<cfset data[1] = row>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Given a taxon_habitat_id, delete the matching row from the taxon_habitat table.
@param taxon_habitat_id the PK value for the row to remove from the taxon_habitat table.
@return a data structure with status or an http 400 status.
--->
<cffunction name="deleteRelationship" access="remote" returntype="any" returnformat="json">
	<cfargument name="media_relations_id" type="numeric" required="yes">
	<cftry>
		<cftransaction>
			<cfquery name="deleteRelationship" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteHabitat_result">
				DELETE FROM
					media_relations
				WHERE
					media_relations_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_relations_id#">
			</cfquery>
			<cfif deleteHabitat_result.recordcount NEQ 1>
				<cftransaction action="rollback"/>
				<cfthrow message="Other than one row (#deleteRelationship_result.recordcount#) would be deleted.  Delete canceled and rolled back">
			</cfif>
		</cftransaction>
		<cfset row = StructNew()>
		<cfset row["status"] = "deleted">
		<cfset data[1] = row>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Given a taxon_name_id retrieve, as html, an editable list of the habitats for that taxon.
@param taxon_name_id the PK of the taxon name for which to look up habitats.
@param target the id of the element in the DOM, without a leading # selector,
  into which the result is to be placed, used to specify target for reload after successful save.
@return a block of html listing habitats, if any, with edit/delete controls.
--->
<cffunction name="getRelationshipsHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="media_id" type="numeric" required="yes">
	<cfargument name="target" type="string" required="yes">
	<cfthread name="getRelationshipsHtmlThread">
		<cftry>
			<cfquery name="media_relations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select media_relationship, media_relations_id
				from media_relations 
				where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
			</cfquery>
			<cfoutput>
				<cfset i=1>
				<cfif media_relations.recordcount gt 0>
				<table class="table float-left pl-3 py-3 w-100 rounded">
					<thead>
						<tr class="col-12">
							<th class="small text-center col-3">Name</th>
							<th class="small text-center col-7">Value</th>
							<th class="small text-center">Action</th>
						</tr>
					</thead>
					<tbody>
					<cfloop query="media_relations">
						<tr class="mx-0 px-4 my-2 list-style-disc"><td class="mx-0 mb-1">
							<label id="label_media_relations_#i#" value="#media_relationship#" class="">#media_relationship#</label>
							</td>
							<td>value to come</td>
							<td class="text-center">
								<button value="Remove" class="btn btn-xs btn-warning mr-1" onClick=" confirmDialog('Remove <b>#media_relationship#</b> relationship entry from this media record?','Remove relationship?', function() { deleteRelationship(#media_relations_id#,#media_id#,'#target#'); } ); " 
								id="relationshipDeleteButton_#i#">Remove</button>
								<button class="btn btn-xs btn-secondary ml-1">Edit</button></td>
						</tr>
						<cfset i=i+1>
					</cfloop>
					</tr>
				</table>
				<cfelse>
					<table>
						<tr class="px-4 list-style-disc"><td>No Relationships Entered</td></tr>
					</table>
				</cfif>
			</cfoutput>
		<cfcatch>
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getRelationshipsHtmlThread" />
	<cfreturn getRelationshipsHtmlThread.output>
</cffunction>

</cfcomponent>
