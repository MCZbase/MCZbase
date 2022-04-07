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

<cffunction name="loadMediaRelations" returntype="string" access="remote" returnformat="plain">
	<cfargument name="media_id" type="string" required="yes">
	<cfargument name="editMedia" type="string" required="yes">
	<cfthread name="loadMediaRelationsThread">
		<cftry>	
										<!---start of Relationship Block--->
		<div class="col-12 col-sm-12 col-md-12 col-lg-6 col-xl-6 px-0 pr-lg-2 float-left">
			<h2>
				<label for="relationships" class="mb-1 mt-2 px-1 data-entry-label font-weight-bold" style="font-size: 1rem;">Media Relationships | <span class="text-dark small90 font-weight-normal"  onclick="manyCatItemToMedia('#media_id#')">Add multiple "shows cataloged_item" records. Click the buttons to rows and delete row(s).</span></label>
			</h2>
			<div id="relationships" class="col-12 px-0 float-left">
				<cfset i=1>
				<cfif relns.recordcount is 0>
					<!--- seed --->
					<div id="seedMedia" style="display:none">
						<input type="hidden" id="media_relations_id__0" name="media_relations_id__0">
						<cfset d="">
						<select name="relationship__0" id="relationship__0" class="data-entry-select  col-5" size="1"  onchange="pickedRelationship(this.id)">
							<cfloop query="ctmedia_relationship">
								<option <cfif #d# is #media_relationship#> selected="selected" </cfif>value="#media_relationship#">#media_relationship#</option>
							</cfloop>
						</select>
						<input type="text" name="related_value__0" id="related_value__0" class="data-entry-input col-6">
						<input type="hidden" name="related_id__0" id="related_id__0">

					</div><!--- end id seedMedia --->
				</cfif>
				<cfloop query="relns">
					<cfset d=media_relationship>
						<div class="form-row col-12 px-0 mx-0">	
							<input type="hidden" id="media_relations_id__#i#" name="media_relations_id__#i#" value="#media_relations_id#">
							<label for="relationship__#i#"  class="sr-only">Relationship</label>
							<select name="relationship__#i#" id="relationship__#i#" size="1"  onchange="pickedRelationship(this.id)" class="data-entry-select col-3 float-left">
								<cfloop query="ctmedia_relationship">
									<option <cfif #d# is #media_relationship#> selected="selected" </cfif>value="#media_relationship#">#media_relationship#</option>
								</cfloop>
							</select>
							<input type="text" name="related_value__#i#" id="related_value__#i#" value="#summary#" class="data-entry-input col-6 float-left px-1">
							<input type="hidden" name="related_id" id="related_id" value="#related_primary_key#">
							<button id="relationshipDiv__#i#" class="btn btn-warning btn-xs float-left small" onClick="deleteRelationship(#media_relations_id#,#getRelations.media_id#,relationshipDiv__#i#)"> Remove </button>
							<input class="btn btn-secondary btn-xs mx-2 small float-left slide-toggle__#i#" onclick="enable_disable()" type="button"
							value="Edit" style="width: 50px;"></input>
						</div>
						<script type="text/javascript">
							$(document).ready(function enable_disable() {
								$("##relationship__#i#").prop("disabled", true);
								$("##related_value__#i#").prop("disabled", true);
								//var previous;
								$(".slide-toggle__#i#").click(function() {
									previous = this.value;
									if (this.value=="Edit") {
										event.preventDefault();
										this.value = "Revert";
										$("##relationship__#i#").prop("disabled", false);
										$("##related_value__#i#").prop("disabled", false);
										// previous = this.value;
									}
									else {
										this.value = "Edit";
										event.preventDefault();
										$("##relationship__#i#").prop("disabled", true);
										$("##related_value__#i#").prop("disabled", true);
									}
								});
							});
						</script>
					<cfset i=i+1>
				</cfloop>
				<span class="infoLink h5 box-shadow-0 d-block col-3 float-right my-1 pr-4" id="addRelation" onclick="addRelation(#i#,'relationships','addRelation');"> Relationship (+)</span> 	
			</div>
			<div class="col-9 px-0 float-left">
				<button class="btn btn-xs btn-primary float-left" type="button" onClick="newRelationship(#getRelations.media_id#,media_relationship)">Save Relationships Changes</button>
			</div>
			<script>
				(function () {
					var previous;

					$("select").on('focus', function () {
						// Store the current value on focus and on change
						previous = this.value;
					}).change(function() {
						// Do something with the previous value after the change
						alert(previous);

						// Make sure the previous value is updated
						previous = this.value;
					});
				})();

//				function manage(relationships) {
//					var rel = document.getElementById('relSubmit');
//					if (relationships.input.value != '') {
//						rel.disabled = false;
//					} else {
//					rel.disabled = true;
//					}
//				}
			</script>
		</div><!---end col-6--->
		
	<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="loadMediaRelationsThread" />
	<cfreturn loadMediaRelationsThread.output>
</cffunction>
		

<!---
Given a habitat and a taxon_name_id, add a row from the taxon_habitat table.
@param taxon_habitat a text string representing a habitat.
@param taxon_name_id the PK of the taxon name for which to add the matching common name.
@return a json structure the status and the id of the new taxon_habitat row.
--->
<cffunction name="newRelationship" access="remote" returntype="any" returnformat="json">
	<!---<cfargument name="media_relationship" type="string" required="yes">--->
	<cfargument name="media_id" type="numeric" required="yes">
	<cftry>
		<cftransaction>
			<cfquery name="newRelationship" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="newRelationship_result">
				INSERT INTO media_relations 
					(media_relationship, media_id)
				VALUES 
					(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_relations_id#">, 
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">)
			</cfquery>
			<cfif newRelationship_result.recordcount eq 1>
				<cfquery name="savePK" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="pkResult">
					select media_relationship from media_relations
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
<!---<cffunction name="loadMediaRelations" returntype="string" access="remote" returnformat="plain">
	<cfargument name="media_id" type="numeric" required="yes">
	<cfargument name="target" type="string" required="yes">
	<cfthread name="loadMediaRelationsThread">
		<cftry>
			<cfquery name="media_relations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select media_relationship, media_relations_id,
				get_media_relations_string(media_id) as theRValue
				from media_relations 
				where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
			</cfquery>
			<cfoutput>
				<cfset i=1>
				<cfif media_relations.recordcount gt 0>
				<table class="table float-left pl-3 py-3 w-100 rounded">
					<thead>
						<tr class="col-12">
							<th class="small text-center" style="width: 152px;">Name</th>
							<th class="small text-center col-7">Value</th>
							<th class="small text-center" style="width: 105px;">Action</th>
						</tr>
					</thead>
					<tbody>
					<cfloop query="media_relations">
						<tr class="mx-0 px-4 my-2 list-style-disc"><td class="mx-0 mb-1">
							<label id="label_media_relations_#i#" value="#media_relationship#" class="">#media_relationship#</label>
							</td>
							<td>#theRValue#</td>
							<td class="text-center">
								<button value="Remove" class="btn btn-xs float-left btn-warning" onClick=" confirmDialog('Remove <b>#media_relationship#</b> relationship entry from this media record?','Remove relationship?', function() { deleteRelationship(#media_relations_id#,#media_id#,'#target#'); } ); " 
								id="relationshipDeleteButton_#i#">Remove</button>
								<button class="btn btn-xs btn-secondary float-left ml-1">Edit</button></td>
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
	<cfthread action="join" name="loadMediaRelationsThread" />
	<cfreturn loadMediaRelationsThread.output>
</cffunction>--->

			
<cffunction name="showMoreMedia" access="remote" returntype="any" returnformat="json">
	<cfargument name="media_id" type="numeric" required="yes">
	<cftry>
		<cftransaction>
			<cfquery name="spec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select distinct collection_object_id as pk, guid, typestatus, SCIENTIFIC_NAME name,
					decode(continent_ocean, null,'',' '|| continent_ocean) || decode(country, null,'',': '|| country) || decode(state_prov, null, '',': '|| state_prov) || decode(county, null, '',': '|| county)||decode(spec_locality, null,'',': '|| spec_locality) as geography,
					trim(MCZBASE.GET_CHRONOSTRATIGRAPHY(locality_id) || ' ' || MCZBASE.GET_LITHOSTRATIGRAPHY(locality_id)) as geology,
					trim( decode(collectors, null, '',''|| collectors) || decode(field_num, null, '','  '|| field_num) || decode(verbatim_date, null, '','  '|| verbatim_date))as coll,
					specimendetailurl, media_relationship
				from media_relations
					left join flat on related_primary_key = collection_object_id
				where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
						and (media_relations.media_relationship = 'shows cataloged_item')
			</cfquery>
			<cfif len(spec.guid) gt 0>
			<cfquery name="relm3" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="showMoreMedia_result">
				select distinct media.media_id, preview_uri, media.media_uri,
							get_medialabel(media.media_id,'height') height, get_medialabel(media.media_id,'width') width,
							media.mime_type, media.media_type, media.auto_protocol, media.auto_host,
							CASE WHEN MCZBASE.is_mcz_media(media.media_id) = 1 THEN ctmedia_license.display ELSE MCZBASE.get_media_dcrights(media.media_id) END as license,
								ctmedia_license.uri as license_uri,
								mczbase.get_media_credit(media.media_id) as credit,
								MCZBASE.is_media_encumbered(media.media_id) as hideMedia
						from media_relations
							 left join media on media_relations.media_id = media.media_id
							 left join ctmedia_license on media.media_license_id = ctmedia_license.media_license_id
						where (media_relationship = 'shows cataloged_item' or media_relationship = 'shows agent')
							AND related_primary_key = <cfqueryparam value=#spec.pk# CFSQLType="CF_SQL_DECIMAL" >
							AND MCZBASE.is_media_encumbered(media.media_id)  < 1
			</cfquery>
			</cfif>
		</cftransaction>
		<cfset row = StructNew()>
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
			
</cfcomponent>
