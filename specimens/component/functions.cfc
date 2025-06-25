<!---
specimens/component/functions.cfc

Copyright 2019-2025 President and Fellows of Harvard College

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
<cf_rolecheck>
<cfinclude template = "/shared/functionLib.cfm">
<cfinclude template="/media/component/search.cfc" runOnce="true"><!--- ? unused ? remove ? --->
<cfinclude template="/media/component/public.cfc" runOnce="true"><!--- for getMediaBlockHtml --->
<cfinclude template="/specimens/component/public.cfc" runOnce="true"><!--- for getIdentificationsUnthreadedHTML  --->

<cffunction name="updateCatNumber" access="remote" returntype="any" returnformat="json">
	<cfargument name="collection_object_id" type="numeric" required="yes">
	<cfargument name="cat_num" type="string" required="yes">
	<cfargument name="collection_id" type="string" required="yes">
	<cfset variables.collection_object_id = arguments.collection_object_id>
	<cfset variables.cat_num = arguments.cat_num>
	<cfset variables.collection_id = arguments.collection_id>
	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfif isdefined("session.roles") AND listfindnocase(session.roles,"manage_collections")>
				<cfquery name="updateCatNum" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateCatNum_result">
					UPDATE cataloged_item 
					SET
						cat_num = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.cat_num#">,
						collection_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.collection_id#">
					WHERE
						collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">
				</cfquery>
				<cfif updateCatNum_result.recordcount EQ 1>
					<cftransaction action="commit">
					<cfquery name="getGuid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT 
						 	collection.institution_acronym || ':' || cataloged_item.collection_cde || ':' || cataloged_item.cat_num  as guid,
							cataloged_item.cat_num,
							cataloged_item.collection_id,
							cataloged_item.collection_cde,
							collection.collection
						FROM
							cataloged_item
							join collection on cataloged_item.collection_id = collection.collection_id
						WHERE
							collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">
					</cfquery>
					<!--- update the guid in the flat table so that a redirect will work before updateFlat runs --->
					<cfquery name="setGuidInFlat" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE flat
						SET
							guid = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getGuid.guid#">,
							collection_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getGuid.collection_id#">,
							collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getGuid.collection_cde#">,
							collection = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getGuid.collection#">
						WHERE
							collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">
					</cfquery>
					<cfset row = StructNew()>
					<cfset row["status"] = "updated">
					<cfset row["id"] = "#reReplace('[^0-9]',variables.collection_object_id,'')#">
					<cfset row["guid"] = getGuid.guid>
					<cfset data[1] = row>
				<cfelse>
					<cfthrow message="Error other than one row affected.">
				</cfif>
			<cfelse>
				<cfthrow message="You do not have permission to change the catalog number.">
			</cfif>
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn serializeJSON(data)>
</cffunction>

<cffunction name="updateAccn" access="remote" returntype="any" returnformat="json">
	<cfargument name="collection_object_id" type="numeric" required="yes">
	<cfargument name="accession_transaction_id" type="numeric" required="yes">
	<cfset variables.collection_object_id = arguments.collection_object_id>
	<cfset variables.accession_transaction_id = arguments.accession_transaction_id>
	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfif isdefined("session.roles") AND listfindnocase(session.roles,"manage_transactions")>
				<cfquery name="upIns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cataloged_item 
					SET
						accn_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.accession_transaction_id#">
					WHERE
						collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">
				</cfquery>
				<cftransaction action="commit">
				<cfset row = StructNew()>
				<cfset row["status"] = "updated">
				<cfset row["id"] = "#accession_transaction_id#">
				<cfset data[1] = row>
			<cfelse>
				<cfthrow message="You do not have permission to change the accession.">
			</cfif>
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn serializeJSON(data)>
</cffunction>

<!--- updateCondition update the condition on a part identified by the part's collection object id 
 @param part_id the collection_object_id for the part to update
 @param condition the new condition to update the part to 
 @return a json structure containing the part_id and a message, with "success" as the value of the message on a successful update.
--->
<cffunction name="updateCondition" access="remote" returntype="query">
	<cfargument name="part_id" type="numeric" required="yes">
	<cfargument name="condition" type="string" required="yes">

	<cfset variables.part_id = arguments.part_id>
	<cfset variables.condition = arguments.condition>

	<cftry>
		<cftransaction>
			<cfquery name="upIns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update coll_object 
				set
					condition = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.condition#">
				where
					COLLECTION_OBJECT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.part_id#">
			</cfquery>
		</cftransaction>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#variables.part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "success", 1)>
		<cfcatch>
			<cfset result = querynew("PART_ID,MESSAGE")>
			<cfset temp = queryaddrow(result,1)>
			<cfset temp = QuerySetCell(result, "part_id", "#variables.part_id#", 1)>
			<cfset temp = QuerySetCell(result, "message", "A query error occured: #cfcatch.Message# #cfcatch.Detail#", 1)>
		</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>

<!--- saveRemarks function to update the remarks for a cataloged item.
 @param collection_object_id the collection_object_id for the cataloged item for which to update the remarks
 @param coll_object_remarks the remarks to update
 @param disposition_remarks the disposition remarks to update
 @param habitat the habitat to update
 @param associated_species the associated species to update
 @return a json structure with status=updated, or an http 500 response.
--->
<cffunction name="saveRemarks" returntype="any" access="remote" returnformat="json">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="coll_object_remarks" type="string" required="yes">
	<cfargument name="disposition_remarks" type="string" required="yes">
	<cfargument name="habitat" type="string" required="yes">
	<cfargument name="associated_species" type="string" required="yes">

	<cfset variables.collection_object_id = arguments.collection_object_id>
	<cfset variables.coll_object_remarks = arguments.coll_object_remarks>
	<cfset variables.disposition_remarks = arguments.disposition_remarks>
	<cfset variables.habitat = arguments.habitat>
	<cfset variables.associated_species = arguments.associated_species>

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<!--- check if a remarks record exists, if not create one --->
			<cfquery name="checkRemarks" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT 
					count(collection_object_id) as ct
				FROM
					coll_object_remark
				WHERE
					collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">
			</cfquery>
			<cfif checkRemarks.ct EQ 0>
				<!--- create a new remarks record --->
				<cfquery name="saveRemarksQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="saveRemarksQuery_result">
					INSERT INTO coll_object_remark (
						collection_object_id,
						coll_object_remarks,
						disposition_remarks,
						habitat,
						associated_species
					) VALUES (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.coll_object_remarks#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.disposition_remarks#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.habitat#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.associated_species#">
					)
				</cfquery>
			<cfelse>
				<!--- update the (sole) existing remarks record --->
				<cfquery name="saveRemarksQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="saveRemarksQuery_result">
					UPDATE coll_object_remark
					SET
						coll_object_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.coll_object_remarks#">,
						disposition_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.disposition_remarks#">,
						habitat = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.habitat#">,
						associated_species = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.associated_species#">
					WHERE
						collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">
				</cfquery>
			</cfif>
			<cfif saveRemarksQuery_result.recordcount EQ 1>
				<cftransaction action="commit"/>
				<cfset row = StructNew()>
				<cfset row["status"] = "updated">
				<cfset row["id"] = "#variables.collection_object_id#">
				<cfset data[1] = row>
			<cfelse>
				<cfthrow message="Error other than one row affected.">
			</cfif>
		<cfcatch>
			<cftransaction action="rollback"/>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn serializeJSON(data)>
</cffunction>

<!--- getEditRemarksHTML obtain a block of html to populate an remarks editor dialog for a specimen.
 @param collection_object_id the collection_object_id for the cataloged item for which to obtain the remarks
	editor dialog.
 @return html for editing remarks for the specified cataloged item.
--->
<cffunction name="getEditRemarksHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfset variables.collection_object_id = arguments.collection_object_id >

	<!---
  CREATE TABLE "COLL_OBJECT_REMARK" 
   (	"COLLECTION_OBJECT_ID" NUMBER NOT NULL ENABLE, 
	"DISPOSITION_REMARKS" VARCHAR2(4000 CHAR), 
	"COLL_OBJECT_REMARKS" VARCHAR2(4000 CHAR), 
	"HABITAT" VARCHAR2(4000 CHAR), 
	"ASSOCIATED_SPECIES" VARCHAR2(4000 CHAR), 
	--->
	<cfthread name="getEditRemarksThread"> 
		<cfoutput>
			<cftry>
				<cfquery name="getRemarks" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT 
						coll_object_remarks,
						disposition_remarks,
						habitat,
						associated_species
					FROM
						coll_object_remark
					WHERE
						collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">
				</cfquery>
				<!--- should be just one record per collection_object_id --->
				<div class="container-fluid">
					<h1 class="h3 px-1">Remarks</h1>
					<form name="formEditRemarks" id="formEditRemarks">
						<div class="form-row row">
							<input type="hidden" name="collection_object_id" id="collection_object_id" value="#variables.collection_object_id#">
							<cfif getRemarks.recordcount EQ 0>
								<cfset remarksText = "">
								<cfset dispositionText = "">
								<cfset habitatText = "">
								<cfset associatedText = "">
							<cfelse>
								<cfset remarksText = getRemarks.coll_object_remarks>
								<cfset dispositionText = getRemarks.disposition_remarks>
								<cfset habitatText = getRemarks.habitat>
								<cfset associatedText = getRemarks.associated_species>
							</cfif>
							<div class="col-12">
								<label for="coll_object_remarks">Remarks (<span id='length_coll_object_remarks'></span>):</label>
								<textarea name="coll_object_remarks" id="coll_object_remarks" rows="2" 
									onkeyup="countCharsLeft('coll_object_remarks', 4000, 'length_coll_object_remarks');"
									class="form-control form-control-sm w-100 autogrow mb-1">#remarksText#</textarea>
							</div>
							<div class="col-12">
								<label for="disposition_remarks">Disposition Remarks (<span id='length_disposition_remarks'></span>):</label>
								<textarea name="disposition_remarks" id="disposition_remarks" rows="2" 
									onkeyup="countCharsLeft('disposition_remarks', 4000, 'length_disposition_remarks');"
									class="form-control form-control-sm w-100 autogrow mb-1">#dispositionText#</textarea>
							</div>
							<div class="col-12">
								<label for="habitat">Microhabitat (<span id='length_habitat'></span>):</label>
								<textarea name="habitat" id="habitat" rows="2" 
									onkeyup="countCharsLeft('habitat', 4000, 'length_habitat');"
									class="form-control form-control-sm w-100 autogrow mb-1">#habitatText#</textarea>
							</div>
							<div class="col-12">
								<label for="associated_species">Associated Species (<span id='length_associated_species'></span>):</label>
								<textarea name="associated_species" id="associated_species" rows="2" 
									onkeyup="countCharsLeft('associated_species', 4000, 'length_associated_species');"
									class="form-control form-control-sm w-100 autogrow mb-1">#associatedText#</textarea>
							</div>
							<div class="col-12 col-md-3 mt-1">
								<input type="button" value="Save" class="btn btn-xs btn-primary" id="saveRemarksButton" onClick="handleSaveRemarks();">
							</div>
							<div class="col-12 col-md-9 mt-md-1">
								<output id="saveRemarksStatus" class="pt-1"></output>
							</div>
						</div>
					</form>
					<script>
						// Make all textareas with autogrow class be bound to the autogrow function on key up
						$(document).ready(function() { 
							$("textarea.autogrow").keyup(autogrow);  
							$('textarea.autogrow').keyup();
						});
						function handleSaveRemarks() {
							var collection_object_id = $("##collection_object_id").val();
							var coll_object_remarks = $("##coll_object_remarks").val();
							var disposition_remarks = $("##disposition_remarks").val();
							var habitat = $("##habitat").val();
							var associated_species = $("##associated_species").val();
							saveRemarks(collection_object_id,coll_object_remarks,disposition_remarks,habitat,associated_species,reloadRemarks,"saveRemarksStatus");
						};
					</script>
				</div>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getEditRemarksThread" />
	<cfreturn getEditRemarksThread.output>
</cffunction>

<!---getEditMediaHTML obtain a block of html to populate an media editor dialog for a specimen.
 @param collection_object_id the collection_object_id for the cataloged item for which to obtain the identification
	editor dialog.
 @return html for editing identifications for the specified cataloged item. 
--->
<cffunction name="getEditMediaHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfif isdefined("arguments.collection_object_id")>
		<cfset variables.collection_object_id = arguments.collection_object_id>
	<cfelse>
		<cfset variables.collection_object_id = "">
	</cfif>

	<cfthread name="getEditMediaThread"> 
		<cfoutput>
			<cftry>
				<cfquery name="getGuid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT 
						guid
					FROM
						flat
					WHERE
						flat.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
				</cfquery>
				<cfquery name="ctmedia_relationship" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT media_relationship 
					FROM ctmedia_relationship
					WHERE media_relationship like '% cataloged_item'
					ORDER by media_relationship
				</cfquery>
				<cfquery name="ctmedia_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT media_type 
					FROM ctmedia_type
					ORDER BY media_type
				</cfquery>
				<div class="container-fluid">
					<div class="row">
						<div class="col-12 float-left">
							<h1 class="h3 px-1"> 
								Edit Media 
								<a href="javascript:void(0);" onClick="getMCZDocs('media')"><i class="fa fa-info-circle"></i></a> 
								<a href="/media.cfm?action=newMedia" target="_blank" class="btn btn-secondary float-right">Add New Media Record</a>
							</h1>
							<!--- link existing media to cataloged item --->
							<div class="add-form float-left">
								<div class="add-form-header pt-1 px-2 col-12 float-left">
									<h2 class="h3 my-0 px-1 pb-1">Relate existing media to #getGuid.guid#</h2>
								</div>
								<div class="card-body">
									<!--- form to add current media to cataloged item --->
									<form name="formLinkMedia" id="formLinkMedia">
										<div class="form-row">	
											<div class="col-12">
												<label for="underscore_collection_id">Filename of Media to link:</label>
												<input type="hidden" name="media_id" id="media_id">
												<input type="text" name="media_uri" id="media_uri" class="data-entry-input">
											</div>
											<div class="col-12 col-md-3">
												<label for="media_type">Media Type</label>
												<select name="media_type" id="media_type" size="1" class="reqdClr w-100" required>
													<cfloop query="ctmedia_type">
														<cfset selected="">
														<cfif #ctmedia_type.media_type# EQ "image">
															<cfset selected="selected='selected'">
														</cfif>
														<option value="#ctmedia_type.media_type#" #selected#>#ctmedia_type.media_type#</option>
													</cfloop>
												</select>
											</div>
											<div class="col-12 col-md-3">
												<label for="relationship_type">Type of Relationship:</label>
												<select name="relationship_type" id="relationship_type" size="1" class="reqdClr w-100" required>
													<cfloop query="ctmedia_relationship">
														<cfset selected="">
														<cfif #ctmedia_relationship.media_relationship# EQ "shows cataloged_item">
															<cfset selected="selected='selected'">
														</cfif>
														<option value="#ctmedia_relationship.media_relationship#" #selected#>#ctmedia_relationship.media_relationship#</option>
													</cfloop>
												</select>
											</div>
											<div class="col-12 col-md-1">
												<label for="addMediaButton" class="data-entry-label">&nbsp;</label>
												<input type="button" value="Add" class="btn btn-xs btn-primary" id="addMediaButton"
													onClick="handleAddMedia();">
											</div>
										</div>
									</form>
									<script>
										jQuery(document).ready(function() {
											makeRichMediaPickerControlMeta2("media_uri","media_id","media_type"); 
										});
										// @deprecated, reloadMediaDialogList reloads just media list in the dialog, 
										// rest of page is reloaded with reloadSpecimenMedia on dialog close.
										function reloadMediaDialogAndPage() { 
											// reload all media elements in the dialog and the page.
											// reloadSpecimenMedia internally checks if accordionMedia exists and reloads the page if it does not.
											reloadSpecimenMedia();
											if ($("##accordionMedia").length) {
												// wrap in check for accordionMedia to avoid error dialogs appearing before page reload.
												reloadLedger();
												reloadDialogMediaList();
											}
										}
										function reloadMediaDialogList() {
											// reload just the media list in the dialog
											jQuery.ajax({
												url: "/specimens/component/functions.cfc",
												data : {
													method : "getEditableMediaListHtmlUnthreaded",
													collection_object_id: "#variables.collection_object_id#"
												},
												success: function (result) {
													if ($("##mediaDialogListBody").length) {
														$("##mediaDialogListBody").html(result);
													} else {
														console.log("mediaDialogListBody " + " not found");
													}
												},
												error: function (jqXHR, textStatus, error) {
													handleFail(jqXHR,textStatus,error,"loading specimen media list for editing");
												},
												dataType: "html"
											});
										}
										function handleAddMedia() {
											var media_id = $("##media_id").val();
											var collection_object_id = "#variables.collection_object_id#";
											var relationship_type = $("##relationship_type").val();
											linkMedia(collection_object_id,media_id,relationship_type,reloadMediaDialogList);
										}
									</script>
								</div><!--- end card-body for add form --->
							</div><!--- end add-form for link media --->
							<!--- remove relationships to existing media from cataloged item --->
							<div class="col-12 col-lg-12 float-left mb-4 px-0 border">
								<div class="bg-light p-0">
									<h2 class="my-0 py-1 text-dark">
										<span class="h3 px-2">Edit existing links to media</span> 
									</h2>
									</div>
									<div id="mediaDialogListBody" style="overflow-y: auto;" > 
										<cfset mediaBlock= getEditableMediaListHtmlUnthreaded(collection_object_id="#variables.collection_object_id#")>
									</div>
								</div>
							</div>
						</div>
					</div>
				</div>
				<cfcatch>
					<cfset error_message = cfcatchToErrorMessage(cfcatch)>
					<cfset function_called = "#GetFunctionCalledName()#">
					<h2 class="h3">Error in #function_called#:</h2>
					<div>#error_message#</div>
				</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getEditMediaThread" />
	<cfreturn getEditMediaThread.output>
</cffunction>

<!--- function getEditableMediaListHtmlUnthreaded get an html list of media objects related to a cataloged item for editing 
  expects to be called from a thread.
 @param collection_object_id the collection_object_id for the cataloged item for which to obtain the media list.
 @return html for editing media for the specified cataloged item.
--->
<cffunction name="getEditableMediaListHTMLUnthreaded" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfset variables.collection_object_id = arguments.collection_object_id>

	<cfoutput>
		<cfquery name="ctmedia_relationship" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT media_relationship 
			FROM ctmedia_relationship
			WHERE media_relationship like '% cataloged_item'
				and media_relationship not like 'ledger %'
			ORDER by media_relationship
		</cfquery>
		<cfquery name="getMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT distinct
				media_relations.media_relations_id,
				media_relations.media_relationship,
				media.media_id,
				media.media_uri,
				media.auto_filename,
				media.preview_uri,
				media.mime_type,
				media.media_type,
				decode(media.mask_media_fg,0,'public',1,'hidden',null,'public','error') as mask_media,
				mczbase.get_media_descriptor(media.media_id) as media_descriptor,
				mczbase.get_media_title(media.media_id) as media_title,
				mczbase.get_medialabel(media.media_id,'aspect') as aspect,
				mczbase.get_medialabel(media.media_id,'subject') as subject,
				media_relations.related_primary_key as collection_object_id
			FROM
				media_relations 
				join media on media_relations.media_id = media.media_id
			WHERE
				media_relations.related_primary_key = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
				AND (
					media_relations.media_relationship = 'shows cataloged_item'
					OR media_relations.media_relationship = 'documents cataloged_item'
				)
		</cfquery>
		<!--- TODO: include media with specimen_part relationships --->
		<cfif getMedia.recordcount EQ 0>
			<div class="row mx-0">
				<div class="col-12">
					<h3 class="h3 text-danger">No media found for this cataloged item.</h3>
				</div>
			</div>
		<cfelse>
			<cfset variables.mpos = 1>
			<cfloop query="getMedia">
				<div class="row mx-0 border-top border-bottom py-1">
					<div class="col-12 col-md-3 float-left">
						<cfset mediaBlock= getMediaBlockHtmlUnthreaded(media_id="#getMedia.media_id#",displayAs="thumb",captionAs="textNone")>
						<div class="text-center">
							#getMedia.auto_filename#
						</div>
					</div>
					<div class="col-12 col-md-3">
						<!--- metadata for media record --->
						<ul>
							<li>#getMedia.subject#</li>
							<cfif getMedia.aspect is not "">
								<li>#getMedia.aspect#</li>
							</cfif>
							<li>#getMedia.mime_type#</li>
							<li>#getMedia.mask_media#</li>
							<li>
								(<a href="/media.cfm?action=edit&media_id=#getMedia.media_id#" target="_blank" >Edit</a>)
							</li>
					</div>
					<div class="col-12 col-md-3">
						<!--- form to add current media to cataloged item --->
						<form name="formChangeLink_#variables.mpos#" id="formChangeLink_#variables.mpos#">
							<div class="form-row">	
								<div class="col-12">
									<label for="relationship_type_#variables.mpos#">Relationship (#getMedia.media_relationship#):</label>
								</div>
								<div class="col-12">
									<input type="hidden" name="media_id" id="media_id_#variables.mpos#">
									<!--- Change relationship type (between shows and documents cataloged_item) --->
									<select name="relationship_type" id="relationship_type_#variables.mpos#" size="1" class="reqdClr w-100" required>
										<cfloop query="ctmedia_relationship">
											<cfset selected="">
											<cfif #ctmedia_relationship.media_relationship# EQ getMedia.media_relationship>
												<cfset selected="selected='selected'">
											</cfif>
											<option value="#ctmedia_relationship.media_relationship#" #selected#>#ctmedia_relationship.media_relationship#</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12">
									<input type="button" value="Change" class="btn btn-xs btn-primary" id="changeMediaButton_#variables.mpos#"
										onClick="handleChangeCIMediaRelationshipType($('##relationship_type_#variables.mpos#').val(),'#getMedia.media_id#','#getMedia.collection_object_id#','#getMedia.media_relations_id#',reloadMediaDialogList);">
								</div>
							</div>
					</div>
					<div class="col-12 col-md-3">
						<button class="btn btn-xs btn-primary" onClick="removeMediaRelationship('#getMedia.media_relations_id#',reloadMediaDialogList);">Remove</button>
					</div>
				</div>
				<cfset variables.mpos= variables.mpos + 1>
			</cfloop>
		</cfif>
	</cfoutput>
</cffunction>

<!--- 
 * changeMediaRelationshipType change the type of a media relationship between a cataloged item and a media record
 *
 * @param media_relations_id the media_relations_id for the media relationship to change.
 * @param relationship_type the new relationship type to change the media relationship to.
 * @param collection_object_id the collection_object_id as a crosscheck
 * @param media_id the media_id for the media as a crossheck.
 * @return a json structure with status=removed, or an http 500 response.
--->
<cffunction name="changeMediaRelationshipType" returntype="any" access="remote" returnformat="json">
	<cfargument name="media_id" type="string" required="yes">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="relationship_type" type="string" required="yes">
	<cfargument name="media_relations_id" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>	
			<cfquery name="changeMediaRel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="changeMediaRel_result">
				UPDATE media_relations
				SET
					media_relationship = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.relationship_type#">
				WHERE
					media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.media_id#">
					AND related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">
					AND media_relations_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.media_relations_id#">
			</cfquery>
			<cfif changeMediaRel_result.recordcount EQ 1>
				<cftransaction action="commit"/>
				<cfset row = StructNew()>
				<cfset row["status"] = "changed">
				<cfset row["id"] = "#media_relations_id#">
				<cfset data[1] = row>
			<cfelse>
				<cfthrow message="Error other than one row affected.">
			</cfif>
		<cfcatch>
			<cftransaction action="rollback"/>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- function addMediaToCatItem relate a media record to cataloged item
  @param collection_object_id the collection_object_id for the cataloged item to which to add the media.
  @param media_id the media_id for the media to add to the cataloged item.
  @param relationship_type the type of relationship to add between the media and the cataloged item.
  @return a json structure with status=added, or an http 500 response.
--->
<cffunction name="addMediaToCatItem" returntype="any" access="remote" returnformat="json">
	<cfargument name="media_id" type="string" required="yes">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="relationship_type" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>	
			<cfquery name="checkMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT media_id 
				FROM media_relations 
				WHERE media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.media_id#">
					AND related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">
					AND media_relationship = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.relationship_type#">
			</cfquery>
			<cfif checkMedia.recordcount GT 0>
				<cfthrow message="This media record is already linked to this cataloged item with this relationship.">
			</cfif>
			<cfquery name="addMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="addMedia_result">
				INSERT INTO media_relations (
					media_id, 
					related_primary_key,
					media_relationship,
					created_by_agent_id
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.media_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.relationship_type#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.myAgentId#">
				)
			</cfquery>
			<cfif addMedia_result.recordcount EQ 1>
				<cftransaction action="commit"/>
				<cfset row = StructNew()>
				<cfset row["status"] = "added">
				<cfset row["id"] = "#media_id#">
				<cfset data[1] = row>
			<cfelse>
				<cfthrow message="Error other than one row affected.">
			</cfif>
		<cfcatch>
			<cftransaction action="rollback"/>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- getEditIdentificationsHTML Threaded method to obtain a block of html to populate an identifications editor dialog for a specimen.
 @param collection_object_id the collection_object_id for the collection object for which to obtain the identifications
	editor dialog.
 @return html for editing identifications for the specified collection object.
--->
<cffunction name="getEditIdentificationsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfset variables.collection_object_id = arguments.collection_object_id>

	<cfthread name="getIdentificationsThread">
		<cftry>
			<!--- Load available formulas --->
			<cfquery name="ctFormula" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT taxa_formula, description
				FROM cttaxa_formula
				ORDER BY taxa_formula
			</cfquery>
			<cfquery name="ctNature" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT nature_of_id, description 
				FROM ctnature_of_id 
				ORDER BY nature_of_id
			</cfquery>
			<!--- Determine what this identification is on --->
			<cfquery name="getDetermined" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" >
				SELECT coll_object_type
				FROM coll_object
				WHERE 
					collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECiMAL" value="#variables.collection_object_id#">
			</cfquery>
			<cfif getDetermined.recordcount EQ 0>
				<cfthrow message="No such collection_object_id.">
			</cfif>
			<cfset target = "">
			<cfif getDetermined.coll_object_type EQ "CI">
				<cfquery name="getTarget" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" >
					SELECT guid
					FROM FLAT
					WHERE 
						collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECiMAL" value="#variables.collection_object_id#">
				</cfquery>
				<cfset target = getTarget.guid>
			<cfelseif getDetermined.coll_object_type EQ "SP">
				<cfquery name="getTarget" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" >
					SELECT guid, specimen_part.part_name, specimen_part.preserve_method
					FROM 
						specimen_part
						join FLAT on specimen_part.derived_from_cat_item = flat.collection_object_id 
					WHERE 
						specimen_part.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECiMAL" value="#variables.collection_object_id#">
				</cfquery>
				<cfset target = "#getTarget.guid# #getTarget.part_name# (#getTarget.preserve_method#)">
			</cfif>
			<cfif len(target) GT 0>
				<cfset target = " to #target#">
			</cfif>
			<cfoutput>
				<div id="identificationHTML">
					<div class="container-fluid">
						<div class="row">
							<div class="col-12 float-left">
								<cfif getDetermined.coll_object_type EQ "CI" OR getDetermined.coll_object_type EQ "SP">
									<!--- identifiable, thus allow add identifications --->
									<div class="add-form float-left">
										<div class="add-form-header pt-1 px-2 col-12 float-left">
											<h2 class="h3 my-0 px-1 pb-1">Add Identification#target#</h2>
										</div>
										<div class="card-body">
											<form name="addIdentificationForm" id="addIdentificationForm">
												<input type="hidden" name="collection_object_id" value="#variables.collection_object_id#">
												<input type="hidden" name="method" value="addIdentification">
												<input type="hidden" name="returnformat" value="json">
												<div class="form-row">
													<div class="col-12 col-md-2">
														<label for="taxa_formula" class="data-entry-label">ID Formula:</label>
														<select name="taxa_formula" id="taxa_formula" class="data-entry-input reqdClr" onchange="updateTaxonBVisibility();" required>
															<cfloop query="ctFormula">
																<option value="#ctFormula.taxa_formula#">#ctFormula.taxa_formula#</option>
															</cfloop>
														</select>
													</div>
													<div class="col-12 col-md-5">
														<label for="taxona" class="data-entry-label">Taxon A:</label>
														<input type="text" name="taxona" id="taxona" class="data-entry-input reqdClr" required>
														<input type="hidden" name="taxona_id" id="taxona_id">
														<script>
															// Initialize taxon autocomplete
															$(document).ready(function() {
																makeScientificNameAutocompleteMeta("taxona","taxona_id");
															});
														</script>
													</div>
													<div class="col-12 col-md-5">
														<div class="form-row" id="taxonb_row" style="display:none;">
															<label for="taxonb" class="data-entry-label">Taxon B:</label>
															<input type="text" name="taxonb" id="taxonb" class="data-entry-input">
															<input type="hidden" name="taxonb_id" id="taxonb_id">
															<script>
																// Initialize taxon B autocomplete
																$(document).ready(function() {
																	makeScientificNameAutocompleteMeta("taxonb","taxonb_id");
																});
															</script>
														</div>
													</div>
													<div class="col-12 col-md-3">
														<label for="made_date" class="data-entry-label">Date Identified:</label>
														<input type="text" name="made_date" id="made_date" class="data-entry-input">
														<script>
															// Initialize datepicker
															$(document).ready(function() {
																$("##made_date").datepicker({
																	dateFormat: "yy-mm-dd",
																	changeMonth: true,
																	changeYear: true,
																	showButtonPanel: true
																});
															});
														</script>
													</div>
													<div class="col-12 col-md-3">
														<label for="nature_of_id" class="data-entry-label">Nature of ID:</label>
														<select name="nature_of_id" id="nature_of_id" class="data-entry-select reqdClr" required>
															<option></option>
															<cfloop query="ctNature">
																<option value="#ctNature.nature_of_id#">#ctNature.nature_of_id# #ctNature.description#</option>
															</cfloop>
														</select>
													</div>
													<div class="col-12 col-md-6">
														<!--- publication autocomplete --->
														<label for="publication" class="data-entry-label">Sensu:</label>
														<input type="text" name="sensu" id="publication" class="data-entry-input">
														<input type="hidden" name="publication_id" id="publication_id">
														<script>
															// Initialize publication autocomplete
															$(document).ready(function() {
																makePublicationAutocompleteMeta("publication","publication_id");
															});
														</script>
													</div>
													<div class="col-12 col-md-10">
														<label for="identification_remarks" class="data-entry-label">Remarks:</label>
														<input type="text" name="identification_remarks" id="identification_remarks" class="data-entry-input">
													</div>
													<div class="col-12 col-md-2">
														<input type="hidden" name="accepted_id_fg" id="accepted_id_fg" value="1">
														<input type="hidden" name="stored_as_fg" id="stored_as_fg" value="0">
														<!--- select to indicate if this identification is to be created as the current identification, as a previous identification, or previous identification which is the stored as name --->
														<label for="id_state" class="data-entry-label">Id is:</label>
														<select name="id_state" id="id_state" class="data-entry-select reqdClr" required>
															<option value="current">Current</option>
															<option value="previous">Previous</option>
															<option value="stored_as">Previous: Stored As</option>
														</select>
														<!--- add event listener to set values of accepted_id_fg and stored_as_fg based on id_state selection --->
														<script>
															$(document).ready(function() {
																$("##id_state").change(function() {
																	var state = $(this).val();
																	if (state === "current") {
																		$("##accepted_id_fg").val("1");
																		$("##stored_as_fg").val("0");
																	} else if (state === "previous") {
																		$("##accepted_id_fg").val("0");
																		$("##stored_as_fg").val("0");
																	} else if (state === "stored_as") {
																		$("##accepted_id_fg").val("0");
																		$("##stored_as_fg").val("1");
																	}
																});
															});
														</script>
													</div>
													<div class="col-12">
														<div class="form-row" id="addIdNewDetsFormRow">
															<div class="col-12 col-md-3">
																<!--- autocomplete for a determiner --->
																<label for="determiner" class="data-entry-label">Determiner:</label>
																<input type="text" name="determiner" id="determiner" class="data-entry-input reqdClr" required>
																<input type="hidden" name="determiner_id" id="determiner_id_1">
																<input type="hidden" name="determiner_count" id="determiner_count" value="1">
																<script>
																	// Initialize determiner autocomplete
																	$(document).ready(function() {
																		makeAgentAutocompleteMeta("determiner","determiner_id_1");
																	});
																</script>
																<!--- button to add another set of determiner controls --->
																<button type="button" class="btn btn-xs btn-secondary" id="addDeterminerButton"
																		 onClick="addDeterminerControl();">Add Determiner</button>
																<script>
																	function addDeterminerControl() {
																		// get the number of current determiner controls
																		var currentCount = parseInt($("##determiner_count").val());
																		// Increment the count
																		currentCount++;
																		// Add a new determiner control
																		var newControl = '<div class="col-12 col-md-3" id="det_div_'+currentCount+'">';
																		newControl += '<label id="det_label_'+currentCount+'" for="det'+currentCount+'"  class="data-entry-label"> Determiner '+currentCount + ':</label>';
																		newControl += '<input type="text" name="det'+currentCount+'" id="det'+currentCount+'"  class="data-entry-input">';
																		newControl += '<input type="hidden" name="determiner_id'+currentCount+'" id="determiner_id_'+currentCount+'" value="" >';
																		// button to remove this determiner control
																		newControl += '<button type="button" class="btn btn-xs btn-secondary" id="removeDet'+currentCount+'" onClick="removeDeterminerControl('+currentCount+');">Remove</button>';
																		newControl += '</div>';
																		$("##addIdNewDetsFormRow").append(newControl);
																		makeAgentAutocompleteMeta("det"+currentCount,"determiner_id_"+currentCount);
																		$("##determiner_count").val(currentCount);
																	}
																	function removeDeterminerControl(index) {
																		// Remove the determiner control pair specified by index
																		$("##det"+index).remove();
																		$("##determiner_id_"+index).remove();
																		$("##removeDet"+index).remove();
																		$("##det_label_"+index).remove();
																		$("##det_div_"+index).remove();
																	}
																</script>
																<!--- hidden input to store determiner IDs for multiple determiner support --->
																<input type="hidden" name="determiner_ids" id="determiner_ids" class="data-entry-input">
															</div>
														</div>
													</div>
													<div class="col-12">
														<input type="button" value="Add" class="btn btn-xs btn-primary" id="addIdButton"
																	 onClick="handleAddIdentification();">
														<output id="addIdStatus" class="pt-1"></output>
													</div>
												</div>
											</form>
											<script>
												// Show/hide Taxon B row based on formula (contains B)
												function updateTaxonBVisibility() {
													var formula = document.getElementById('taxa_formula').value;
													if (formula.includes('B')) {
														document.getElementById('taxonb_row').style.display = '';
													} else {
														document.getElementById('taxonb_row').style.display = 'none';
														document.getElementById('taxonb').value = '';
														document.getElementById('taxonb_id').value = '';
													}
												}
												// Init on load
												document.addEventListener('DOMContentLoaded', function() {
													updateTaxonBVisibility();
												});
	
												function reloadIdentificationsDialogAndPage() {
													reloadIdentifications();
													loadIdentificationsList("#variables.collection_object_id#", "identificationDialogList","true");
												}
												function handleAddIdentification() {
													// iterate through all of the determiner_id controls and add their values to a comma separated list in determiner_ids
													var determinerIds = [];
													$("input[id^='determiner_id_']").each(function() {
														var id = $(this).val();
														if (id) {
															determinerIds.push(id);
														}
													});
													console.log(determinerIds);
													// set the determiner_ids hidden input to the comma separated list
													$("##determiner_ids").val(determinerIds.join(','));
													setFeedbackControlState("addIdStatus","saving")
													var form = $('##addIdentificationForm');
													var data = form.serialize();
													$.ajax({
														url: '/specimens/component/functions.cfc',
														data: data,
														type: 'POST',
														success: function() {
															setFeedbackControlState("addIdStatus","saved")
															reloadIdentificationsDialogAndPage();
														}
														,error: function(jqXHR, textStatus, errorThrown) {
															setFeedbackControlState("addIdStatus","error")
															handleFail(jqXHR, textStatus, errorThrown, "adding identification");
														}
													});
												}
											</script>
										</div>
									</div>
								</cfif>
								<div id="identificationDialogList" class="col-12 float-left mt-4 mb-4 px-0">
									<cfset idList = getIdentificationsUnthreadedHTML(collection_object_id = variables.collection_object_id, editable=true)>
								</div>
							</div>
						</div>
					</div>
				</div>
			</cfoutput>
			<cfcatch>
				<cfoutput>
					<p class="mt-2 text-danger">Error: #cfcatch.type# #cfcatch.message# #cfcatch.detail#</p>
				</cfoutput>
			</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getIdentificationsThread" />
	<cfreturn getIdentificationsThread.output>
</cffunction>

<!--- addIdentification add an identification to a collection object.
	@param collection_object_id the collection_object_id for the collection object to which to add the identification.
	@param taxa_formula the taxa formula to use for the identification.
	@param taxona the taxon A name to use for the identification.
	@param taxona_id the taxon A ID to use for the identification.
	@param taxonb the taxon B name to use for the identification (optional).
	@param taxonb_id the taxon B ID to use for the identification (optional).
	@param made_date the date the identification was made (optional).
	@param nature_of_id the nature of the identification.
	@param publication_id the publication ID for Sensu for the identification (optional).
	@param identification_remarks any remarks for the identification (optional).
	@param accepted_id_fg whether to set the identification is to be the current identification.
	@param stored_as_fg whether to store the identification as a field guide (optional, default 0).
	@param determiner_ids a comma-separated list of agent IDs for the determiners.
 --->
<cffunction name="addIdentification" access="remote" returntype="any" returnformat="json">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="taxa_formula" type="string" required="yes">
	<cfargument name="taxona" type="string" required="yes">
	<cfargument name="taxona_id" type="string" required="yes">
	<cfargument name="taxonb" type="string" required="no" default="">
	<cfargument name="taxonb_id" type="string" required="no" default="">
	<cfargument name="made_date" type="string" required="no" default="">
	<cfargument name="nature_of_id" type="string" required="yes">
	<cfargument name="publication_id" type="string" required="no" default="">
	<cfargument name="identification_remarks" type="string" required="no" default="">
	<cfargument name="accepted_id_fg" type="string" required="yes">
	<cfargument name="stored_as_fg" type="string" required="no" default="0">
	<cfargument name="determiner_ids" type="string" required="yes">

	<cfset variables.collection_object_id = arguments.collection_object_id>
	<cfset variables.taxa_formula = arguments.taxa_formula>
	<cfset variables.taxona = arguments.taxona>
	<cfset variables.taxona_id = arguments.taxona_id>
	<cfset variables.taxonb = arguments.taxonb>
	<cfset variables.taxonb_id = arguments.taxonb_id>
	<cfset variables.made_date = arguments.made_date>
	<cfset variables.nature_of_id = arguments.nature_of_id>
	<cfset variables.publication_id = arguments.publication_id>
	<cfset variables.identification_remarks = arguments.identification_remarks>
	<cfset variables.accepted_id_fg = arguments.accepted_id_fg>
	<cfset variables.stored_as_fg = arguments.stored_as_fg>
	<cfset variables.determiner_ids = arguments.determiner_ids>

	<!--- determiner_ids: comma-separated agent_id's --->
	<cfset var data = ArrayNew(1)>

	<cfset var scientific_name = variables.taxa_formula>
	<!--- throw an exception if formula contains B but taxon B is not provided --->
	<cfif variables.taxa_formula contains "B" and len(variables.taxonb) EQ 0>	
		<cfthrow message="Taxon B is required when the formula contains 'B'.">
	</cfif>
	<!--- replace A in the formula with a string that is not likely to occur in a scientific name --->
	<cfset scientific_name = REReplace(scientific_name, "\bA\b", "TAXON_A", "all")>
	<!--- replace B in the formula with a string that is not likely to occurr in a scientific name --->
	<cfset scientific_name = REReplace(scientific_name, "\bB\b", "TAXON_B", "all")>
	<!--- replace the placeholder for A in the formula with the taxon A name --->
	<cfset scientific_name = replace(scientific_name, "TAXON_A", variables.taxona)>
	<cfif len(variables.taxonb)>
		<!--- replace the placeholder for B with the taxon B name if provided --->
		<cfset scientific_name = replace(scientific_name, "TAXON_B", variables.taxonb)>
	</cfif>
	<!--- Clean up any double spaces or trailing punctuation --->
	<cfset scientific_name = Trim(REReplace(scientific_name, "[ ]{2,}", " ", "all"))>
	<cftransaction>
		<cftry>
			<cfquery name="getType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" >
				SELECT coll_object_type
				FROM coll_object
				WHERE 
					collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECiMAL" value="#variables.collection_object_id#">
			</cfquery>
			<cfif getType.recordcount EQ 0>
				<cfthrow message="No such collection_object_id.">
			</cfif>
			<!--- only add identifications to allowed types, cataloged item, specimen part--->
			<cfif NOT (getType.coll_object_type EQ "CI" OR getType.coll_object_type EQ "SP") >
				<cfthrow message = "Identifications can not be added to a collection object of type [#getType.coll_object_type#]">
			</cfif>
			<cfif variables.accepted_id_fg EQ "1">
				<!--- if this is an accepted identification, force unset the stored_as_fg flag --->
				<cfset variables.stored_as_fg = 0>
				<!--- Only one accepted per specimen, unset the flag for others --->
				<cfquery name="unsetAcceptedFG" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE identification 
					SET ACCEPTED_ID_FG = 0 
					WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">
				</cfquery>
			</cfif>
			<cfif variables.stored_as_fg EQ "1">
				<!--- Only one stored as per specimen, unset the flag for others --->
				<cfquery name="unserStoredFG" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE identification 
					SET STORED_AS_FG = 0 
					WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">
				</cfquery>
			</cfif>
			<!--- Insert identification --->
			<cfquery name="newID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="newID_result">
				INSERT INTO identification (
					identification_id,
					collection_object_id,
					made_date,
					nature_of_id,
					accepted_id_fg,
					identification_remarks,
					taxa_formula,
					scientific_name,
					publication_id,
					stored_as_fg
				) VALUES (
					sq_identification_id.nextval,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.made_date#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.nature_of_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.accepted_id_fg#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.identification_remarks#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.taxa_formula#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#scientific_name#">,
					<cfif len(variables.publication_id)>
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.publication_id#">
					<cfelse>
						NULL
					</cfif>,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.stored_as_fg#">
				)
			</cfquery>
			<!--- lookup the oracle primary key value for the inserted identification.identification_id --->
			<cfquery name="getNewIDPK" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT identification_id
				FROM identification
				WHERE ROWIDTOCHAR(rowid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newID_result.GENERATEDKEY#">
			</cfquery>
			<cfset var new_identification_id =getNewIDPK.identification_id>
			<!--- Insert determiners --->
			<cfif len(variables.determiner_ids)>
				<cfset var agentList = ListToArray(variables.determiner_ids)>
				<cfloop from="1" to="#ArrayLen(agentList)#" index="idx">
					<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						INSERT INTO identification_agent (
							identification_id,
							agent_id,
							identifier_order
						) VALUES (
							sq_identification_id.currval,
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agentList[idx]#">,
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#idx#">
						)
					</cfquery>
				</cfloop>
			</cfif>
			<!--- Taxonomy linking for A and (optionally) B --->
			<cfif len(variables.taxona_id)>
				<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					INSERT INTO identification_taxonomy (
						identification_id,
						taxon_name_id,
						variable
					) VALUES (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_identification_id#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.taxona_id#">,
						'A'
					)
				</cfquery>
			</cfif>
			<cfif len(variables.taxonb_id)>
				<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					INSERT INTO identification_taxonomy (
						identification_id,
						taxon_name_id,
						variable
					) VALUES (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_identification_id#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.taxonb_id#">,
						'B'
					)
				</cfquery>
			</cfif>
			<cftransaction action="commit"/>
			<cfset row = StructNew()>
			<cfset row["status"] = "added">
			<cfset row["id"] = "#new_identification_id#">
			<cfset data[1] = row>
		<cfcatch>
			<cftransaction action="rollback"/>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- Remove an identification (prevents removing accepted) 
  @param identification_id the identification_id to remove.
--->
<cffunction name="removeIdentification" access="remote" returntype="any" returnformat="json">
	<cfargument name="identification_id" type="string" required="yes">

	<cfset variables.identification_id = arguments.identification_id>

	<cfset data = ArrayNew(1)>
	<cfquery name="getAccepted" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT accepted_id_fg 
		FROM identification 
		WHERE identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.identification_id#">
	</cfquery>

	<cftransaction>
		<cftry>
			<cfif getAccepted.accepted_id_fg EQ 1>
				<cfthrow message="Cannot delete the accepted identification.">
			</cfif>
			<!--- Remove associated records --->
			<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				DELETE FROM identification_agent WHERE identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.identification_id#">
			</cfquery>
			<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				DELETE FROM identification_taxonomy WHERE identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.identification_id#">
			</cfquery>
			<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				DELETE FROM identification WHERE identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.identification_id#">
			</cfquery>
			<cftransaction action="commit"/>
			<cfset row = StructNew()>
			<cfset row["status"] = "removed">
			<cfset row["id"] = "#variables.identification_id#">
			<cfset data[1] = row>
		<cfcatch>
			<cftransaction action="rollback"/>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- getEditSingleIdentificationHTML Threaded method to obtain a dialog to edit a single identification.
 @param identification_id the identification_id for the identification to edit
 @return html for editing a single identification.
--->
<cffunction name="getEditSingleIdentificationHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="identification_id" type="string" required="yes">
	<cfset variables.identification_id = arguments.identification_id>

	<cfthread name="getEditIdentificationThread">
		<cftry>
			<!--- Load controlled vocabularies for taxon formula and nature of id --->
			<cfquery name="ctFormula" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT taxa_formula, description
				FROM cttaxa_formula
				ORDER BY taxa_formula
			</cfquery>
			<cfquery name="ctNature" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT nature_of_id, description 
				FROM ctnature_of_id 
				ORDER BY nature_of_id
			</cfquery>
			
			<!--- Get the current identification data --->
			<cfquery name="idData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT 
					identification.identification_id,
					identification.collection_object_id,
					identification.made_date,
					identification.nature_of_id,
					identification.accepted_id_fg,
					identification.identification_remarks,
					identification.taxa_formula,
					identification.scientific_name,
					identification.publication_id,
					identification.stored_as_fg,
					fp_long.formatted_publication full_citation,
					fp_short.formatted_publication short_citation
				FROM 
					identification
					LEFT JOIN formatted_publication fp_long ON identification.publication_id = fp_long.publication_id and 
						fp_long.format_style = 'long'
					LEFT JOIN formatted_publication fp_short ON identification.publication_id = fp_short.publication_id and 
						fp_short.format_style = 'short'
				WHERE 
					identification.identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.identification_id#">
			</cfquery>
			
			<!--- Get the taxon record for the A identification --->
			<cfquery name="taxonA" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT
					identification_taxonomy.taxon_name_id,
					taxonomy.scientific_name
				FROM
					identification_taxonomy
					JOIN taxonomy ON identification_taxonomy.taxon_name_id = taxonomy.taxon_name_id
				WHERE
					identification_taxonomy.identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.identification_id#">
					AND identification_taxonomy.variable = 'A'
			</cfquery>
			
			<!--- Get the taxon record for the B identification, if any --->
			<cfquery name="taxonB" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT
					identification_taxonomy.taxon_name_id,
					taxonomy.scientific_name
				FROM
					identification_taxonomy
					JOIN taxonomy ON identification_taxonomy.taxon_name_id = taxonomy.taxon_name_id
				WHERE
					identification_taxonomy.identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.identification_id#">
					AND identification_taxonomy.variable = 'B'
			</cfquery>
			
			<!--- Get determiners --->
			<cfquery name="determiners" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT
					identification_agent.identification_agent_id,
					identification_agent.agent_id,
					identification_agent.identifier_order,
					preferred_agent_name.agent_name
				FROM
					identification_agent
					JOIN preferred_agent_name ON identification_agent.agent_id = preferred_agent_name.agent_id
				WHERE
					identification_agent.identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.identification_id#">
				ORDER BY
					identification_agent.identifier_order
			</cfquery>
			
			<!--- Check if we found the identification --->
			<cfif idData.recordcount EQ 0>
				<cfthrow message = "Identification not found for identification_id: #encodeForHtml(variables.identification_id)#">
			</cfif>
			
			<cfoutput>
				<div id="editIdentificationHTML">
					<div class="container-fluid">
						<div class="row">
							<div class="col-12 float-left">
								<div class="edit-form float-left">
									<div class="edit-form-header pt-1 px-2 col-12 float-left">
										<h2 class="h3 my-0 px-1 pb-1">Edit Identification</h2>
									</div>
									<div class="card-body">
										<form name="editIdentificationForm" id="editIdentificationForm">
											<input type="hidden" name="identification_id" value="#variables.identification_id#">
											<input type="hidden" name="collection_object_id" value="#idData.collection_object_id#">
											<input type="hidden" name="method" value="saveIdentification">
											<input type="hidden" name="returnformat" value="json">
											<div class="form-row">
												<div class="col-12 col-md-2">
													<label for="taxa_formula" class="data-entry-label">ID Formula:</label>
													<select name="taxa_formula" id="eid_edit_taxa_formula" class="data-entry-input reqdClr" onchange="updateEditTaxonBVisibility();" required>
														<cfloop query="ctFormula">
															<option value="#ctFormula.taxa_formula#" <cfif idData.taxa_formula EQ ctFormula.taxa_formula>selected</cfif>>#ctFormula.taxa_formula#</option>
														</cfloop>
													</select>
												</div>
												<div class="col-12 col-md-5">
													<label for="taxona" class="data-entry-label">Taxon A:</label>
													<input type="text" name="taxona" id="eid_edit_taxona" class="data-entry-input reqdClr" required value="#taxonA.scientific_name#">
													<input type="hidden" name="taxona_id" id="eid_edit_taxona_id" value="#taxonA.taxon_name_id#">
													<script>
														// Initialize taxon autocomplete
														$(document).ready(function() {
															makeScientificNameAutocompleteMeta("edit_taxona","edit_taxona_id");
														});
													</script>
												</div>
												<div class="col-12 col-md-5">
													<div class="form-row" id="eid_edit_taxonb_row" <cfif NOT idData.taxa_formula CONTAINS "B">style="display:none;"</cfif>>
														<label for="taxonb" class="data-entry-label">Taxon B:</label>
														<input type="text" name="taxonb" id="eid_edit_taxonb" class="data-entry-input" value="#taxonB.scientific_name#">
														<input type="hidden" name="taxonb_id" id="eid_edit_taxonb_id" value="#taxonB.taxon_name_id#">
														<script>
															// Initialize taxon B autocomplete
															$(document).ready(function() {
																makeScientificNameAutocompleteMeta("edit_taxonb","edit_taxonb_id");
															});
														</script>
													</div>
												</div>
												<div class="col-12 col-md-3">
													<label for="made_date" class="data-entry-label">Date Identified:</label>
													<input type="text" name="made_date" id="eid_edit_made_date" class="data-entry-input" value="#idData.made_date#">
													<script>
														// Initialize datepicker
														$(document).ready(function() {
															$("##edit_made_date").datepicker({
																dateFormat: "yy-mm-dd",
																changeMonth: true,
																changeYear: true,
																showButtonPanel: true
															});
														});
													</script>
												</div>
												<div class="col-12 col-md-3">
													<label for="nature_of_id" class="data-entry-label">Nature of ID:</label>
													<select name="nature_of_id" id="eid_edit_nature_of_id" class="data-entry-select reqdClr" required>
														<cfloop query="ctNature">
															<option value="#ctNature.nature_of_id#" <cfif idData.nature_of_id EQ ctNature.nature_of_id>selected</cfif>>#ctNature.nature_of_id# #ctNature.description#</option>
														</cfloop>
													</select>
												</div>
												<div class="col-12 col-md-6">
													<!--- publication autocomplete --->
													<label for="publication" class="data-entry-label">Sensu:</label>
													<input type="text" name="sensu" id="eid_edit_publication" class="data-entry-input" value="#idData.short_citation#">
													<input type="hidden" name="publication_id" id="eid_edit_publication_id" value="#idData.publication_id#">
													<script>
														// Initialize publication autocomplete
														$(document).ready(function() {
															makePublicationAutocompleteMeta("edit_publication","edit_publication_id");
														});
													</script>
												</div>
												<div class="col-12 col-md-10">
													<label for="identification_remarks" class="data-entry-label">Remarks:</label>
													<input type="text" name="identification_remarks" id="eid_edit_identification_remarks" class="data-entry-input" value="#idData.identification_remarks#">
												</div>
												<div class="col-12 col-md-2">
													<label for="stored_as_fg" class="data-entry-label">Stored As:</label>
													<input type="checkbox" name="stored_as_fg" id="eid_edit_stored_as_fg" value="1" <cfif idData.stored_as_fg EQ 1>checked</cfif>>
												</div>
												<div class="col-12 col-md-3">
													<label for="accepted_id_fg" class="data-entry-label">Accepted ID:</label>
													<input type="checkbox" name="accepted_id_fg" id="eid_edit_accepted_id_fg" value="1" <cfif idData.accepted_id_fg EQ 1>checked</cfif>>
												</div>
												
												<!--- Determiners section --->
												<div class="col-12 mt-3">
													<h4 class="h5">Determiners</h4>
													<div id="eid_edit_determiners_container">
														<cfloop query="determiners">
															<div class="determiner-row mb-2" id="eid_determiner_row_#determiners.identification_agent_id#">
																<input type="hidden" name="det_id_#determiners.identification_agent_id#" value="#determiners.identification_agent_id#">
																<input type="text" name="det_name_#determiners.identification_agent_id#" id="eid_det_name_#determiners.identification_agent_id#" class="data-entry-input determiner-input" value="#determiners.agent_name#">
																<input type="hidden" name="det_agent_id_#determiners.identification_agent_id#" id="eid_det_agent_id_#determiners.identification_agent_id#" value="#determiners.agent_id#">
																<input type="number" name="det_order_#determiners.identification_agent_id#" id="eid_det_order_#determiners.identification_agent_id#" class="data-entry-input determiner-order" value="#determiners.identifier_order#" style="width:60px;" min="1">
																<button type="button" class="btn btn-xs btn-secondary ml-2" onclick="removeEditDeterminer('#determiners.identification_agent_id#')">Remove</button>
																<script>
																	// Initialize agent autocomplete for each determiner
																	$(document).ready(function() {
																		makeAgentAutocompleteMeta("det_name_#determiners.identification_agent_id#","det_agent_id_#determiners.identification_agent_id#");
																	});
																</script>
															</div>
														</cfloop>
													</div>
													<!--- Button to add another determiner --->
													<button type="button" class="btn btn-xs btn-secondary mt-2" id="eid_addEditDeterminerButton" onClick="addEditDeterminerControl();">Add Determiner</button>
												</div>
												
												<!--- Action buttons --->
												<div class="col-12 mt-3">
													<input type="button" value="Save Changes" class="btn btn-xs btn-primary mr-2" id="eid_saveIdButton" onClick="handleSaveIdentification();">
													<input type="button" value="Cancel" class="btn btn-xs btn-secondary" onClick="closeEditDialog();">
													<output id="eid_editIdStatus" class="pt-1"></output>
												</div>
											</div>
										</form>
										<script>
											// Show/hide Taxon B row based on formula
											function updateEditTaxonBVisibility() {
												var formula = document.getElementById('eid_edit_taxa_formula').value;
												if (formula.includes('B')) {
													document.getElementById('eid_edit_taxonb_row').style.display = '';
												} else {
													document.getElementById('eid_edit_taxonb_row').style.display = 'none';
													document.getElementById('eid_edit_taxonb').value = '';
													document.getElementById('eid_edit_taxonb_id').value = '';
												}
											}
											
											// Track any new determiners added during editing
											var newDeterminerId = 0;
											
											function addEditDeterminerControl() {
												newDeterminerId--;  // Use negative IDs for new determiners to distinguish from existing ones
												var newId = "new_" + Math.abs(newDeterminerId);
												
												var newRow = '<div class="determiner-row mb-2" id="eid_determiner_row_' + newId + '">';
												newRow += '<input type="hidden" name="det_id_' + newId + '" value="new">';
												newRow += '<input type="text" name="det_name_' + newId + '" id="eid_det_name_' + newId + '" class="data-entry-input determiner-input">';
												newRow += '<input type="hidden" name="det_agent_id_' + newId + '" id="eid_det_agent_id_' + newId + '" value="">';
												newRow += '<input type="number" name="det_order_' + newId + '" id="eid_det_order_' + newId + '" class="data-entry-input determiner-order" value="' + ($("##edit_determiners_container .determiner-row").length + 1) + '" style="width:60px;" min="1">';
												newRow += '<button type="button" class="btn btn-xs btn-secondary ml-2" onclick="removeEditDeterminer(\'' + newId + '\')">Remove</button>';
												newRow += '</div>';
												
												$("##edit_determiners_container").append(newRow);
												
												// Initialize autocomplete for the new determiner
												makeAgentAutocompleteMeta("det_name_" + newId, "det_agent_id_" + newId);
											}
											
											function removeEditDeterminer(id) {
												$("##eid_determiner_row_" + id).remove();
												// Update order numbers
												var order = 1;
												$(".determiner-order").each(function() {
													$(this).val(order++);
												});
											}
											
											function closeEditDialog() {
												// Close the dialog or go back to identification list
												$("##editIdentificationHTML").remove();
												reloadIdentifications();
											}
											
											function handleSaveIdentification() {
												setFeedbackControlState("editIdStatus", "saving");
												
												// Collect all determiners (existing and new)
												var determiners = [];
												$("##edit_determiners_container .determiner-row").each(function() {
													var rowId = $(this).attr('id').replace('determiner_row_', '');
													var detId = $("input[name='det_id_" + rowId + "']").val();
													var agentId = $("input[name='det_agent_id_" + rowId + "']").val();
													var order = $("input[name='det_order_" + rowId + "']").val();
													
													if (agentId && agentId.length > 0) {
														determiners.push({
															det_id: detId,
															agent_id: agentId,
															order: order
														});
													}
												});
												
												// Add determiners to the form data
												var form = $('##editIdentificationForm');
												var formData = form.serialize();
												formData += "&determiners=" + JSON.stringify(determiners);
												
												$.ajax({
													url: '/specimens/component/functions.cfc',
													data: formData,
													type: 'POST',
													success: function(response) {
														setFeedbackControlState("editIdStatus", "saved");
														closeEditDialog();
														reloadIdentificationsDialogAndPage();
													},
													error: function(jqXHR, textStatus, errorThrown) {
														setFeedbackControlState("editIdStatus", "error");
														handleFail(jqXHR, textStatus, errorThrown, "saving identification");
													}
												});
											}
										</script>
									</div>
								</div>
							</div>
						</div>
					</div>
				</div>
			</cfoutput>
			<cfcatch>
				<cfoutput>
					<cfset function_called = "#GetFunctionCalledName()#">
					<h3 class="mt-2 text-danger">Error in #function_called# #cfcatch.type#</h3>
					<p>#cfcatch.message# #cfcatch.detail#</p>
					<cfif isDefined("session.roles") and listFindNoCase(session.roles,"global_admin")>
						<cfdump var="#cfcatch#" label="Error Details">
					</cfif>
				</cfoutput>
			</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getEditIdentificationThread" />
	<cfreturn getEditIdentificationThread.output>
</cffunction>

<!--- saveIdentification saves changes to a single identification record.
	@param identification_id the identification_id for the identification to update.
	@param collection_object_id the collection_object_id for the collection object.
	@param taxa_formula the taxa formula to use for the identification.
	@param taxona the taxon A name to use for the identification.
	@param taxona_id the taxon A ID to use for the identification.
	@param taxonb the taxon B name to use for the identification (optional).
	@param taxonb_id the taxon B ID to use for the identification (optional).
	@param made_date the date the identification was made (optional).
	@param nature_of_id the nature of the identification.
	@param publication_id the publication ID for Sensu for the identification (optional).
	@param identification_remarks any remarks for the identification (optional).
	@param stored_as_fg whether to store the identification as a field guide (optional, default 0).
	@param accepted_id_fg whether this is the accepted identification (optional, default 0).
	@param determiners a JSON array of determiner objects with det_id, agent_id, and order properties.
 --->
<cffunction name="saveIdentification" access="remote" returntype="any" returnformat="json">
	<cfargument name="identification_id" type="string" required="yes">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="taxa_formula" type="string" required="yes">
	<cfargument name="taxona" type="string" required="yes">
	<cfargument name="taxona_id" type="string" required="yes">
	<cfargument name="taxonb" type="string" required="no" default="">
	<cfargument name="taxonb_id" type="string" required="no" default="">
	<cfargument name="made_date" type="string" required="no" default="">
	<cfargument name="nature_of_id" type="string" required="yes">
	<cfargument name="publication_id" type="string" required="no" default="">
	<cfargument name="identification_remarks" type="string" required="no" default="">
	<cfargument name="stored_as_fg" type="string" required="no" default="0">
	<cfargument name="accepted_id_fg" type="string" required="no" default="0">
	<cfargument name="determiners" type="string" required="yes">
	
	<cfset var data = ArrayNew(1)>
	<cfset determinersArray = deserializeJSON(arguments.determiners)>
	
	<cfset var scientific_name = arguments.taxa_formula>
	<!--- throw an exception if formula contains B but taxon B is not provided --->
	<cfif arguments.taxa_formula contains "B" and len(arguments.taxonb) EQ 0>	
		<cfthrow message="Taxon B is required when the formula contains 'B'.">
	</cfif>
	
	<!--- replace A in the formula with a string that is not likely to occur in a scientific name --->
	<cfset scientific_name = REReplace(scientific_name, "\bA\b", "TAXON_A", "all")>
	<!--- replace B in the formula with a string that is not likely to occurr in a scientific name --->
	<cfset scientific_name = REReplace(scientific_name, "\bB\b", "TAXON_B", "all")>
	<!--- replace the placeholder for A in the formula with the taxon A name --->
	<cfset scientific_name = replace(scientific_name, "TAXON_A", arguments.taxona)>
	<cfif len(arguments.taxonb)>
		<!--- replace the placeholder for B with the taxon B name if provided --->
		<cfset scientific_name = replace(scientific_name, "TAXON_B", arguments.taxonb)>
	</cfif>
	<!--- Clean up any double spaces or trailing punctuation --->
	<cfset scientific_name = Trim(REReplace(scientific_name, "[ ]{2,}", " ", "all"))>
	
	<!--- Disable the stored_as_fg trigger, needed to execute setStoredAsZero query below --->
	<cftry>
		<cfquery datasource="uam_god">
			alter trigger tr_stored_as_fg disable
		</cfquery>
		<cfcatch>
			<!--- if already disabled, ignore --->
		</cfcatch>
	</cftry>
	
	<cftransaction>
		<cftry>
			<!--- Handle accepted_id_fg flag - only one per specimen --->
			<cfif arguments.accepted_id_fg EQ 1>
				<cfquery name="setAcceptedZero" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE identification SET accepted_id_fg = 0 
					WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">
				</cfquery>
			</cfif>
			
			<!--- Handle stored_as_fg flag - only one per specimen --->
			<cfif arguments.stored_as_fg EQ 1>
				<cfquery name="setStoredAsZero" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE identification SET stored_as_fg = 0 
					WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">
				</cfquery>
			</cfif>
			
			<!--- Update the identification record --->
			<cfquery name="doUpdate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="doUpdate_result">
				UPDATE identification SET
					made_date = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.made_date#">,
					nature_of_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.nature_of_id#">,
					accepted_id_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.accepted_id_fg#">,
					identification_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.identification_remarks#">,
					taxa_formula = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.taxa_formula#">,
					scientific_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#scientific_name#">,
					stored_as_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.stored_as_fg#">,
					publication_id = <cfif len(arguments.publication_id)>
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.publication_id#">
					<cfelse>
						NULL
					</cfif>
				WHERE identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.identification_id#">
			</cfquery>
			<cfif doUpdate_result.recordcount NEQ 1>
				<cfthrow message="Other than 1 identification would be updated for identification_id: [#encodeForHtml(arguments.identification_id)#]">
			</cfif>
			
			<!--- Update taxonomy links --->
			<!--- First, remove existing taxonomy links --->
			<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				DELETE FROM identification_taxonomy 
				WHERE identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.identification_id#">
			</cfquery>
			
			<!--- Then add the updated links --->
			<cfif len(arguments.taxona_id)>
				<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					INSERT INTO identification_taxonomy (
						identification_id,
						taxon_name_id,
						variable
					) VALUES (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.identification_id#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.taxona_id#">,
						'A'
					)
				</cfquery>
			</cfif>
			
			<cfif len(arguments.taxonb_id)>
				<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					INSERT INTO identification_taxonomy (
						identification_id,
						taxon_name_id,
						variable
					) VALUES (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.identification_id#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.taxonb_id#">,
						'B'
					)
				</cfquery>
			</cfif>
			
			<!--- Update determiners --->
			<!--- First, get the existing determiners to compare with the incoming list --->
			<cfquery name="existingDeterminers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT identification_agent_id
				FROM identification_agent
				WHERE identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.identification_id#">
			</cfquery>
			
			<cfset var existingIds = ValueList(existingDeterminers.identification_agent_id)>
			<cfset var processedIds = "">
			
			<!--- Process each determiner from the form --->
			<cfloop array="#determinersArray#" index="det">
				<cfset var detId = det.det_id>
				<cfset var agentId = det.agent_id>
				<cfset var orderNum = det.order>
				
				<cfif detId EQ "new">
					<!--- This is a new determiner to add --->
					<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						INSERT INTO identification_agent (
							identification_id,
							agent_id,
							identifier_order
						) VALUES (
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.identification_id#">,
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agentId#">,
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#orderNum#">
						)
					</cfquery>
				<cfelse>
					<!--- This is an existing determiner to update --->
					<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE identification_agent SET
							agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agentId#">,
							identifier_order = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#orderNum#">
						WHERE identification_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#detId#">
					</cfquery>
					<cfset processedIds = ListAppend(processedIds, detId)>
				</cfif>
			</cfloop>
			
			<!--- Remove any determiners that were in the database but not in the form submission --->
			<cfloop list="#existingIds#" index="existingId">
				<cfif NOT ListFind(processedIds, existingId)>
					<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						DELETE FROM identification_agent 
						WHERE identification_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#existingId#">
					</cfquery>
				</cfif>
			</cfloop>
			
			<cftransaction action="commit"/>
			<cfset row = StructNew()>
			<cfset row["status"] = "updated">
			<cfset row["id"] = "#arguments.identification_id#">
			<cfset data[1] = row>
		<cfcatch>
			<cftransaction action="rollback"/>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	
	<!--- Re-enable the stored_as_fg trigger --->
	<cftry>
		<cfquery datasource="uam_god">
			alter trigger tr_stored_as_fg enable
		</cfquery>
		<cfcatch>
			<!--- If already enabled, ignore --->
		</cfcatch>
	</cftry>
	
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- Bulk update identifications for a collection object (edit/save all fields, triggers, flags, etc.) --->
<cffunction name="updateIdentifications" access="remote" returntype="any" returnformat="json">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="identificationUpdates" type="array" required="yes">
	<!--- Each element: struct with all fields including accepted_id_fg, stored_as_fg, sort_order, etc. --->
	<cfset var data = ArrayNew(1)>
	<!--- Disable the stored_as_fg trigger if needed --->
	<cftry>
		<cfquery datasource="uam_god">
			alter trigger tr_stored_as_fg disable
		</cfquery>
		<cfcatch>
			<!--- if already disabled, ignore --->
		</cfcatch>
	</cftry>
	<cftransaction>
		<cftry>
			<cfloop array="#arguments.identificationUpdates#" index="ident">
				<cfset var id = ident.identification_id>
				<cfset var accepted = ident.accepted_id_fg>
				<cfset var storedas = structKeyExists(ident,"stored_as_fg") ? ident.stored_as_fg : 0>
				<cfset var sort_order = structKeyExists(ident,"sort_order") ? ident.sort_order : "">
				<!--- Accepted logic: only one per specimen --->
				<cfif accepted EQ 1>
					<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE identification SET accepted_id_fg = 0 WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">
					</cfquery>
					<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE identification SET accepted_id_fg = 1, sort_order = null WHERE identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#id#">
					</cfquery>
					<cfset storedas = 0>
				</cfif>
				<!--- Stored as logic: only one per specimen --->
				<cfif storedas EQ 1>
					<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE identification SET stored_as_fg = 0 WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">
					</cfquery>
					<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE identification SET stored_as_fg = 1 WHERE identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#id#">
					</cfquery>
				<cfelse>
					<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE identification SET stored_as_fg = 0 WHERE identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#id#">
					</cfquery>
				</cfif>
				<!--- If delete requested --->
				<cfif accepted EQ "DELETE">
					<!--- Delete all associated agents and taxonomy --->
					<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						DELETE FROM identification_agent WHERE identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#id#">
					</cfquery>
					<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						DELETE FROM identification_taxonomy WHERE identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#id#">
					</cfquery>
					<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						DELETE FROM identification WHERE identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#id#">
					</cfquery>
				<cfelse>
					<!--- Update fields --->
					<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE identification SET
							nature_of_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ident.nature_of_id#">,
							made_date = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ident.made_date#">,
							identification_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ident.identification_remarks#">,
							publication_id = <cfif len(ident.publication_id)><cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#ident.publication_id#"><cfelse>NULL</cfif>,
							sort_order = <cfif len(sort_order)><cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#sort_order#"><cfelse>NULL</cfif>
						WHERE identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#id#">
					</cfquery>
					<!--- Update determiners (identification_agent) --->
					<cfif structKeyExists(ident, "determiners")>
						<cfloop array="#ident.determiners#" index="det">
							<cfif det.action EQ "add">
								<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									INSERT INTO identification_agent (identification_id, agent_id, identifier_order)
									VALUES (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#id#">,
													<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#det.agent_id#">,
													<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#det.identifier_order#">)
								</cfquery>
							<cfelseif det.action EQ "delete">
								<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									DELETE FROM identification_agent WHERE identification_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#det.identification_agent_id#">
								</cfquery>
							<cfelseif det.action EQ "update">
								<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									UPDATE identification_agent SET
										agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#det.agent_id#">,
										identifier_order = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#det.identifier_order#">
									WHERE identification_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#det.identification_agent_id#">
								</cfquery>
							</cfif>
						</cfloop>
					</cfif>
				</cfif>
			</cfloop>
			<cftransaction action="commit"/>
			<cfset row = StructNew()>
			<cfset row["status"] = "1">
			<cfset row["message"] = "Record updated.">
			<cfset row["id"] = "#arguments.collection_object_id#">
			<cfset data[1] = row>
		<cfcatch>
			<cftransaction action="rollback"/>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<!--- Re-enable the trigger --->
	<cftry>
		<cfquery datasource="uam_god">
			alter trigger tr_stored_as_fg enable
		</cfquery>
		<cfcatch>
			<!--- ignore if already enabled --->
		</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---function getEditIdentificationHtml obtain an html block to popluate an edit dialog for an identification 
 @param identification-id the identification.identification_id to edit.
 @return html for editing the identification 
--->
<cffunction name="getEditIdentificationHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="identification_id" type="string" required="yes">
	<cfthread name="getIdentificationThread">
		<cftry>
			<cfquery name="formulas" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT taxa_formula 
				FROM cttaxa_formula
			</cfquery>
			<cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT 1 as status, identification.identification_id, identification.collection_object_id, 
					identification.scientific_name, identification.made_date, identification.nature_of_id, 
					identification.stored_as_fg, identification.identification_remarks, identification.accepted_id_fg, 
					identification.taxa_formula, identification.sort_order, taxonomy.full_taxon_name, taxonomy.author_text, 
					identification_agent.agent_id, concatidagent(identification.identification_id) agent_name
				FROM 
					identification
					left join identification_taxonomy on identification.identification_id=identification_taxonomy.identification_id 
					left join taxonomy on identification_taxonomy.taxon_name_id = taxonomy.taxon_name_id and 
					left join identification_agent on identification_agent.identification_id = identification.identification_id and
				WHERE 	
					identification.identification_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#identification_id#">
				ORDER BY 
					made_date
			</cfquery>
			<cfoutput>
				<div id="identificationHTML">
					<cfloop query="theResult">
						<div class="identifcationExistingForm">
							<form>
								<div class="container pl-1">
									<div class="col-xl-6 col-md-12 float-left">
										<div class="form-group">
											<label for="scientific_name">Scientific Name:</label>
											<input type="text" name="taxona" id="taxona" class="reqdClr form-control form-control-sm" value="#encodeForHTML(scientific_name)#" size="1" onChange="taxaPick('taxona_id','taxona','newID',this.value); return false;" onKeyPress="return noenter(event);">
											<input type="hidden" name="taxona_id" id="taxona_id" class="reqdClr">
										</div>
										<!--- TODO:  Add additional name for B formulas --->
										<div class="form-group w-25 mb-3 float-left">
											<label for="taxa_formula">Formula:</label>
											<select class="border custom-select form-control input-sm" id="select">
												<option value="" disabled="" selected="">#taxa_formula#</option>
												<cfloop query="formulas">
													<option value="#taxa_formula#">#taxa_formula#</option>
												</cfloop>
											</select>
										</div>
										<div class="form-group w-50 mb-3 ml-3 float-left">
											<label for="made_date">Made Date:</label>
											<input type="text" class="form-control ml-0 input-sm" id="made_date" value="#dateformat(made_date,'yyyy-mm-dd')#&nbsp;">
										</div>
									</div>
									<div class="col-md-6 col-sm-12 float-left">
										<div class="form-group"> 
											<!--- TODO: Fix this, should be an agent picker --->
											<label for="determinedby">Determined By:</label>
											<input type="text" class="form-control-sm" id="determinedby" value="#encodeForHTML(agent_name)#">
										</div>
										<div class="form-group">
											<label for="nature_of_id">Nature of ID:</label>
											<select name="nature_of_id" id="nature_of_id" size="1" class="reqdClr custom-select form-control">
												<option value="#nature_of_id#">#nature_of_id#</option>
												<!--- TODO: Wrong query name, should reference a code table query. --->
												<cfloop query="theResult">
													<option value="theResult.nature_of_id">#nature_of_id#</option>
												</cfloop>
											</select>
										</div>
									</div>
									<div class="col-md-12 col-sm-12 float-left">
										<div class="form-group">
											<label for="full_taxon_name">Full Taxon Name:</label>
											<input type="text" class="form-control-sm" id="full_taxon_name" value="#encodeForHTML(full_taxon_name)#">
										</div>
										<div class="form-group">
											<label for="identification_remarks">Identification Remarks:</label>
											<textarea type="text" class="form-control" id="identification_remarks" value="#encodeForHTML(identification_remarks)#"></textarea>
										</div>
										<div class="form-check">
											<input type="checkbox" class="form-check-input" id="materialUnchecked">
											<label class="mt-2 form-check-label" for="materialUnchecked">Stored as #encodeForHTML(scientific_name)#</label>
										</div>
										<div class="form-group float-right">
											<button type="button" value="Create New Identification" class="btn btn-primary ml-2"
												 onClick="$('.dialog').dialog('open'); loadNewIdentificationForm(identification_id,'newIdentificationForm');">Create New Identification</button>
										</div>
									</div>
								</div>
							</form>
						</div>
					</cfloop>
					<!--- theResult ---> 
				</div>
			</cfoutput>
			<cfcatch>
				<cfoutput>
					<p class="mt-2 text-danger">Error: #cfcatch.type# #cfcatch.message# #cfcatch.detail#</p>
				</cfoutput>
			</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getIdentificationThread" />
	<cfreturn getIdentificationThread.output>
</cffunction>

<cffunction name="getMediaTable" returntype="query" access="remote">
	<cfargument name="media_id" type="string" required="yes">
	<cfset r=1>
	<cftry>
		<cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT 1 as status, media.media_id 
					media.media_uri,media.preview_uri, media.media_type, media.mime_type, media.mask_media_fg, media.media_license_id
				FROM 
					media
					left join media_relations on  media_relations.media_id=media.media_id  
					left join media_labels on media_labels.media_id = media_relations.media_id
				WHERE 	
					media.media_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
				ORDER BY 
					media_id
		</cfquery>
		<cfif theResult.recordcount eq 0>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "0", 1)>
			<cfset t = QuerySetCell(theResult, "message", "No shipments found.", 1)>
		</cfif>
		<cfcatch>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "-1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "#cfcatch.type# #cfcatch.message# #cfcatch.detail#", 1)>
		</cfcatch>
	</cftry>
	<cfif isDefined("asTable") AND asTable eq "true">
		<cfreturn resulthtml>
		<cfelse>
		<cfreturn theResult>
	</cfif>
</cffunction>

<cffunction name="saveMediaID" access="remote" returntype="any" returnformat="json">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="media_id" type="string" required="yes">
	<cfargument name="media_uri" type="string" required="yes">
	<cfargument name="preview_uri" type="string" required="no">
	<cfargument name="media_type" type="string" required="yes">
	<cfargument name="mime_type" type="string" required="yes">
	<cfargument name="mask_media_fg" type="string" required="yes">
	<cfargument name="media_license_fg" type="string" required="yes">
	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="updateMediaCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="newMediaCheck_result">
				SELECT count(*) as ct from media
				WHERE
					MEDIA_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value='#media_id#'>
			</cfquery>
			<cfif updateMediaCheck.ct NEQ 1>
				<cfthrow message = "Unable to update images. Provided media_id does not match a record in the images ID table.">
			</cfif>
			<cfquery name="updateMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateMedia">
				UPDATE media SET
					media_uri = <cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#media_uri#">,
					preview_uri = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#preview_uri#">,
					media_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_type#">,
					mime_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#mime_type#">,
					mask_media_fg = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#mask_media_fg#">
				media_license_fg = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_license_fg#">
				
				where
					media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
			</cfquery>
			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["id"] = "#media_id#">
			<cfset data[1] = row>
			<cftransaction action="commit">
			<cfcatch>
				<cftransaction action="rollback">
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
				<cfabort>
			</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- getEditCatalogHTML get html to populate a dialog for editing catalog number and related catalog information
 @param collection_object_id for the cataloged item to edit.
 @return html for editing the catalog number and related information
--->
<cffunction name="getEditCatalogHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getEditCatalogThread">
		<cfoutput>
			<cftry>
				<cfquery name="ctColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT collection, 
						institution_acronym,
						collection_cde,
						collection_id
					FROM collection 
					ORDER BY collection
				</cfquery>
				<cfquery name="getCatalog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT
						cataloged_item.collection_object_id,
						coll_object_type,
						cataloged_item.cat_num,
						cataloged_item.collection_cde,
						collection.institution_acronym,
						collection.collection_id,
						accn.transaction_id,
						accn.accn_number,
						accn.received_date,
						accn.accn_status,
						cataloged_item.accn_id,
						cataloged_item.cataloged_item_type,
						ctcataloged_item_type.description as cataloged_item_type_description
					FROM
						cataloged_item
						join collection on cataloged_item.collection_id=collection.collection_id
						join coll_object on cataloged_item.collection_object_id=coll_object.collection_object_id
						join accn on cataloged_item.accn_id=accn.transaction_id
						join ctcataloged_item_type on cataloged_item.cataloged_item_type=ctcataloged_item_type.cataloged_item_type
					WHERE
						cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
				</cfquery>
				<cfloop query="getCatalog">
					<cfquery name="getAccnAgents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT
							initcap(trans_agent_role) agent_role,
							mczbase.get_agentnameoftype(agent_id,'preferred') agent_name 
						FROM
							trans_agent
						WHERE
							trans_agent.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getCatalog.accn_id#">
						ORDER BY
							trans_agent_role asc
					</cfquery>
					<cfquery name="getDispositionRemarks" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT 
							disposition_remarks
						FROM
							coll_object_remark
						WHERE	
							collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
						AND disposition_remarks is not null
					</cfquery>
					<div class="container-fluid">
						<div class="row">
							<div class="col-12 float-left mb-4 px=0 border">
								<!--- cataloging data --->
								<h2 class="h3 my-0 px-1 pb-1">Cataloged Item #getCatalog.institution_acronym#:#getCatalog.collection_cde#:#getCatalog.cat_num#</h2>
								<ul>
									<cfif isDefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions")>
										<li>Accession: <a href="/transactions/Accession.cfm?action=edit&transaction_id=#transaction_id#">#getCatalog.accn_number#</a></li>
									<cfelse>
										<li>Accession: <a href="">#getCatalog.accn_number#</a></li>
									</cfif>
									<li>Received Date: #dateformat(getCatalog.received_date,'mm/dd/yyyy')#</li>
									<li>Accession Status: #getCatalog.accn_status#</li>
									<cfloop query="getAccnAgents">
										<li>#getAccnAgents.agent_role#: #getAccnAgents.agent_name#</li>
									</cfloop>
									<cfif getDispositionRemarks.recordcount gt 0>
										<cfloop query="getDispositionRemarks">
											<li>Disposition Remarks: #getDispositionRemarks.disposition_remarks#</li>
										</cfloop>
									</cfif>
								</ul>
							</div>
							<div class="col-12 float-left mb-4 px=0 border">
								<!--- Type of object --->
								<cfif getCatalog.coll_object_type is "CI">
									<cfset variables.coll_object_type="Cataloged Item">
								<cfelse>
									<cfset variables.coll_object_type="#getCatalog.coll_object_type#">
								</cfif>
								<!--- check for mixed collection --->
								<cfquery name="checkMixed" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									SELECT count(identification_id) ct
									FROM coll_object
										join specimen_part on specimen_part.derived_from_cat_item = coll_object.collection_object_id
										join identification on specimen_part.collection_object_id = identification.collection_object_id
									WHERE coll_object.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getCatalog.collection_object_id#">
								</cfquery>
								<cfif checkMixed.ct gt 0>
									<cfset variables.coll_object_type="#variabls.coll_object_type#: Mixed Collection">
								</cfif>
								#variables.coll_object_type# #getCatalog.cataloged_item_type_description# 
								( occurrenceID: https://mczbase.mcz.harvard.edu/guid/#getCatalog.institution_acronym#:#getCatalog.collection_cde#:#getCatalog.cat_num# )
								<cfquery name="getComponents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									SELECT count(specimen_part.collection_object_id) ct, coll_object_type, part_name, count(identification.collection_object_id) identifications
									FROM 
										specimen_part 
										join coll_object on coll_object.collection_object_id=specimen_part.collection_object_id
										left join identification on coll_object.collection_object_id=identification.collection_object_id
									WHERE derived_from_cat_item = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getCatalog.collection_object_id#">
									GROUP BY coll_object_type, part_name
								</cfquery>
								<ul>
								<cfloop query="getComponents">
									<cfset variables.occurrences="">
									<cfset variables.subtype="">
									<cfif getComponents.identifications gt 0>
										<cfset variables.subtype=": Different Organism">
										<!--- TODO: show occurrence ID value(s) for the identifiable object(s) --->
										<cfset variables.occurrences="(occurrenceID: **TODO** )">
									</cfif>
									<cfif getComponents.coll_object_type is "SP">
										<cfset variables.coll_object_type="Specimen Part#variables.subtype#">
									<cfelseif getComponents.coll_object_type is "SS">
										<cfset variables.coll_object_type="Subsample#variables.subtype#">
									<cfelseif getComponents.coll_object_type is "IO"><!--- identifiable object thus a new occurrence --->
										<!--- TODO: Identify specimen parts with identifications through linked identifications, not type --->
										<cfset variables.coll_object_type="Different Organism">
										<!--- TODO: show occurrence ID value(s) for the identifiable object(s) --->
										<cfset variables.occurrences="(occurrenceID: **TODO** )">
									<cfelse>
										<cfset variables.coll_object_type="#getComponents.coll_object_type#">
									</cfif>
									<li>#getComponents.ct# #variables.coll_object_type# #getComponents.part_name# #variables.occurrences#</li>
								</cfloop>
								</ul>
							</div>
							<cfif isDefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions")>
								<div class="col-12 float-left mb-4 px=0 border">
									<h1 class="h3 my-1">Change Accession for this cataloged item:</h1>
									<form name="editAccn" id="editAccnForm">
										<input type="hidden" name="method" value="updateAccn">
										<input type="hidden" name="returnformat" value="json">
										<input type="hidden" name="queryformat" value="column">
										<input type="hidden" name="collection_object_id" value="#collection_object_id#">
										<div class="form-row mb-2">
											<div class="col-12 col-md-6">
												<input type="hidden" name="accession_transaction_id" value="" id="accession_transaction_id">
												<label for="accn_number" class="data-entry-label">Accession</label>
												<input type="text" name="accn_number"  class="data-entry-input" id="accn_number">
											</div>
											<div class="col-12 col-md-3">
												<label for="collection_id_limit" class="data-entry-label">Search In:</label>
												<cfset thisCollId=#getCatalog.collection_id#>
												<select name="collection_id_limit" id="collection_id_limit" size="1" class="mb-3 mb-md-0 data-entry-select reqdClr">
													<cfloop query="ctcoll">
														<cfif #thisCollId# is #ctcoll.collection_id#><cfset selected="selected"><cfelse><cfset selected=""></cfif>
														<option value="#ctcoll.collection_id#" #selected#>#ctcoll.institution_acronym# #ctcoll.collection_cde#</option>
													</cfloop>
												</select>
											</div>
											<div class="col-12 col-md-3">
												<label for="change_accn_btn" class="data-entry-label">&nbsp;</label>
												<input type="button" id="change_accn_btn" value="Change Accession" class="btn btn-xs btn-primary" onClick="if (checkFormValidity($('##editAccnForm')[0])) { changeAccnSubmit();  } ">
												<div id="saveAccnResultDiv"></div>
											</div>
										</div>
									</form>
									<script>
										$(document).ready(function() {
											$("##editAccnForm").on("submit", function(e) {
												e.preventDefault();
											});
											makeAccessionAutocompleteLimitedMeta("accn_number","accession_transaction_id","collection_id_limit");
										});
										function changeAccnSubmit(){
											setFeedbackControlState("saveAccnResultDiv","saving")
											$.ajax({
												url : "/specimens/component/functions.cfc",
												type : "post",
												dataType : "json",
												data: $("##editAccnForm").serialize(),
												success: function (result) {
													if (result[0].status=="updated") {
														setFeedbackControlState("saveAccnResultDiv","saved")
													} else {
														setFeedbackControlState("saveAccnResultDiv","error")
														// we shouldn't be able to reach this block, backing error should return an http 500 status
														messageDialog('Error updating Accesion: '+result.DATA.MESSAGE[0], 'Error saving accession change.');
													}
												},
												error: function(jqXHR,textStatus,error){
													setFeedbackControlState("saveAccnResultDiv","error")
													handleFail(jqXHR,textStatus,error,"saving changes to Accession");
												}
											});
										};
									</script>
								</div>
							</cfif>
							<cfif isDefined("session.roles") and listcontainsnocase(session.roles,"manage_collection")>
								<div class="col-12 float-left mb-4 px=0 border">
									<!--- Edit catalog number --->
									<h1 class="h3 my-1">Change Catalog Number for this cataloged item:</h1>
									<form name="editCatNumForm" id="editCatNumForm">
										<input type="hidden" name="method" value="updateCatNumber">
										<input type="hidden" name="returnformat" value="json">
										<input type="hidden" name="queryformat" value="column">
										<input type="hidden" name="collection_object_id" value="#collection_object_id#">
										<div class="form-row">
											<div class="col-12 col-sm-4 mb-0">
												<label for="collection_id" class="data-entry-label">Collection:</label>
												<cfif isDefined("session.roles") and listcontainsnocase(session.roles,"manage_collection")>
													<!--- require manage_collection role to change collection --->
													<cfset thisCollId=#getCatalog.collection_id#>
													<select name="collection_id" size="1" class="mb-3 mb-md-0 data-entry-select reqdClr" id="collection_id">
														<cfloop query="ctcoll">
															<cfif #thisCollId# is #ctcoll.collection_id#><cfset selected="selected"><cfelse><cfset selected=""></cfif>
															<option value="#ctcoll.collection_id#" #selected#>#ctcoll.institution_acronym# #ctcoll.collection_cde#</option>
														</cfloop>
													</select>
												<cfelse>
													#getCatalog.institution_acronym#:#getCatalog.collection_cde#
													<input type="hidden" name="collection_id" value="#getCatalog.collection_id#">
												</cfif>
											</div>
											<div class="col-12 col-sm-4 mb-0">
												<label for="cat_num" class="data-entry-label">Catalog Number:</label>
												<input type="text" name="cat_num" id="cat_num" class="data-entry-input reqdClr" value="#getCatalog.cat_num#" required>
											</div>
											<div class="col-12 col-sm-4 mb-0">
												<label for="saveCatNumButton" class="data-entry-label">&nbsp;</label>
												<input type="button" value="Save" aria-label="Save Changes" class="btn btn-xs btn-primary" id="saveCatNumButton"
													onClick="if (checkFormValidity($('##editCatNumForm')[0])) { editCatNumSubmit();  } ">
												<output id="saveCatNumResultDiv" class="d-block text-danger">&nbsp;</output>
											</div>
											<script>
												function editCatNumSubmit(){
													setFeedbackControlState("saveCatNumResultDiv","saving")
													$.ajax({
														url : "/specimens/component/functions.cfc",
														type : "post",
														dataType : "json",
														data: $("##editCatNumForm").serialize(),
														success: function (result) {
															if (result[0].status=="updated") {
																setFeedbackControlState("saveCatNumResultDiv","saved")
																// reload the page with the new guid
																targetPage = "/guid/" + result[0].guid;
																console.log("targetPage: " + targetPage);
																$("##specimenDetailsPageContent").html("<h2 class=h3>Loading  " + result[0].guid + " ...</h2>");
																window.location.href = targetPage;
															} else {
																setFeedbackControlState("saveCatNumResultDiv","error")
																// we shouldn't be able to reach this block, backing error should return an http 500 status
																messageDialog('Error updating catalog number: '+result.DATA.MESSAGE[0], 'Error saving Catalog Number.');
															}
														},
														error: function(jqXHR,textStatus,error){
															setFeedbackControlState("saveCatNumResultDiv","error")
															handleFail(jqXHR,textStatus,error,"saving changes to Cat Num");
														}
													});
												};
											</script> 
										</div>
									</form>
								</div>
							</cfif>
						</div>
					</div>
				</cfloop>
			<cfcatch>
				<cfif isDefined("cfcatch.queryError") >
					<cfset queryError=cfcatch.queryError>
				<cfelse>
					<cfset queryError = ''>
				</cfif>
				<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfcontent reset="yes">
				<cfheader statusCode="500" statusText="#message#">
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert"> <img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
						</div>
					</div>
				</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getEditCatalogThread" />
	<cfreturn getEditCatalogThread.output>
</cffunction>

<!---getEditOtherIDsHTML obtain a block of html to populate an other ids editor dialog for a specimen.
 @param collection_object_id the collection_object_id for the cataloged item for which to obtain the other ids editor dialog.
 @return html for editing other ids for the specified cataloged item. 
--->
<cffunction name="getEditOtherIDsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfset variables.collection_object_id = arguments.collection_object_id>
	<cfthread name="getEditOtherIDsThread">
		<cfoutput>
			<cftry>
				<!--- Changing catalog number is a big deal, display only here editing is in catalog dialog --->
				<cfquery name="getCatalog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT 
						cataloged_item.cat_num,
						cataloged_item.collection_cde,
						collection.institution_acronym,
						cataloged_item.collection_object_id
					FROM
						cataloged_item
						join collection on cataloged_item.collection_id=collection.collection_id
					WHERE
						cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">
				</cfquery>
				<cfquery name="getIDs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT DISTINCT
						coll_obj_other_id_num.COLL_OBJ_OTHER_ID_NUM_ID,
						coll_obj_other_id_num.display_value,
						coll_obj_other_id_num.other_id_prefix,
						coll_obj_other_id_num.other_id_number,
						coll_obj_other_id_num.other_id_suffix,
						coll_obj_other_id_num.other_id_type,
						ctcoll_other_id_type.description,
						ctcoll_other_id_type.base_url,
						ctcoll_other_id_type.encumber_as_field_num
					FROM 
						cataloged_item
						join coll_obj_other_id_num on cataloged_item.collection_object_id=coll_obj_other_id_num.collection_object_id 
						left join ctcoll_other_id_type on coll_obj_other_id_num.other_id_type=ctcoll_other_id_type.other_id_type
					WHERE
						cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
				</cfquery>
				<cfquery name="ctType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT other_id_type 
					FROM ctcoll_other_id_type
				</cfquery>
				<div class="container-fluid">
					<div class="row">
						<div class="col-12">

							<!--- Add form --->
							<div class="add-form">
								<div class="add-form-header pt-1 px-2 col-12 float-left">
									<h2 class="h3 my-0 px-1 pb-1">Add other identifier for #getCatalog.institution_acronym#:#getCatalog.collection_cde#:#getCatalog.cat_num#</h2>
								</div>
								<div class="card-body mt-2">
									<form name="addOtherIDForm" id="addOtherIDForm" class="row mb-0 pt-1">
										<div class="form-row ml-3" style="display: flex;">
											<div class="col-3 pl-0 pr-2">
												<input type="hidden" name="collection_object_id" value="#getCatalog.collection_object_id#">
												<input type="hidden" name="method" value="addNewOtherID">
												<input type="hidden" name="returnformat" value="json">
												<input type="hidden" name="queryformat" value="column">
												<label class="data-entry-label" id="other_id_type">Other ID Type</label>
												<select name="other_id_type" size="1" class="reqdClr data-entry-select">
													<cfloop query="ctType">
														<option value="#ctType.other_id_type#">#ctType.other_id_type#</option>
													</cfloop>
												</select>
											</div>
											<div class="col-2 px-1">
												<label class="data-entry-label" id="other_id_prefix">Other ID Prefix</label>
												<input type="text" class="reqdClr data-entry-input" name="other_id_prefix" size="6">
											</div>
											<div class="col-3 px-1">
												<label class="data-entry-label" id="other_id_number">Other ID Number</label>
												<input type="text" class="reqdClr data-entry-input" name="other_id_number" size="6">
											</div>
											<div class="col-2 px-1">
												<label class="data-entry-label" id="other_id_suffix">Other ID Suffix</label>
												<input type="text" class="reqdClr data-entry-input" name="other_id_suffix" size="6">
											</div>
											<div class="col-2 px-1 mt-3">
												<input type="button" value="Create Identifier" class="btn btn-xs btn-primary" onClick="if (checkFormValidity($('##addOtherIDForm')[0])) { addOtherIDSubmit();  } ">
												<output id="addOtherIDResultDiv" class="d-block text-danger">&nbsp;</output>
											</div>
										</div>
									</form>
									<script>
										function addOtherIDSubmit() { 
											setFeedbackControlState("addOtherIDResultDiv","saving")
											$.ajax({
												url : "/specimens/component/functions.cfc",
												type : "post",
												dataType : "json",
												data: $("##addOtherIDForm").serialize(),
												success: function (result) {
													if (typeof result.DATA !== 'undefined' && typeof result.DATA.STATUS !== 'undefined' && result.DATA.STATUS[0]=='1') { 
														setFeedbackControlState("addOtherIDResultDiv","saved")
														reloadOtherIDDialog("#getCatalog.collection_object_id#");
													} else {
														// we shouldn't be able to reach this block, backing error should return an http 500 status
														setFeedbackControlState("addOtherIDResultDiv","error")
														messageDialog('Error adding Other IDs: '+result.DATA.MESSAGE[0], 'Error saving Other ID.');
													}
												},
												error: function(jqXHR,textStatus,error){
													setFeedbackControlState("addOtherIDResultDiv","error")
													handleFail(jqXHR,textStatus,error,"adding new Other ID");
												}
											});
										};
									</script>
								</div>
							</div>

							<!--- List/Edit existing --->
							<div class="container-fluid">
								<div class="row">
									<div class="col-12 mt-0 bg-light border rounded pt-1 pb-0 px-3">
										<h1 class="h3">Edit Existing Identifiers</h1>
										<cfset i=1>
										<cfloop query="getIDs">
											<form name="getIDs#i#" id="editOtherIDForm#i#" class="mb-0">
												<input type="hidden" name="method" value="updateOtherID" id="getIDsMethod#i#">
												<input type="hidden" name="returnformat" value="json">
												<input type="hidden" name="queryformat" value="column">
												<input type="hidden" name="collection_object_id" value="#collection_object_id#">
												<input type="hidden" name="coll_obj_other_id_num_id" value="#coll_obj_other_id_num_id#">
												<input type="hidden" name="number_of_ids" id="number_of_ids" value="#getIDs.recordcount#">
									
												<div class="row p-1 border" id="otherIDEditControls#i#">
													<div class="col-12 col-md-6 pl-1 pr-1 mb-1">
														#getIDs.other_id_type#:
														<strong> 
															<cfif getIds.base_url NEQ "">
																<a href="#getIDs.base_url##getIDs.display_value#" target="_blank">#getIDs.display_value#</a>
															<cfelse>
																#getIDs.display_value#
															</cfif>
														</strong>
													</div>
													<div class="col-12 col-md-6 pl-1 pr-1 mb-1">
														#getIDs.description#
													</div>
													<div class="form-group mb-1 col-12 col-md-3 pl-0 pr-1">
														<cfset thisType = #getIDs.other_id_type#>
														<label class="data-entry-label" for="other_id_type#i#" >Type</label>
														<select name="other_id_type" class="data-entry-select" style="" size="1" id="other_id_type#i#">
															<cfloop query="ctType">
																<cfif #thisType# is #ctType.other_id_type#><cfset selected="selected"><cfelse><cfset selected=""></cfif>
																<option #selected# value="#ctType.other_id_type#">#ctType.other_id_type#</option>
															</cfloop>
														</select>
													</div>
													<div class="form-group mb-1 col-12 col-md-2 px-1">
														<label for="other_id_prefix" class="data-entry-label" for="other_id_prefix#i#" >Prefix</label>
														<input class="data-entry-input" type="text" value="#encodeForHTML(getIDs.other_id_prefix)#" size="12" name="other_id_prefix" id="other_id_prefix#i#">
													</div>
													<div class="form-group mb-1 col-12 col-md-2 px-1">
														<label for="other_id_number" class="data-entry-label" for="other_id_number#i#" >Number</label>
														<input type="text" class="data-entry-input" value="#encodeForHTML(getIDs.other_id_number)#" size="12" name="other_id_number" id="other_id_number#i#">
													</div>
													<div class="form-group mb-1 col-12 col-md-2 px-1">
														<label for="other_id_suffix" class="data-entry-label">Suffix</label>
														<input type="text" class="data-entry-input" value="#encodeForHTML(getIDs.other_id_suffix)#" size="12" name="other_id_suffix" id="other_id_suffix#i#">
													</div>
													<div class="form-group col-12 col-md-3 px-1 mt-0 mt-md-3">
														<input type="button" value="Save" aria-label="Save Changes" class="btn btn-xs btn-primary"
															onClick="if (checkFormValidity($('##editOtherIDForm#i#')[0])) { editOtherIDsSubmit(#i#);  } ">
											
														<input type="button" value="Delete" class="btn btn-xs btn-danger" onclick="doDelete(#i#);">
														<output id="saveOtherIDResultDiv#i#"></output>
													</div>
												</div>
											</form>
											<cfset i=#i#+1>
										</cfloop>

										<script>
											function doDelete(num) {
												$("##getIDsMethod"+num).val('deleteOtherID');
												console.log($("##getIDsMethod"+num).val());
												setFeedbackControlState("saveOtherIDResultDiv"+num,"deleting")
												$.ajax({
													url : "/specimens/component/functions.cfc",
													type : "post",
													dataType : "json",
													data: $("##editOtherIDForm" + num).serialize(),
													success: function(result) { 
														if (typeof result.DATA !== 'undefined' && typeof result.DATA.STATUS !== 'undefined' && result.DATA.STATUS[0]=='1') { 
															setFeedbackControlState("saveOtherIDResultDiv" + num,"deleted")
															$("##otherIDEditControls"+num).find('input, textarea, button, select').attr("disabled", true);
															$("##otherIDEditControls"+num + " :input").val("");
															reloadOtherIDs();
														} else {
															// we shouldn't be able to reach this block, backing error should return an http 500 status
															setFeedbackControlState("saveOtherIDResultDiv" + num,"error")
															messageDialog('Error updating Other IDs: '+result.DATA.MESSAGE[0], 'Error deleting Other ID.');
														}
													},
													error: function(jqXHR,textStatus,error){
														setFeedbackControlState("saveOtherIDResultDiv"+num,"error")
														handleFail(jqXHR,textStatus,error,"deleting Other ID");
													}
												});
											};
											function editOtherIDsSubmit(num){
												$("##getIDsMethod"+num).val('updateOtherID');
												setFeedbackControlState("saveOtherIDResultDiv" + num,"saving")
												$.ajax({
													url : "/specimens/component/functions.cfc",
													type : "post",
													dataType : "json",
													data: $("##editOtherIDForm" + num).serialize(),
													success: function (result) {
														if (typeof result.DATA !== 'undefined' && typeof result.DATA.STATUS !== 'undefined' && result.DATA.STATUS[0]=='1') { 
															setFeedbackControlState("saveOtherIDResultDiv" + num,"saved")
														} else {
															// we shouldn't be able to reach this block, backing error should return an http 500 status
															setFeedbackControlState("saveOtherIDResultDiv" + num,"error")
															messageDialog('Error updating Other IDs: '+result.DATA.MESSAGE[0], 'Error saving Other ID.');
														}
													},
													error: function(jqXHR,textStatus,error){
														setFeedbackControlState("saveOtherIDResultDiv" + num,"error")
														handleFail(jqXHR,textStatus,error,"saving changes to Other IDs");
													}
												});
											};
										</script> 
									</div>
								</div>
							</div><!--- End of List/Edit existing --->

						</div>
					</div>
				</div>
			<cfcatch>
				<cfif isDefined("cfcatch.queryError") >
					<cfset queryError=cfcatch.queryError>
					<cfelse>
					<cfset queryError = ''>
				</cfif>
				<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfcontent reset="yes">
				<cfheader statusCode="500" statusText="#message#">
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert"> <img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
						</div>
					</div>
				</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getEditOtherIDsThread" />
	<cfreturn getEditOtherIDsThread.output>
</cffunction>

<cffunction name="addNewOtherID" returntype="any" access="remote" returnformat="json">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="other_id_type" type="string" required="yes">
	<cfargument name="other_id_prefix" type="string" required="no">
	<cfargument name="other_id_number" type="string" required="no">
	<cfargument name="other_id_suffix" type="string" required="no">

	<cftry>
		<cfset data=queryNew("status, message, id")>
		<cfquery name="addNewOtherID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			INSERT INTO coll_obj_other_id_num (
				collection_object_id, 
				other_id_type, 
				other_id_prefix, 
				other_id_number, 
				other_id_suffix
			) VALUES (
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.other_id_type#">,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.other_id_prefix#">,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.other_id_number#">,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.other_id_suffix#">
			)
		</cfquery>
		<cftransaction action="commit">
		<cfset t = queryaddrow(data,1)>
		<cfset t = QuerySetCell(data, "status", "1", 1)>
		<cfset t = QuerySetCell(data, "message", "Record added.", 1)>
		<cfset t = QuerySetCell(data, "id", "#collection_object_id#", 1)>
	<cfcatch>
		<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
	</cftry>
	<cfreturn data>
</cffunction>
	

<!---updateOtherID function update an other id for a cataloged item.
 @param collection_object_id the collection_object_id for the cataloged item for which to update an other id.
 @param coll_obj_other_id_num_id the primary key for the other id to update.
 @commit change
--->
<cffunction name="updateOtherID" returntype="any" access="remote" returnformat="json">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="coll_obj_other_id_num_id" type="string" required="yes">
	<cfargument name="other_id_type" type="string" required="yes">
	<cfargument name="other_id_prefix" type="string" required="no">
	<cfargument name="other_id_suffix" type="string" required="no">

	<cftry>
		<cfset data=queryNew("status, message, id")>
		<cfquery name="updateOtherID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			UPDATE coll_obj_other_id_num 
			SET
				other_id_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.other_id_type#">,
				other_id_prefix = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.other_id_prefix#">,
				other_id_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.other_id_number#">,
				other_id_suffix = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.other_id_suffix#">
			WHERE coll_obj_other_id_num_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.coll_obj_other_id_num_id#">
		</cfquery>
		<cftransaction action="commit">
		<cfset t = queryaddrow(data,1)>
		<cfset t = QuerySetCell(data, "status", "1", 1)>
		<cfset t = QuerySetCell(data, "message", "Record updated.", 1)>
		<cfset t = QuerySetCell(data, "id", "#collection_object_id#", 1)>
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		</cfcatch>
	</cftry>
	<cfreturn data>
</cffunction>

<!---deleteOtherID function delete an other id for a cataloged item.
 @param collection_object_id the collection_object_id for the cataloged item for which to delete an other id.
 @param coll_obj_other_id_num_id the primary key for the other id to delete.
 @return status of the delete operation in a json structure with status, message, and id fields.
--->
<cffunction name="deleteOtherID" returntype="any" access="remote" returnformat="json">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="coll_obj_other_id_num_id" type="string" required="yes">

	<cftry>
		<cfset data=queryNew("status, message, id")>
		<cfquery name="deleteOtherID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			DELETE FROM coll_obj_other_id_num 
			WHERE coll_obj_other_id_num_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.coll_obj_other_id_num_id#">
			AND collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">
		</cfquery>
		<cftransaction action="commit">
		<cfset t = queryaddrow(data,1)>
		<cfset t = QuerySetCell(data, "status", "1", 1)>
		<cfset t = QuerySetCell(data, "message", "Record deleted.", 1)>
		<cfset t = QuerySetCell(data, "id", "#coll_obj_other_id_num_id#", 1)>
	<cfcatch>
		<cftransaction action="rollback">
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
	</cfcatch>
	</cftry>
	<cfreturn data>	
</cffunction>

<!---getCatNumOtherIDHTML function
 @param collection_object_id
--->
<cffunction name="getCatNumOtherIDHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getOtherIDsThread">
		<cfoutput>
			<cftry>
				<cfquery name="oid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT
					coll_obj_other_id_num.display_value
					end display_value,
					coll_obj_other_id_num.other_id_type,
					case when base_url is not null then
						ctcoll_other_id_type.base_url || coll_obj_other_id_num.display_value
					else
						null
					end link
				FROM
					coll_obj_other_id_num 
					left join ctcoll_other_id_type on coll_obj_other_id_num.other_id_type=ctcoll_other_id_type.other_id_type
				where
					collection_object_id= <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
				ORDER BY
					other_id_type,
					display_value
				</cfquery>
				<div id="otherIDHTML">
					<cfloop query="theResult">
						<div class="OtherIDExistingForm">
							<form>
								<div class="container pl-1">
									<div class="col-12">
										<cfif len(oid.other_id_type) gt 0>
											<ul class="list-group">
												<cfloop query="oid">
													<li class="list-group-item">#other_id_type#:
														<cfif len(display_value) gt 0>
															<a class="external" href="##" target="_blank">#display_value#</a>
															<cfelse>
															#display_value#
														</cfif>
													</li>
												</cfloop>
											</ul>
										</cfif>
										<button type="button" value="Create New Other Identifier" class="btn btn-primary ml-2"
										onClick="$('.dialog').dialog('open'); loadNewOtherIdentifierForm(coll_obj_other_id_num_id,'newOtherIdentifierForm');">Create New Other Identifier</button>
									</div>
								</div>
							</form>
						</div>
					</cfloop>
				</div>
				<cfcatch>
					<cfoutput>
						<p class="mt-2 text-danger">Error: #cfcatch.type# #cfcatch.message# #cfcatch.detail#</p>
					</cfoutput>
				</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getOtherIDThread" />
	<cfreturn getOtherIDThread.output>
</cffunction>
<!---getCatNumOtherIDHTML function
 @param collection_object_id
--->
<cffunction name="getOtherIDHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="coll_obj_other_id_num_id" type="string" required="yes">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getOtherIDs2Thread">
		<cftry>
			<cfoutput>
				<cfquery name="oid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT
					case when status = 1 and
						concatencumbrances(coll_obj_other_id_num.collection_object_id) like '%mask original field number%' and
						ctcoll_other_id_type.encumber_as_field_num = 1
						then 'Masked'
					else
						coll_obj_other_id_num.display_value
					end display_value,
					coll_obj_other_id_num.other_id_type,
					case when base_url is not null then
						ctcoll_other_id_type.base_url || coll_obj_other_id_num.display_value
					else
						null
					end link
				FROM
					coll_obj_other_id_num 
					left join ctcoll_other_id_type on coll_obj_other_id_num.other_id_type=ctcoll_other_id_type.other_id_type
				where
					collection_object_id= <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
				ORDER BY
					other_id_type,
					display_value
			</cfquery>
				<div id="otherIDHTML">
					<cfloop query="theResult">
						<div class="OtherIDExistingForm">
							<form>
								<div class="container pl-1">
									<div class="col-12">
										<cfif len(oid.other_id_type) gt 0>
											<ul class="list-group">
												<cfloop query="oid">
													<li class="list-group-item">#other_id_type#:
														<cfif len(display_value) gt 0>
															<a class="external" href="##" target="_blank">#display_value#</a>
															<cfelse>
															#display_value#
														</cfif>
													</li>
												</cfloop>
											</ul>
										</cfif>
										<button type="button" value="Create New Other Identifier" class="btn btn-primary ml-2"
										onClick="$('.dialog').dialog('open'); loadNewOtherIdentifierForm(coll_obj_other_id_num_id,'newOtherIdentifierForm');">Create New Other Identifier</button>
									</div>
								</div>
							</form>
						</div>
					</cfloop>
					<!--- theResult ---> 
				</div>
			</cfoutput>
			<cfcatch>
				<cfoutput>
					<p class="mt-2 text-danger">Error: #cfcatch.type# #cfcatch.message# #cfcatch.detail#</p>
				</cfoutput>
			</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getOtherID2Thread" />
	<cfreturn getOtherID2Thread.output>
</cffunction>

<cffunction name="getOtherIDTable" returntype="query" access="remote">
	<cfargument name="coll_obj_other_id_num_id" type="string" required="yes">
	<cfset r=1>
	<cftry>
		<cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select 1 as status, coll_obj_other_id_num_id, collection_object_id, other_id_type, other_id_prefix, other_id_number, display_name
			from coll_obj_other_id_num
			where coll_obj_other_id_num_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#coll_obj_other_id_num_id#">
		</cfquery>
		<cfif theResult.recordcount eq 0>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "0", 1)>
			<cfset t = QuerySetCell(theResult, "message", "No shipments found.", 1)>
		</cfif>
		<cfcatch>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "-1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "#cfcatch.type# #cfcatch.message# #cfcatch.detail#", 1)>
		</cfcatch>
	</cftry>
	<cfif isDefined("asTable") AND asTable eq "true">
		<cfreturn resulthtml>
		<cfelse>
		<cfreturn theResult>
	</cfif>
</cffunction>

<cffunction name="saveOtherID" access="remote" returntype="any" returnformat="json">>
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="coll_obj_other_id_num_id" type="string" required="yes">
	<cfargument name="other_id_type" type="string" required="yes">
	<cfargument name="other_id_prefix" type="string" required="no">
	<cfargument name="other_id_number" type="string" required="yes">
	<cfargument name="other_id_suffix" type="string" required="no">
	<cfargument name="display_value" type="string" required="yes">
	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="updateOtherIDCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="newOtherIDCheck_result">
				SELECT count(*) as ct from coll_obj_other_id_num
				WHERE
					coll_obj_other_id_num_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value='#coll_obj_other_id_num_id#'>
			</cfquery>
			<cfif updateOtherIDCheck.ct NEQ 1>
				<cfthrow message = "Unable to update other ID. Provided coll_obj_other_num_id does not match a record in the ID table.">
			</cfif>
			<cfquery name="updateOtherID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateOtherID">
				UPDATE coll_obj_other_id_num SET
					coll_obj_other_id_num_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#coll_obj_other_id_num_id#">,
					other_id_type = <cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#other_id_type#">,
					other_id_prefix = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#other_id_prefix#">,
					other_id_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#other_id_number#">,
					other_id_suffix = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#other_id_suffix#">,
					display_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#display_value#">
				where
					coll_obj_other_id_num_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#coll_obj_other_id_num_id#">
			</cfquery>
			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["id"] = "#coll_obj_other_id_num_id#">
			<cfset data[1] = row>
			<cftransaction action="commit">
			<cfcatch>
				<cftransaction action="rollback">
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
				<cfabort>
			</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>
						
<!---
  getEditCollectorsHTML
  Returns an HTML block to populate an edit dialog for collectors or preparators for a cataloged item.
  @param collection_object_id the cataloged item for which to edit collectors/preparators.
  @param target specifies whether to edit collectors, preparators, or both.
  @return html for editing the collectors/preparators of a cataloged item.
  @see getCollectorsDetailHTML for the HTML block listing current collectors/preparators.
--->
<cffunction name="getEditCollectorsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="target" type="string" required="yes">

	<cfset variables.collection_object_id = arguments.collection_object_id>
	<cfset variables.target = arguments.target>

	<cfif variables.target NEQ "collector" AND variables.target NEQ "preparator">
		<cfset variables.target = "both">
	</cfif>

	<cfthread name="getCollectorsThread">
		<cftry>
			<cfoutput>
				<div id="collectorsHTML">
					<div class="container-fluid">
						<div class="row">
							<div class="col-12 float-left">
								<div class="add-form float-left">
									<cfset targetLabel = "">
									<cfset targetValue = "">
									<div class="add-form-header pt-1 px-2 col-12 float-left">
										<h2 class="h3 my-0 px-1 pb-1">
											<cfif variables.target is "collector">
												Add Collector
												<cfset targetLabel = "Collector">
												<cfset targetValue = "c">
											<cfelseif variables.target is "preparator">
												Add Preparator
												<cfset targetLabel = "Preparator">
												<cfset targetValue = "p">
											<cfelse>
												Add Collector or Preparator
												<cfset targetLabel = "Agent">
												<cfset targetValue = "c"><!--- default selection to collector --->
											</cfif>
										</h2>
									</div>
									<div class="card-body">
										<!--- Form to add a new collector/preparator --->
										<form name="addToCollectors" onSubmit="return false;">
											<input type="hidden" name="collection_object_id" value="#variables.collection_object_id#">
											<input type="hidden" name="method" value="addCollector">
											<input type="hidden" name="returnformat" value="json">
											<input type="hidden" name="queryformat" value="column">
											<div class="form-row">
												<cfif target EQ "both">
													<cfset colw ="4">
												<cfelse>
													<cfset colw ="6">
												</cfif>
												<div class="col-12 col-md-#colw# pt-3 px-2">
													<label for="add_agent_name">
														Add #targetLabel#:
													</label>
													<input type="text" name="name" id="add_agent_name" class="data-entry-input reqdClr">
													<input type="hidden" name="agent_id" id="add_new_agent_id">
												</div>
												<cfif target EQ "both">
													<div class="col-12 col-md-2 pt-3 px-2">
														<label for="add_collector_role">Role:</label>
														<select name="collector_role" id="add_collector_role" class="data-entry-input reqdClr">
															<cfset selected = "">
															<cfif targetValue EQ "c">
																<cfset selected = "selected">
															</cfif>
															<option value="c" #selected#>collector</option>
															<cfset selected = "">
															<cfif targetValue EQ "p">
																<cfset selected = "selected">
															</cfif>
															<option value="p" #selected#>preparator</option>
														</select>
													</div>
												<cfelse>
													<input type="hidden" name="collector_role" value="#targetValue#">
												</cfif>
												<div class="col-12 col-md-2 pt-3 px-2">
													<label for="add_coll_order">Order:</label>
													<cfquery name="collCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
														SELECT count(*) as cnt
														FROM collector
														WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">
															<cfif variables.target is "collector">
																AND collector_role = 'c'
															<cfelseif variables.target is "preparator">
																AND collector_role = 'p'
															</cfif>
													</cfquery>
													<select name="coll_order" id="add_coll_order" class="data-entry-input reqdClr">
														<cfset countPlusOne = collCount.cnt + 1>
														<cfloop from="1" to="#countPlusOne#" index="c">
															<option value="#c#" <cfif c EQ countPlusOne>selected</cfif>>#c#</option>
														</cfloop>
													</select>
												</div>
												<div class="col-12 col-md-4 pt-3">
													<label for="addButton" class="data-entry-label">&nbsp;</label>
													<input type="button" value="Add" class="btn btn-xs btn-primary" id="addButton" onClick=" handleAddCollector(); ">
													<output id="addButtonResultDiv"></output>
												</div>
											</div>
										</form>
										<script>
											jQuery(document).ready(function() {
												makeAgentAutocompleteMeta("add_agent_name", "add_new_agent_id", true);
											});
											function reloadCollectorsDialogAndPage() { 
												<cfif variables.target is 'collector' or variables.target EQ 'both'>
													reloadLocality();
												<cfelseif variables.target is 'preparator' or variables.target EQ 'both'>
													reloadPreparators();
												</cfif>
												loadCollectorsList("#variables.collection_object_id#", "collectorsDialogList", "#variables.target#");
											}
											function loadCollectorsList(collection_object_id, targetDiv, target) {
												$.ajax({
													url : "/specimens/component/functions.cfc",
													type : "post",
													dataType : "html",
													data: {
														method: "getCollectorsDetailHTML",
														collection_object_id: collection_object_id,
														target: target,
														returnformat: "plain"
													},
													success: function(result) {
														$("##" + targetDiv).html(result);
													},
													error: function(jqXHR,textStatus,error){
														handleFail(jqXHR,textStatus,error,"loading collectors list");
													}
												});
											}
											function handleAddCollector(){
												if (checkFormValidity($('form[name="addToCollectors"]')[0])) {
													setFeedbackControlState("addButtonResultDiv","saving")
													$.ajax({
														url : "/specimens/component/functions.cfc",
														type : "post",
														dataType : "json",
														data: $("form[name='addToCollectors']").serialize(),
														success: function(result) { 
															if (result[0].status=="added") {
																setFeedbackControlState("addButtonResultDiv","saved")
																reloadCollectorsDialogAndPage();
															} else {
																setFeedbackControlState("addButtonResultDiv","error")
																messageDialog('Error adding collector/preparator: '+result.DATA.MESSAGE[0], 'Error adding collector/preparator.');
															}
															<!--- add an entry to the list of orders one larger than the current highest --->
															<!--- Find max value among the current options --->
															var max = 0;
															$("##add_coll_order").find('option').each(function() {
																var val = parseInt($(this).val(), 10);
																if (!isNaN(val) && val > max) {
																	max = val;
																}
															});
															<!--- deselect options --->
															$("##add_coll_order").find('option:selected').prop('selected', false);
															<!--- Add a new option with value one more than the max in a selected state --->
															var newVal = max + 1;
															$("##add_coll_order").append(
																$('<option>', { value: newVal, text: newVal, selected: true })
															);
															$("##add_agent_name").val("");
															$("##add_new_agent_id").val("");
														},
														error: function(jqXHR,textStatus,error){
															setFeedbackControlState("addButton","error")
															handleFail(jqXHR,textStatus,error,"adding collector/preparator");
														}
													});
												}
											}
										</script>
									</div><!--- end card-body for add form --->
								</div><!--- end add-form --->
								<div id="collectorsDialogList" class="col-12 float-left mt-4 mb-4 px-0">
									<!--- include output from getCollectorsDetailHTML to list collectors/preparators for the cataloged item --->
									<cfset collectorsList = getCollectorsDetailHTML(collection_object_id=variables.collection_object_id, target=variables.target)>
								</div>
							</div><!--- end col-12 --->
						</div><!--- end row --->
					</div><!--- end container-fluid --->
				</div><!--- end collectorsHTML --->
			</cfoutput>
			<cfcatch>
				<cfoutput>
					<cfset error_message = cfcatchToErrorMessage(cfcatch)>
					<p class="mt-2 text-danger">Error: #cfcatch.type# #error_message#</p>
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
						<cfdump var="#cfcatch#">
					</cfif>
				</cfoutput>
			</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getCollectorsThread" />
	<cfreturn getCollectorsThread.output>
</cffunction>

<!---
	getCollectorsDetailHTML
	Returns an HTML block listing collectors or preparators for a cataloged item, with edit and remove buttons.
	@param collection_object_id the cataloged item for which to show collectors/preparators.
	@param target specifies whether to list collectors, preparators, or both.
	@return html showing the collectors/preparators of a cataloged item.
	@see getEditCollectorsHTML which calls this function.
--->
<cffunction name="getCollectorsDetailHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="target" type="string" required="yes">

	<cfset variables.collection_object_id = arguments.collection_object_id>
	<cfset variables.target = arguments.target>

	<cfif variables.target NEQ "collector" AND variables.target NEQ "preparator">
		<cfset variables.target = "both">
	</cfif>

	<cftry>
		<cfquery name="getColls" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT
				collector.collector_id,
				agent_name, 
				collector_role,
				coll_order,
				collector.agent_id
			FROM
				cataloged_item
				join collector on collector.collection_object_id = cataloged_item.collection_object_id 
				join preferred_agent_name on collector.agent_id = preferred_agent_name.agent_id 
			WHERE
				collector.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">
				<cfif variables.target is 'collector'>
					AND collector_role = 'c'
				<cfelseif variables.target is 'preparator'>
					AND collector_role = 'p'
				</cfif>
			ORDER BY 
				collector_role, coll_order
		</cfquery>
		<!--- find max value for coll_order --->
		<cfquery name="collOrderMax" dbtype="query">
			SELECT MAX(coll_order) AS max_order FROM getColls
		</cfquery>
		<cfset maxCollOrder = Val(collOrderMax.max_order) + 1>
		<cfoutput>
			<h2 class="h3">Current
				<cfif variables.target is "collector">
					Collectors
				<cfelseif variables.target is "preparator">
					Preparators
				<cfelse>
					Collectors and Preparators
				</cfif>
			</h2>
			<cfif getColls.recordcount EQ 0>
				<ul>
					<li>None</li>
				</ul>
			</cfif>
			<cfset i=1>
			<cfloop query="getColls">
				<div class="border border-secondary my-0">
					<form name="colls#i#" id="colls#i#" class="w-100" onSubmit="return false;">
						<input type="hidden" name="method" id="coll_method_#i#" value="">
						<input type="hidden" name="returnformat" value="json">
						<input type="hidden" name="queryformat" value="column">
						<input type="hidden" name="collector_id" id="collector_id_#i#" value="#getColls.collector_id#">
						<input type="hidden" name="collection_object_id" id="collection_object_id_#i#" value="#variables.collection_object_id#">
						<input type="hidden" name="collector_role" id="collector_role_#i#" value="#getColls.collector_role#">
						<div class="form-row">
							<div class="col-12 col-md-6 px-2">
								<cfif getColls.collector_role EQ "c">
									<cfset role="Collector">
								<cfelse>
									<cfset role="Preparator">
								</cfif>
								<label for="agent_name_#i#" class="data-entry-label">#role#</label>
								<input type="text" name="agent_name" id="agent_name_#i#" class="data-entry-input reqdClr" value="#getColls.agent_name#">
								<input type="hidden" name="agent_id" id="agent_id_#i#" value="#getColls.agent_id#">
							</div>
							<div class="col-12 col-md-2 px-2">
								<label class="data-entry-label">Order:</label>
								<select class="data-entry-select" name="coll_order" id="coll_order_#i#">
									<cfloop from="1" to="#maxCollOrder#" index="ci">
										<cfset selected = "">
										<cfif ci EQ getColls.coll_order>
											<cfset selected = "selected">
										</cfif>
										<option value="#ci#" #selected#>#ci#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-4 pt-3 px-2">
								<input type="button" value="Save" class="btn btn-xs btn-primary" onclick=" updateCollector('#i#');">
								<input type="button" value="Remove" class="btn btn-xs btn-danger" onClick=" confirmDialog('Remove this #role#?', 'Confirm Delete #role#', function() { removeCollector('#i#'); }  );">
								<output id="coll_output_#i#"></output>
							</div>
						</div>
					</form>
					<script>
						jQuery(document).ready(function() {
							makeAgentAutocompleteMeta("agent_name_#i#", "agent_id_#i#", true);
						});
					</script>
				</div>
				<cfset i = i + 1>
			</cfloop>
			<script>
				function removeCollector(formId) {
					$("##coll_method_" + formId).val("removeCollector");
					setFeedbackControlState("coll_output_" + formId,"deleting")
					$.ajax({
						url: "/specimens/component/functions.cfc",
						type: "POST",
						dataType : "json",
						data: $("##colls" + formId).serialize(),
						success: function(response) {
							if (response[0].status=="removed") {
								setFeedbackControlState("coll_output_" + formId,"removed")
								<cfif variables.target is 'collector' or variables.target EQ 'both'>
									reloadLocality();
								<cfelseif variables.target is 'preparator' or variables.target EQ 'both'>
									reloadPreparators();
								</cfif>
								loadCollectorsList("#variables.collection_object_id#", "collectorsDialogList", "#variables.target#");
							} else {
								setFeedbackControlState("coll_output_" + formId,"error")
							}
						},
						error: function(xhr, status, error) {
							setFeedbackControlState("coll_output_" + formId,"error")
							handleFail(xhr,status,error,"removing collector/preparator");
						}
					});
				}
				function updateCollector(formId) { 
					$("##coll_method_" + formId).val("updateCollector");
					setFeedbackControlState("coll_output_" + formId,"deleting")
					$.ajax({
						url: "/specimens/component/functions.cfc",
						type: "POST",
						dataType: "json",
						data: $("##colls" + formId).serialize(),
						success: function(response) {
							if (response[0].status=="saved") {
								setFeedbackControlState("coll_output_" + formId,"saved")
								<cfif variables.target is 'collector' or variables.target EQ 'both'>
									reloadLocality();
								<cfelseif variables.target is 'preparator' or variables.target EQ 'both'>
									reloadPreparators();
								</cfif>
								loadCollectorsList("#variables.collection_object_id#", "collectorsDialogList", "#variables.target#");
							} else {
								setFeedbackControlState("coll_output_" + formId,"error")
							}
						},
						error: function(xhr, status, error) {
							setFeedbackControlState("coll_output_" + formId,"error")
							handleFail(xhr,status,error,"updating collector/preparator");
						}
					});
					
				}
			</script>
		</cfoutput>
		<cfcatch>
			<cfoutput>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<p class="mt-2 text-danger">Error: #cfcatch.type# #error_message#</p>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
					<cfdump var="#cfcatch#">
				</cfif>
			</cfoutput>
		</cfcatch>
	</cftry>
</cffunction>

<!--- addCollector function adds a new collector or preparator to a cataloged item, handling order conflicts, 
   and ensuring sequential order of collectors/preparators.
 @param collection_object_id the collection_object_id for the cataloged item to which to add the collector/preparator.
 @param agent_id the agent_id of the collector/preparator to add.
 @param collector_role specifies whether the collector is a collector or preparator.
 @param coll_order specifies the order of the collector/preparator in relation to other collectors/preparators for this cataloged item.
 @return status of the add operation in a json structure with status=saved and id field or an http 500 error.
--->
<cffunction name="addCollector" returntype="any" access="remote" returnformat="json">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="agent_id" type="string" required="yes">
	<cfargument name="collector_role" type="string" required="yes">
	<cfargument name="coll_order" type="numeric" required="yes">

	<cfset variables.collection_object_id = arguments.collection_object_id>
	<cfset variables.agent_id = arguments.agent_id>
	<cfset variables.collector_role = arguments.collector_role>
	<cfset variables.coll_order = arguments.coll_order>

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<!--- Step 1: Check if a collision in coll_order occurs for this collection_object and role --->
			<cfquery name="checkCollision" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT COUNT(*) AS collisionCount
				FROM collector
				WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">
					AND collector_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.collector_role#">
					AND coll_order = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#arguments.coll_order#">
			</cfquery>
			<!--- Step 2: Shift coll_order values if a collision with the to be inserted record would occur --->
			<cfif checkCollision.collisionCount GT 0>
				<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE collector
						SET coll_order = coll_order + 1
						WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">
							AND collector_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.collector_role#">
							AND coll_order >= <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#arguments.coll_order#">
				</cfquery>
			</cfif>
			<!--- Step 3: insert the new record --->
			<cfquery name="addCollectorQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="addCollectorQuery_result">
				INSERT INTO collector (collection_object_id, agent_id, collector_role, coll_order)
				VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.agent_id#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.collector_role#">,
					<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#arguments.coll_order#">
				)
			</cfquery>
			<!--- get the inserted collector_id --->
			<cfset rowid = addCollectorQuery_result.generatedkey>
			<cfquery name="getCollectorId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT collector_id
				FROM collector
				WHERE  ROWIDTOCHAR(rowid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#rowid#">
			</cfquery>
			<!--- Step 4: ensure that coll_order is a sequential integer, starting at 1 for a given collection_object_id and collector_role --->
			<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				MERGE INTO collector tgt
				USING (
					SELECT collector_id,
						   ROW_NUMBER() OVER (
							 ORDER BY coll_order, collector_id
						   ) AS new_order
					FROM collector
					WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">
					  AND collector_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.collector_role#">
				) src
				ON (tgt.collector_id = src.collector_id)
				WHEN MATCHED THEN
				  UPDATE SET tgt.coll_order = src.new_order
			</cfquery>
			<cfset row = StructNew()>
			<cfset row["status"] = "added">
			<cfset row["id"] = "#getCollectorId.collector_id#">
			<cfset data[1] = row>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- removeCollector function removes a collector or preparator from a cataloged item, ensuring that the order of 
   remaining collectors/preparators is sequential starting at one.
 @param collector_id the collector_id of the collector/preparator to remove.
 @param collection_object_id the collection_object_id for the cataloged item from which to remove the collector/preparator.
 @param agent_id the agent_id of the collector/preparator to remove.
 @return status of the remove operation in a json structure with status=removed and id field or an http 500 error.
--->
<cffunction name="removeCollector" returntype="any" access="remote" returnformat="json">
	<cfargument name="collector_id" type="string" required="yes">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="agent_id" type="string" required="yes">

	<cfset variables.collector_id = arguments.collector_id>
	<cfset variables.collection_object_id = arguments.collection_object_id>
	<cfset variables.agent_id = arguments.agent_id>

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<!--- obtain the role for the collector/preparator to be removed (to renumber the others) --->
			<cfquery name="getRole" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getRole_result">
				SELECT collector_role
				FROM collector
				WHERE 
					collector_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collector_id#">
			</cfquery>
			<cfquery name="removeCollectorQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="removeCollectorQuery_result">
				DELETE FROM collector
				WHERE 
					collector_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collector_id#">
					AND collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">
					AND agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.agent_id#">
			</cfquery>
			<cfif removeCollectorQuery_result.recordcount NEQ 1>
				<cfthrow message = "Unable to remove collector. Provided collector_id [#variables.collector_id#], collection_object_id [#variables.collection_objecT_id#], agent_id [#variables.agent_id#]  does not match a record in the collector table.">
			</cfif>
			<!--- Step 2: ensure that coll_order is a sequential integer, starting at 1 for a given collection_object_id and collector_role --->
			<cfquery name="resetOrder" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				MERGE INTO collector tgt
				USING (
					SELECT collector_id,
						   ROW_NUMBER() OVER (
							 ORDER BY coll_order, collector_id
						   ) AS new_order
					FROM collector
					WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">
					  AND collector_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getRole.collector_role#">
				) src
				ON (tgt.collector_id = src.collector_id)
				WHEN MATCHED THEN
				  UPDATE SET tgt.coll_order = src.new_order
			</cfquery>
			<cfset row = StructNew()>
			<cfset row["status"] = "removed">
			<cfset row["id"] = "#reReplace(variables.collector_id,'[^0-9]','')#">
			<cfset data[1] = row>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- updateCollector given changed information about a collector record, update (agent and order) 
    for that record. 
  @param collector_id the primary key value of the collector record to update.
  @param collection_object_id the collection_object_id for the cataloged item that was collected/prepared, 
    used to verify the target collector record, is not updated by this method.
  @param agent_id the new agent_id for the collector record.
  @param collector_role the role of the agent (c for collector, p for preparator)
  @param coll_order the new order of the collector record for the cataloged item and collector_role.
  @return a json structure with status=saved and id fields indicating the result of the update operation or an http 500 error.
--->
<cffunction name="updateCollector" returntype="any" access="remote" returnformat="json">
	<cfargument name="collector_id" type="string" required="yes">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="agent_id" type="string" required="yes">
	<cfargument name="collector_role" type="string" required="yes">
	<cfargument name="coll_order" type="numeric" required="yes">

	<cfset variables.collector_id = arguments.collector_id>
	<cfset variables.collection_object_id = arguments.collection_object_id>
	<cfset variables.agent_id = arguments.agent_id>
	<cfset variables.collector_role = arguments.collector_role>
	<cfset variables.coll_order = arguments.coll_order>
	
	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<!--- Step 1: Check if a collision in coll_order occurs for this collection_object and role --->
			<cfquery name="checkCollision" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT COUNT(*) AS collisionCount
				FROM collector
				WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">
					AND collector_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.collector_role#">
					AND coll_order = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#variables.coll_order#">
					AND collector_id <> <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collector_id#">
			</cfquery>
			<!--- Step 2: Shift coll_order values if a collision with the to be inserted record would occur --->
			<cfif checkCollision.collisionCount GT 0>
				<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)# ">
					UPDATE collector
					SET coll_order = coll_order + 1
					WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">
						AND collector_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.collector_role#">
						AND coll_order >= <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#variables.coll_order#">
						AND collector_id <> <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collector_id#">
				</cfquery>
			</cfif>
			<!--- Step 3: Update the collector record --->
			<cfquery name="updateCollectorQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateCollectorQuery_result">
				UPDATE collector
				SET 
					agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.agent_id#">,
					collector_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.collector_role#">,
					coll_order = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#variables.coll_order#">
				WHERE 
					collector_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collector_id#">
					AND collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">
			</cfquery>
			<cfif updateCollectorQuery_result.recordcount NEQ 1>
				<cfthrow message = "Unable to update collector. Provided collector_id [#variables.collector_id#], collection_object_id [#variables.collection_object_id#] does not match a record in the collector table.">
			</cfif>
			<!--- Step 4: ensure that coll_order is a sequential integer, starting at 1 for a given collection_object_id and collector_role --->
			<cfquery name="resetOrder" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				MERGE INTO collector tgt
				USING (
					SELECT collector_id,
						   ROW_NUMBER() OVER (
							 ORDER BY coll_order, collector_id
						   ) AS new_order
					FROM collector
					WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">
					  AND collector_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.collector_role#">
				) src
				ON (tgt.collector_id = src.collector_id)
				WHEN MATCHED THEN
				  UPDATE SET tgt.coll_order = src.new_order
			</cfquery>
			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["id"] = "#reReplace(variables.collector_id,'[^0-9]','')#">
			<cfset data[1] = row>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>			
</cffunction>

<!--- TODO: Incomplete add determiner function --->
<cffunction name="getAgentIdentifiers" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfset variables.collection_object_id = arguments.collection_object_id>

	<cfthread name="getAgentIdentsThread">
		<cfoutput>
			<cftry>
				<cfthrow message = "TODO: getAgentIdentifiers needs implementation">
			<cfcatch>
				<cftransaction action="rollback">
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
				<cfabort>
			</cfcatch>
			</cftry>
		</cfoutput> 
	</cfthread>
	<cfthread action="join" name="getAgentIdentsThread" />
	<cfreturn getAgentIdentsThread.output>
</cffunction>

<cffunction name="getEditPartsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfset variables.collection_object_id = arguments.collection_object_id>
	<!--- TODO: Cases to handle: 
	  One Cataloged Item, one occurrence, one or more parts, each a material sample, each part in one container.
	  One Cataloged Item, a set of parts may be a separate occurrence with a separate identification history, each part a material sample, each part in one container, need occurrence ids for additional parts after the first, need rows in at least digir_filtered_flat for additional occurrences.
	  More than one cataloged item, each a separate occurrence, with a set of parts, each part a material sample, parts may be in the same collection object container (thus loanable only as a unit).
   --->
	<cfthread name="getEditPartsThread">
		<cftry>
			<cfquery name="collcode" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select collection_cde from cataloged_item where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
			</cfquery>
			<cfquery name="ctDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select coll_obj_disposition from ctcoll_obj_disp order by coll_obj_disposition
			</cfquery>
			<cfquery name="ctModifiers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select modifier from ctnumeric_modifiers order by modifier desc
			</cfquery>
			<cfquery name="ctPreserveMethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select preserve_method
				from ctspecimen_preserv_method
				where collection_cde = '#collcode.collection_cde#'
				order by preserve_method
			</cfquery>
			<cfquery name="rparts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select
					specimen_part.collection_object_id part_id,
					pc.label label,
					nvl2(preserve_method, part_name || ' (' || preserve_method || ')',part_name) part_name,
					sampled_from_obj_id,
					coll_object.COLL_OBJ_DISPOSITION part_disposition,
					coll_object.CONDITION part_condition,
					nvl2(lot_count_modifier, lot_count_modifier || lot_count, lot_count) lot_count,
					coll_object_remarks part_remarks,
					attribute_type,
					attribute_value,
					attribute_units,
					determined_date,
					attribute_remark,
					agent_name
				from
					specimen_part,
					coll_object,
					coll_object_remark,
					coll_obj_cont_hist,
					container oc,
					container pc,
					specimen_part_attribute,
					preferred_agent_name
				where
					specimen_part.collection_object_id=specimen_part_attribute.collection_object_id (+) and
					specimen_part_attribute.determined_by_agent_id=preferred_agent_name.agent_id (+) and
					specimen_part.collection_object_id=coll_object.collection_object_id and
					coll_object.collection_object_id=coll_obj_cont_hist.collection_object_id and
					coll_object.collection_object_id=coll_object_remark.collection_object_id (+) and
					coll_obj_cont_hist.container_id=oc.container_id and
					oc.parent_container_id=pc.container_id (+) and
					specimen_part.derived_from_cat_item = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
			</cfquery>
			<cfquery name="parts" dbtype="query">
				select
					part_id,
					label,
					part_name,
					sampled_from_obj_id,
					part_disposition,
					part_condition,
					lot_count,
					part_remarks
				from
					rparts
				group by
					part_id,
					label,
					part_name,
					sampled_from_obj_id,
					part_disposition,
					part_condition,
					lot_count,
					part_remarks
				order by
					part_name
			</cfquery>
			<cfquery name="mPart" dbtype="query">
				select * from parts where sampled_from_obj_id is null order by part_name
			</cfquery>
			<cfset ctPart.ct=''>
			<cfquery name="ctPart" dbtype="query">
				select count(*) as ct from parts group by lot_count order by part_name
			</cfquery>
			<cfoutput>
				<div class="container-fluid">
					<div class="row">
						<div class="col-12 mt-1">
							<form>
								<h1 class="h3 px-1">Edit Existing Parts</h1>
								<table class="table border-bottom mb-0">
									<thead>
										<tr class="bg-light">
											<th><span>Part Name</span></th>
											<th><span>Condition</span></th>
											<th><span>Disposition</span></th>
											<th><span>##</span></th>
											<th><span>Container</span></th>
										</tr>
									</thead>
									<tbody>
										<cfset i=1>
										<cfloop query="mPart">
											<tr <cfif mPart.recordcount gt 1>class=""<cfelse></cfif>>
												<td><input class="data-entry-input" value="#part_name#"></td>
												<td><input class="data-entry-input" size="7" value="#part_condition#"></td>
												<td><input class="data-entry-input" size="7" value="#part_disposition#"></td>
												<td><input class="data-entry-input" size="2" value="#lot_count#"></td>
												<td><input class="data-entry-input" value="#label#"></td>
											</tr>
											<cfif len(part_remarks) gt 0>
												<tr class="small">
													<td colspan="5"><span class="d-block"><span class="font-italic pl-1">Remarks:</span>
														<input class="w-100" type="text" value="#part_remarks#">
														</span></td>
												</tr>
											</cfif>
											<cfquery name="patt" dbtype="query">
												select
													attribute_type,
													attribute_value,
													attribute_units,
													determined_date,
													attribute_remark,
													agent_name
												from
													rparts
												where
													attribute_type is not null and
													part_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
												group by
													attribute_type,
													attribute_value,
													attribute_units,
													determined_date,
													attribute_remark,
													agent_name
											</cfquery>
											<cfif patt.recordcount gt 0>
												<tr>
													<td colspan="5"><cfloop query="patt">
															<div class="small pl-3" style="line-height: .9rem;">
																<input type="text" class="" value="#attribute_type#">
																=
																<input class="" value="#attribute_value#">
																<cfif len(attribute_units) gt 0>
																	<input type="text" class="" value="#attribute_units#">
																</cfif>
																<cfif len(determined_date) gt 0>
																	determined date =
																	<input type="text" class="" value="#dateformat(determined_date,"yyyy-mm-dd")#">
																</cfif>
																<cfif len(agent_name) gt 0>
																	determined by =
																	<input type="text" class="" value="#agent_name#">
																</cfif>
																<cfif len(attribute_remark) gt 0>
																	remark =
																	<input type="text" class="" value="#attribute_remark#">
																</cfif>
															</div>
														</cfloop></td>
												</tr>
											</cfif>
											<cfquery name="sPart" dbtype="query">
												select * from parts where sampled_from_obj_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
											</cfquery>
											<cfloop query="sPart">
												<tr>
													<td><span class="d-inline-block pl-3">#part_name# <span class="font-italic">subsample</span></span></td>
													<td>#part_condition#</td>
													<td>#part_disposition#</td>
													<td>#lot_count#</td>
													<td>#label#</td>
												</tr>
												<cfif len(part_remarks) gt 0>
													<tr class="small">
														<td colspan="5"><span class="pl-3 d-block"> <span class="font-italic">Remarks:</span>
															<input class="" type="text" value="#part_remarks#">
															</span></td>
													</tr>
												</cfif>
											</cfloop>
										</cfloop>
									</tbody>
								</table>
							</form>
							<div class="col-8 px-0 mt-3">
								<div id="accordionNewPart">
									<div class="card">
										<div class="card-header pt-1" id="headingNewPart">
											<h1 class="my-0 px-1">
												<button class="btn btn-link text-left collapsed" data-toggle="collapse" data-target="##collapseNewPart" aria-expanded="true" aria-controls="collapseNewPart"> <span class="h4">Add Specimen Part</span> </button>
											</h1>
										</div>
										<div id="collapseNewPart" class="collapse" aria-labelledby="headingNewPart" data-parent="##accordionNewPart">
											<div class="card-body mt-2"> <a name="newPart"></a>
												<form name="newPart">
													<input type="hidden" name="Action" value="newPart">
													<input type="hidden" name="collection_object_id" value="#collection_object_id#">
													<table class="table table-light border-0 col-12 px-0 mb-2">
														<tr>
															<td class="border-0"><div align="right">Part Name: </div></td>
															<td class="border-0"><input type="text" name="part_name" id="part_name" class="reqdClr"
																	onchange="findPart(this.id,this.value,'#collcode.collection_cde#');"
																	onkeypress="return noenter(event);"></td>
														</tr>
														<tr>
															<td class="border-0"><div align="right">Preserve Method: </div></td>
															<td class="border-0"><select name="preserve_method" size="1"  class="reqdClr">
																	<cfloop query="ctPreserveMethod">
																		<option value="#ctPreserveMethod.preserve_method#">#ctPreserveMethod.preserve_method#</option>
																	</cfloop>
																</select>
															</td>
														</tr>
														<tr>
															<td class="border-0"><div align="right">Count:</div></td>
															<td class="border-0"><select name="lot_count_modifier" size="1">
																	<option value=""></option>
																	<cfloop query="ctModifiers">
																		<option value="#ctModifiers.modifier#">#ctModifiers.modifier#</option>
																	</cfloop>
																</select>
																<input type="text" name="lot_count" class="reqdClr" size="2"></td>
														</tr>
														<tr>
															<td class="border-0"><div align="right">Disposition:</div></td>
															<td class="border-0">
																<select name="coll_obj_disposition" size="1"  class="reqdClr">
																	<cfloop query="ctDisp">
																		<option value="#ctDisp.coll_obj_disposition#">#ctDisp.coll_obj_disposition#</option>
																	</cfloop>
																</select>
															</td>
														</tr>
														<tr>
															<td class="border-0"><div align="right">Condition:</div></td>
															<td class="border-0"><input type="text" name="condition" class="reqdClr"></td>
														</tr>
														<tr>
															<td class="border-0" style="width: 200px;"><div align="right">Remarks:</div></td>
															<td class="border-0"><input type="text" name="coll_object_remarks" size="50"></td>
														</tr>
														<tr>
															<td colspan="2" class="border-0">
																<div align="center">
																	<input type="submit" value="Create" class="btn btn-xs btn-primary">
																</div>
															</td>
														</tr>
													</table>
												</form>
											</div>
										</div>
									</div>
								</div>
							</div>
						</div>
					</div>
				</div>
			</cfoutput>
			<cfcatch>
				<cfoutput>
					<cfif isDefined("cfcatch.queryError") >
						<cfset queryError=cfcatch.queryError>
						<cfelse>
						<cfset queryError = ''>
					</cfif>
					<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
					<cfcontent reset="yes">
					<cfheader statusCode="500" statusText="#message#">
					<div class="container">
						<div class="row">
							<div class="alert alert-danger" role="alert"> <img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
								<h2>Internal Server Error.</h2>
								<p>#message#</p>
								<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
							</div>
						</div>
					</div>
				</cfoutput>
			</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getEditPartsThread" />
	<cfreturn getEditPartsThread.output>
</cffunction>


<cffunction name="getEditCitationHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getEditCitationsThread"> 
		<cfoutput>
			<cftry>
				<div id="citationsDialog">
					<cfquery name="citations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT
							citation.type_status,
							citation.occurs_page_number,
							citation.citation_page_uri,
							citation.CITATION_REMARKS,
							cited_taxa.scientific_name as cited_name,
							cited_taxa.taxon_name_id as cited_name_id,
							formatted_publication.formatted_publication as formpub,
							formatted_publication.publication_id,
							cited_taxa.taxon_status as cited_name_status
						from
							citation,
							taxonomy cited_taxa,
							formatted_publication
						where
							citation.cited_taxon_name_id = cited_taxa.taxon_name_id AND
							citation.publication_id = formatted_publication.publication_id AND
							format_style='long' and
							citation.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
						order by
							substr(formatted_publication, - 4)
					</cfquery>
					<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						select collection_id,collection from collection
						order by collection
					</cfquery>
					<cfquery name="ctColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						select collection,collection_id from collection order by collection
					</cfquery>
					<cfquery name="ctTypeStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						select type_status from ctcitation_type_status order by type_status
					</cfquery>
					<cfquery name="ctjournal_name" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						select journal_name from ctjournal_name order by journal_name
					</cfquery>
					<cfquery name="ctpublication_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						select publication_type from ctpublication_type order by publication_type
					</cfquery>
					<cfquery name="getCited" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT
								citation.publication_id,
								citation.collection_object_id,
								collection,
								collection.collection_id,
								cat_num,
								identification.scientific_name,
								citedTaxa.scientific_name as citSciName,
								occurs_page_number,
								citation_page_uri,
								type_status,
								citation_remarks,
								cit_current_fg,
								citation_remarks,
								publication_title,
								formatted_publication.formatted_publication as formpub,
								formatted_publication.publication_id,
								publication.publication_id,
								publication.published_year,
								publication.publication_type,
								doi,
								cited_taxon_name_id
							FROM
								citation,
								cataloged_item,
								collection,
								identification,
								taxonomy citedTaxa,
								formatted_publication,
								publication
							WHERE
								citation.collection_object_id = cataloged_item.collection_object_id AND
								cataloged_item.collection_id = collection.collection_id AND
								citation.cited_taxon_name_id = citedTaxa.taxon_name_id (+) AND
								cataloged_item.collection_object_id = identification.collection_object_id (+) AND
								identification.accepted_id_fg = 1 AND
								citation.publication_id = publication.publication_id AND
								citation.publication_id = formatted_publication.publication_id AND
								format_style='long' and
								citation.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
							ORDER BY
								occurs_page_number,cat_num
						</cfquery>
						<cfquery name="getpubs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							select publication_id,formatted_publication from formatted_publication
						</cfquery>
					<section class="container-fluid">
						<div class="row mx-0">
							<div class="search-box">
							<form name="addCitForm" id="addCitForm">
								<input name="action" type="hidden" value="search">
								<input type="hidden" name="method" value="getCitResults" class="keeponclear">
								<div class="col-12 search-box-header px-0 float-left">
									<h2 class="h3 text-white float-left mb-1 mt-0 px-3"> Add Citation</h2>
								</div>
								<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
									<div class="col-12 col-md-3 mt-2 float-right">
										<a class="btn btn-xs btn-outline-primary px-2 float-right" target="_blank" href="/publication/Publication.cfm?action=new">Add New Publication <i class="fas fa-external-link-alt"></i></a>
									</div>
								</cfif>

								<div class="col-12 px-2">
									<div class="col-12 float-left mt-0 mb-1 py-0 px-0">
										<div class="col-12 px-1 float-left">
											<label for="publication" class="data-entry-label my-0"><span id="publication_id">Title</span></label>
											<input type="hidden" name="publication_id" id="publication_id" value="#encodeForHTML(getpubs.formatted_publication)#">
											<input type="text" id="publication" value='' class="data-entry-input">
										</div>
									</div>
									<div class="col-12 col-md-3 px-1 mb-1 float-left">
										<label for="collection_id" class="data-entry-label mt-1 mb-0">Cites Collection</label>
										<select name="collection" id="collection" size="1"  class="data-entry-select">
											<option value="">All</option>
											<cfloop query="ctColl">
												<option value="#collection#">#collection#</option>
											</cfloop>
										</select>
									</div>
									<div class="col-12 col-md-5 px-1 mb-1 float-left">
										<label for="citsciname" class="data-entry-label mt-1 mb-0">
											<span id="citsciname">Cited Scientific Name</span>
										</label>
										<input name="citsciname" class="data-entry-input" id="cited_sci_Name" type="text">
									</div>
									<div class="col-12 col-md-4 mb-1 px-1 float-left">
										<label for="scientific_name" class="data-entry-label mt-1 mb-0">
											<span id="scientific_name">Accepted Scientific Name</span>
										</label>
										<input name="scientific_name" class="data-entry-input" id="scientific_name" type="text">
									</div>
									<div class="col-12 float-left mt-0 mb-1 p-0">
										<div class="col-12 col-md-3 px-1 float-left">
											<label for="type_status" class="data-entry-label mt-1 mb-0">
												<span id="type_status">Citation Type</span>
											</label>
											<select name="type_status" id="type_status" class="data-entry-select">
												<option value""></option>
												<cfloop query="ctTypeStatus">
													<option value="#type_status#">#type_status#</option>
												</cfloop>
											</select>
										</div>
										<div class="col-12 col-md-3 px-1 float-left">
											<label for="occurs_page_number" class="data-entry-label mt-1 mb-0">Page ##</label>
											<input name="occurs_page_number" id="occurs_page_number" class="data-entry-input" type="text" value="">
										</div>
										<div class="col-12 col-md-6 px-1 float-left">
											<label for="citation_remarks" class="data-entry-label mt-1 mb-0">Remarks</label>
											<input name="citation_remarks" id="citation_remarks" class="data-entry-input" type="text" value="">
										</div>
									</div>
									<div class="col-12 my-2 px-1 float-left">
										<input type="submit" value="Save" class="btn btn-xs btn-primary mr-3">
										<input type="reset"	value="Clear Form"	class="btn btn-xs btn-warning">
									</div>
								</div>
							</form>
							<script>
								$(document).ready(function() {
									makePublicationAutocompleteMeta("publication", "publication_id");
								});
							</script>
							</div>
						</div>
					</section>
					<section class="container-fluid px-0 my-4">
						<cfif len(getCited.publication_id) GT 0>
						<cfset i = 1 >
						<h1 class="h3">Citations for this specimen</h1>
							<table class="table mb-0 small px-2">
								<thead class="p-2">
									<tr>
										<th>&nbsp;</th>
										<th class="px-1" style="min-width: 280px;">Publication Title</th>
										<th class="px-1">Cited As</th>
										<th class="px-1">Current ID</th>
										<th class="px-1" style="min-width: 80px;">Citation Type</th>
										<th class="px-1" style="min-width: 50px;">Page ##</th>
										<th class="px-1" style="min-width: 213px;">Remarks</th>
									</tr>
								</thead>
								<cfloop query="getCited">
								<tbody>
									<tr>
										<td nowrap>
											<table>
												<tr>
													<form name="deleCitation#i#" method="post" action="Citation.cfm">
														<input type="hidden" name="Action">
														<input type="hidden" name="collection_object_id" value="#collection_object_id#">
														<input type="hidden" name="cited_taxon_name_id" value="#cited_taxon_name_id#">
														<td class="border-0 px-0">
															<button type="button" aria-label="Remove Citation" class="btn btn-xs btn-danger" onclick="removeCitation(#collection_object_id#, #cited_taxon_name_id#)">Delete</button
														</td>
														<td class="border-0 pr-0 pl-2">
															<input type="button"
															value="Edit"
															class="btn btn-xs btn-primary"
															onClick="deleCitation#i#.Action.value='editCitation'; submit();">
														</td>
													</form>
												</tr>
											</table>
										</td>
										<td class="px-2"><a href="/Specimens.cfm?action=search&publication_id=#publication_id#">#formpub#</a></td>
										<td class="px-2"><i><a href="/taxonomy/Taxonomy.cfm?taxon_name_id=#getCited.citSciName#"><i>#replace(getCited.citSciName," ","&nbsp;","all")#</i></a></i>&nbsp;</td>
										<td class="px-2"><i>#scientific_name#</i>&nbsp;</td>
										<td class="px-2">#type_status#&nbsp;</td>
										<td>
											<cfif len(#citation_page_uri#) gt 0>
												<cfset citpage = trim(occurs_page_number)>
												<cfif len(citpage) EQ 0><cfset citpage="[link]"></cfif>
												<a href ="#citation_page_uri#" target="_blank" class="px-1">#citpage#</a>&nbsp;
											<cfelse>
												<span class="px-1">#occurs_page_number#&nbsp;</span>
											</cfif>
										</td>
										<td nowrap>#citation_remarks#&nbsp;</td>
									</tr>
									</tbody>
								</cfloop>
							</table>
						<cfset i = i + 1>
					</cfif>
					</section>
				</div>
				<cfset cellRenderClasses = "ml-1">
				<script>
					window.columnHiddenSettings = new Object();
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
						lookupColumnVisibilities ('#cgi.script_name#','Default');
					</cfif>

					var linkIdCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
						var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
						return '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a href="/specimens/component/search.cfc?collection_object_id=' + rowData['COLLECTION_OBJECT_ID'] + '">'+value+'</a></span>';
					};
					<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_specimens")>
						var editCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
							var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
							return '<span class="cellRenderClasses" style="margin: 6px; display:block; float: ' + columnproperties.cellsalign + '; "><a target="_blank" class="px-2 btn-xs btn-outline-primary" href="/specimens/component/search.cfc?collection_object_id=edit&collection_object_id=' + rowData['COLLECTION_OBJECT_ID'] + '">Edit</a></span>';
							return '<span class="#cellRenderClasses#" style="margin: 6px; display:block; float: ' + columnproperties.cellsalign + '; "><a target="_blank" class="px-2 btn-xs btn-outline-primary" href="#Application.serverRootUrl#/specimens/component/search.cfc?action=edit&taxon_name_id=' + value + '">Edit</a></span>';
						};
					</cfif>


				
				</script> 
				<cfcatch>
					<cfif isDefined("cfcatch.queryError") >
						<cfset queryError=cfcatch.queryError>
						<cfelse>
						<cfset queryError = ''>
					</cfif>
					<cfset message=trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)>
					<cfcontent reset="yes">
					<cfheader statusCode="500" statusText="#message#">
					<div class="container">
						<div class="row">
							<div class="alert alert-danger" role="alert"> <img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
								<h2>Internal Server Error.</h2>
								<p>#message#</p>
								<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
							</div>
						</div>
					</div>
				</cfcatch>
			</cftry>
		</cfoutput> 
	
<!--- get all cited specimens --->
<!------------------------------------------------------------------------------->
<!---remove citation --button for removing media relationship = shows cataloged_item--->
<cffunction name="removeCitation" returntype="string" access="remote" returnformat="plain">
	<cfargument name="cited_taxon_name_id" type="string" required="yes">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="publication_id" type="string" required="yes">
		<cfthread name="removeCitationThread"> 
	<cftry>
		<cftransaction>
			<cfquery name="deleteCitation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				delete from citation
				where
				collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
				and publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
				and cited_taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#cited_taxon_name_id#">
			</cfquery>
		</cftransaction>
			<cfset row["status"] = "deleted">
			<cftransaction action="commit">
		<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
				<cfabort>
		</cfcatch>
	</cftry>
	</cfthread>
	<cfthread action="join" name="getEditCitationThread" />
	<cfreturn getEditCitationThread.output>
</cffunction>
<!------------------------------------------------------------------------------->
<cfif action is "nothing">
     <div style="width: 99%; margin: 0 auto; padding: 0 .5rem 5em .5rem;">
<cfset title="Manage Citations">
<cfoutput>

<cfquery name="getCited" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT
		citation.publication_id,
		citation.collection_object_id,
		collection,
		collection.collection_id,
		cat_num,
		identification.scientific_name,
		citedTaxa.scientific_name as citSciName,
		occurs_page_number,
		citation_page_uri,
		type_status,
		citation_remarks,
		publication_title,
		doi,
		cited_taxon_name_id,
		concatSingleOtherId(cataloged_item.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID
	FROM
		citation,
		cataloged_item,
		collection,
		identification,
		taxonomy citedTaxa,
		publication
	WHERE
		citation.collection_object_id = cataloged_item.collection_object_id AND
		cataloged_item.collection_id = collection.collection_id AND
		citation.cited_taxon_name_id = citedTaxa.taxon_name_id (+) AND
		cataloged_item.collection_object_id = identification.collection_object_id (+) AND
		identification.accepted_id_fg = 1 AND
		citation.publication_id = publication.publication_id AND
		citation.publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
	ORDER BY
		occurs_page_number,citSciName,cat_num
</cfquery>
<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select collection_id,collection from collection
	order by collection
</cfquery>
	<h3 class="wikilink">Citations for <i>#getCited.publication_title#</i></h3>
	<cfif len(getCited.doi) GT 0>
	doi: <a target="_blank" href="https://doi.org/#getCited.DOI#">#getCited.DOI#</a><br><br>
	</cfif>
<a href="/publications/Publication.cfm?publication_id=#publication_id#">Edit Publication</a>
	
<form name="newCitation" id="newCitation" method="post" action="Citation.cfm">
	<input type="hidden" name="Action" value="newCitation">
	<input type="hidden" name="publication_id" value="#publication_id#">
	<input type="hidden" name="collection_object_id" id="collection_object_id">
		<table border class="newRec">
			<tr>
				<td colspan="2">
				Add Citation to <b>	#getCited.publication_title#</b>:
				</td>
			</tr>
			<tr>
				<td>
					<label for="collection">Collection</label>
					<select name="collection" id="collection" size="1" class="reqdClr">
						<cfloop query="ctcollection">
							<option value="#collection_id#">#collection#</option>
						</cfloop>
					</select>
				</td>
				<td>
					<label for="cat_num" id="lbl_cat_num">Catalog Number [ <span class="likeLink" onclick="getCatalogedItemCitation('cat_num','cat_num');">force refresh</span> ]</label>
					<input type="text" name="cat_num" id="cat_num" onchange="getCatalogedItemCitation(this.id,'cat_num')" class="reqdClr">
				</td>
				<cfif len(session.CustomOtherIdentifier) gt 0>
					<td>
						<label for="custom_id">#session.CustomOtherIdentifier#</label>
						<input type="text" name="custom_id" id="custom_id" onchange="getCatalogedItemCitation(this.id,'#session.CustomOtherIdentifier#')">
					</td>
				</cfif>
			</tr>
			<tr>
				<td>
					<label for="scientific_name">Current Identification</label>
					<input type="text" name="scientific_name" id="scientific_name" readonly class="readClr" size="50">
				</td>
				<td colspan="2">
					<label for="cited_taxon_name" id="lbl_cited_taxon_name">
						<a href="javascript:void(0);" onClick="getDocs('publication','cited_as_taxon')">Cited As</a></label>
					<input type="text" name="cited_taxon_name" id="cited_taxon_name" class="reqdClr" size="50" onChange="taxaPick('cited_taxon_name_id','cited_taxon_name','newCitation',this.value); return false;">
					<span class="infoLink"
						onClick = "taxaPick('cited_taxon_name_id','cited_taxon_name','newCitation',document.getElementById('scientific_name').value)">Use Current</span>
					<input type="hidden" name="cited_taxon_name_id">
				</td>
			</tr>
			<tr>
				<td>
					<label for="type_status">
						<a href="javascript:void(0);" onClick="getDocs('publication','citation_type')">Citation Type</a>
					</label>
					<select name="type_status" id="type_status" size="1">
						<cfloop query="ctTypeStatus">
							<option value="#ctTypeStatus.type_status#">#ctTypeStatus.type_status#</option>
						</cfloop>
					</select>
					<span class="infoLink" onClick="getCtDoc('ctcitation_type_status',newCitation.type_status.value)">Define</span>
				</td>
				<td>
					<label for="occurs_page_number">
						<a href="javascript:void(0);" onClick="getDocs('publication','cited_on_page_number')">Page ##</a>
					</label>
					<input type="text" name="occurs_page_number" id="occurs_page_number" size="4">
				</td>
			</tr>
			<tr>
				<td colspan="3">
					<label for="citation_page_uri">Citation Page URI:</label>
					<input type="text" name="citation_page_uri" id="citation_page_uri" size="90">
				</td>
			</tr>
			<tr>
				<td colspan="3">
					<label for="citation_remarks">Remarks:</label>
					<input type="text" name="citation_remarks" id="citation_remarks" size="90">
				</td>
			</tr>
			<tr>
				<td colspan="2" align="center">
					<input type="submit"
						id="submit"
						title="Insert Citation"
						value="Insert Citation"
						class="insBtn"
						onmouseover="this.className='insBtn btnhov'"
						onmouseout="this.className='insBtn'">
				</td>
			</tr>
		</table>
	</form>
	<table class="pubtable" border="0" style="border: none;font-size: 15px;margin-top:1.5rem;">
		<thead style="background-color: ##beecea;padding: 11px;line-height: 1.5rem;">
			<tr>
				<th>&nbsp;</th>
				<th>Cat Num</th>
				<cfif len(#getCited.CustomID#) GT 0><th>#session.CustomOtherIdentifier#</th></cfif>
				<th>Cited As</th>
				<th>Current ID</th>
				<th>Citation Type</th>
				<th style="padding: 0 1rem;">Page ##</th>
				<th style="padding: 0 1rem; min-width: 300px;">Remarks</th>
			</tr>
		</thead>
		<tbody>
			<cfset i=1>
			<cfloop query="getCited">
				<tr>
					<td nowrap>
						<table>
							<tr>
								<form name="deleCitation#i#" method="post" action="Citation.cfm">
									<input type="hidden" name="Action">
									<input type="hidden" value="#publication_id#" name="publication_id">
									<input type="hidden" name="collection_object_id" value="#collection_object_id#">
									<input type="hidden" name="cited_taxon_name_id" value="#cited_taxon_name_id#">
									<td style="border-bottom: none;">
									<input type="button"
										value="Delete"
										class="delBtn"
										onmouseover="this.className='delBtn btnhov'"
										onmouseout="this.className='delBtn'"
										onClick="deleCitation#i#.Action.value='deleCitation';submit();">
									</td>
									<td style="border-bottom: none;">
									<input type="button"
										value="Edit"
										class="lnkBtn"
										onmouseover="this.className='lnkBtn btnhov'"
										onmouseout="this.className='lnkBtn'"
										onClick="deleCitation#i#.Action.value='editCitation'; submit();">
									</td>
								</form>
								<td style="border-bottom: none;">
								<input type="button"
									value="Clone"
									class="insBtn"
									onmouseover="this.className='insBtn btnhov'"
									onmouseout="this.className='insBtn'"
									onclick = "newCitation.cited_taxon_name.value='#getCited.citSciName#';
									newCitation.cited_taxon_name_id.value='#getCited.cited_taxon_name_id#';
									newCitation.type_status.value='#getCited.type_status#';
									newCitation.occurs_page_number.value='#getCited.occurs_page_number#';
									newCitation.citation_remarks.value='#stripQuotes(getCited.citation_remarks)#';
									newCitation.collection.value='#getCited.collection_id#';
									newCitation.citation_page_uri.value='#getCited.citation_page_uri#';
									">
								</td>
							</tr>
						</table>
					</td>
					<td style="padding:0 .5rem;"><a href="/SpecimenDetail.cfm?collection_object_id=#getCited.collection_object_id#">#getCited.collection#&nbsp;#getCited.cat_num#</a></td>
					<cfif len(#getCited.CustomID#) GT 0><td nowrap="nowrap">#customID#</td></cfif>
					<td style="padding: 0 .5rem;"><i>#getCited.citSciName#</i>&nbsp;</td>
					<td style="padding: 0 .5rem;"><i>#getCited.scientific_name#</i>&nbsp;</td>
					<td style="padding: 0 .5rem;">#getCited.type_status#&nbsp;</td>
					<td>
						<cfif len(#getCited.citation_page_uri#) gt 0>
							<cfset citpage = trim(getCited.occurs_page_number)>
							<cfif len(citpage) EQ 0><cfset citpage="[link]"></cfif>
							<a href ="#getCited.citation_page_uri#" target="_blank">#citpage#</a>&nbsp;
						<cfelse>
							#getCited.occurs_page_number#&nbsp;
						</cfif>
					</td>
					<td nowrap>#stripQuotes(getCited.citation_remarks)#&nbsp;</td>
				</tr>
				<cfset i=#i#+1>
			</cfloop>
		</tbody>
	</table>
</cfoutput>
	</div>
</cfif>

<!------------------------------------------------------------------------------->
<!------------------------------------------------------------------------------->
<cfif #Action# is "newCitation">
	<cfoutput>
	<cfquery name="newCite" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		INSERT INTO citation (
			publication_id,
			collection_object_id,
			cit_current_fg
			<cfif len(#cited_taxon_name_id#) gt 0>
				,cited_taxon_name_id
			</cfif>
			<cfif len(#occurs_page_number#) gt 0>
				,occurs_page_number
			</cfif>
			<cfif len(#type_status#) gt 0>
				,type_status
			</cfif>
			<cfif len(#citation_remarks#) gt 0>
				,citation_remarks
			</cfif>
			<cfif len(#citation_page_uri#) gt 0>
				,citation_page_uri
			</cfif>
			)
			VALUES (
			#publication_id#,
			#collection_object_id#,
			1
			<cfif len(#cited_taxon_name_id#) gt 0>
				,#cited_taxon_name_id#
			</cfif>
			<cfif len(#occurs_page_number#) gt 0>
				,#occurs_page_number#
			</cfif>
			<cfif len(#type_status#) gt 0>
				,'#type_status#'
			</cfif>
			<cfif len(#citation_remarks#) gt 0>
				,'#escapequotes(citation_remarks)#'
			</cfif>
			<cfif len(#citation_page_uri#) gt 0>
				,'#escapequotes(citation_page_uri)#'
			</cfif>
			)
			</cfquery>
			<cflocation url="Citation.cfm?publication_id=#publication_id#">
	</cfoutput>

</cfif>
<!------------------------------------------------------------------------------->
<!------------------------------------------------------------------------------->
<cfif #Action# is "saveEdits">
	<cfoutput>
	<cfquery name="edCit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		UPDATE citation SET
			cit_current_fg = 1
			<cfif len(#cited_taxon_name_id#) gt 0>
				,cited_taxon_name_id = #cited_taxon_name_id#
			  <cfelse>
			  	,cited_taxon_name_id = null
			</cfif>
			<cfif len(#occurs_page_number#) gt 0>
				,occurs_page_number = #occurs_page_number#
			  <cfelse>
			  	,occurs_page_number = null
			</cfif>
			<cfif len(#type_status#) gt 0>
				,type_status = '#type_status#'
			  <cfelse>
				,type_status = null
			</cfif>
			<cfif len(#citation_remarks#) gt 0>
				,citation_remarks = '#escapequotes(citation_remarks)#'
			  <cfelse>
			  	,citation_remarks = null
			</cfif>
			<cfif len(#citation_page_uri#) gt 0>
				,citation_page_uri = '#escapequotes(citation_page_uri)#'
			  <cfelse>
			  	,citation_page_uri = null
			</cfif>

		WHERE
			publication_id = #publication_id# AND
			collection_object_id = #collection_object_id# AND
			cited_taxon_name_id = #current_cited_taxon_name_id#
		</cfquery>
		<cflocation url="Citation.cfm?publication_id=#publication_id#">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------->
<cfif #Action# is "editCitation">
<cfset title="Edit Citations">
    <div style="width: 50em; margin: 0 auto; padding: 2em 0 3em 0;">
<cfoutput>

<cfquery name="getCited" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT
		citation.publication_id,
		citation.collection_object_id,
		cat_num,
		collection,
		identification.scientific_name,
		citedTaxa.scientific_name as citSciName,
		occurs_page_number,
		citation_page_uri,
		type_status,
		citation_remarks,
		publication_title,
		cited_taxon_name_id
	FROM
		citation,
		cataloged_item,
		identification,
		taxonomy citedTaxa,
		publication,
		collection
	WHERE
		cataloged_item.collection_id = collection.collection_id AND
		citation.collection_object_id = cataloged_item.collection_object_id AND
		citation.cited_taxon_name_id = citedTaxa.taxon_name_id (+) AND
		cataloged_item.collection_object_id = identification.collection_object_id AND
		identification.accepted_id_fg = 1 AND
		citation.publication_id = publication.publication_id AND
		citation.publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#"> AND
		citation.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#"> AND
		citation.cited_taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#cited_taxon_name_id#">
</cfquery>


</cfoutput>
<cfoutput query="getCited">
    <h3>Edit Citation for <i>#getCited.publication_title#</i></h3>
<cfform name="editCitation" id="editCitation" method="post" action="Citation.cfm">
		<input type="hidden" name="Action" value="saveEdits">
		<input type="hidden" name="publication_id" value="#publication_id#">
		<input type="hidden" name="collection_object_id" value="#collection_object_id#">
		<input type="hidden" name="current_cited_taxon_name_id" value="#cited_taxon_name_id#">

<table border>

<tr>
	<td>
		<label for="citem">Cataloged Item</label>
		<span id="citem">#collection# #cat_num#</span>
	</td>
	<td>
		<label for="scientific_name">Identified As</label>
		<span id="scientific_name">#scientific_name#</span>
	</td>
</tr>

<tr>
	<td>
		<label for="cited_taxon_name">Cited As</label>
		<input type="text"
			name="cited_taxon_name"
			id="cited_taxon_name"
			value="#citSciName#"
			class="reqdClr"
			size="50"
			onChange="taxaPick('cited_taxon_name_id','cited_taxon_name','editCitation',this.value); return false;">
		<input type="hidden" name="cited_taxon_name_id" value="#cited_taxon_name_id#" class="reqdClr">
	</td>
	<td>
		<label for="type_status">Citation Type</label>
		<select name="type_status" id="type_status" size="1">
			<cfloop query="ctTypeStatus">
				<option
					<cfif #getCited.type_status# is "#ctTypeStatus.type_status#"> selected </cfif>value="#ctTypeStatus.type_status#">#ctTypeStatus.type_status#</option>
			</cfloop>
		</select>
	</td>
</tr>

<tr>
	<td>
		<label for="occurs_page_number">Page</label>
		<input type="text" name="occurs_page_number" id="occurs_page_number" size="4" value="#occurs_page_number#">
	</td>
	<td>
		<label for="citation_remarks">Remarks</label>
		<input type="text" name="citation_remarks" id="citation_remarks" size="50" value="#stripQuotes(citation_remarks)#">
	</td>
</tr>
<tr>
	<td colspan="2">
		<label for="citation_page_uri">Citation Page URI</label>
		<input type="text" name="citation_page_uri" id="citation_page_uri" size="100%" value="#citation_page_uri#">
	</td>
</tr>
<tr>
	<td colspan="2" align="center">
		<input type="submit"
			value="Save Edits"
			class="savBtn"
			id="sBtn"
			title="Save Edits"
			onmouseover="this.className='savBtn btnhov'"
			onmouseout="this.className='savBtn'">

	</td>

	</cfform>
</tr>
</table>
</cfoutput>
        </div>
</cfif>
<!------------------------------------------------------------------------------->
<cfif #Action# is "deleCitation">
<cfoutput>
	<cfquery name="deleCit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	delete from citation
	where
		collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
		and publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
		and cited_taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#cited_taxon_name_id#">
	</cfquery>
	<cflocation url="Citation.cfm?publication_id=#publication_id#">
</cfoutput>
</cfif>
<!------------------------------------------------------------------------------->
	</cfthread>
	<cfthread action="join" name="getEditCitationsThread" />
	<cfreturn getEditCitationsThread.output>
</cffunction>
		
<cffunction name="getCatalogedItemCitation" access="remote">
	<cfargument name="collection_id" type="numeric" required="yes">
	<cfargument name="theNum" type="string" required="yes">
	<cfargument name="type" type="string" required="yes">
	<cfoutput>
	<cftry>
		<cfif type is "cat_num">
			<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select
					cataloged_item.COLLECTION_OBJECT_ID,
					cataloged_item.cat_num,
					scientific_name
				from
					cataloged_item,
					identification
				where
					cataloged_item.collection_object_id = identification.collection_object_id AND
					accepted_id_fg=1 and
					cat_num='#theNum#' and
					collection_id=#collection_id#
			</cfquery>
		<cfelse>
			<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select
					cataloged_item.COLLECTION_OBJECT_ID,
					cataloged_item.cat_num,
					scientific_name
				from
					cataloged_item,
					identification,
					coll_obj_other_id_num
				where
					cataloged_item.collection_object_id = identification.collection_object_id AND
					cataloged_item.collection_object_id = coll_obj_other_id_num.collection_object_id AND
					accepted_id_fg=1 and
					display_value='#theNum#' and
					other_id_type='#type#' and
					collection_id=#collection_id#
			</cfquery>
		</cfif>
		<cfcatch>
			<cfset result = querynew("collection_object_id,scientific_name")>
			<cfset temp = queryaddrow(result,1)>
			<cfset temp = QuerySetCell(result, "collection_object_id", "-1", 1)>
			<cfset temp = QuerySetCell(result, "scientific_name", "#cfcatch.Message# #cfcatch.Detail#", 1)>
		</cfcatch>
	</cftry>
	<cfreturn result>
	</cfoutput>
</cffunction>

<!--- 
 getAttributeCodeTables lookup value and unit code tables for a given attribute type.
 @param collection_object_id the collection object id to obtain the collection by which to limit the code table values
 @param attribute_type the attribute type to obtain the code tables for
 @return a JSON object containing the attribute type, value code table, units code table, and the values for each
  with the values for each code table returned as a pipe delimited string
--->
<cffunction name="getAttributeCodeTables" returntype="any" access="remote" returnformat="json">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="attribute_type" type="string" required="yes">
	<cfset variables.collection_object_id = arguments.collection_object_id>
	<cfset variables.attribute_type = arguments.attribute_type>
	<cfset result = ArrayNew(1)>
	<cftry>
		<cfquery name="getCatItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT
				cataloged_item.collection_object_id,
				cataloged_item.cat_num,
				cataloged_item.collection_cde,
				collection.institution_acronym
			FROM
				cataloged_item 
				join collection on cataloged_item.collection_id = collection.collection_id
			WHERE
				cataloged_item.collection_object_id = <cfqueryparam value="#variables.collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
		</cfquery>
		<cfquery name="getAttributeCodeTables" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT
				attribute_type,
				upper(value_code_table) value_code_table,
				upper(units_code_table) units_code_table
			FROM
				ctattribute_code_tables
			WHERE 
				attribute_type = <cfqueryparam value="#variables.attribute_type#" cfsqltype="CF_SQL_VARCHAR">
		</cfquery>
		<cfif getAttributeCodeTables.recordCount EQ 1>
			<cfset row = StructNew()>
			<cfset row["value_code_table"] = "#getAttributeCodeTables.value_code_table#">
			<cfset row["units_code_table"] = "#getAttributeCodeTables.units_code_table#">
			<cfset row["attribute_type"] = "#getAttributeCodeTables.attribute_type#">
			<cfif len(getAttributeCodeTables.value_code_table) GT 0>
				<cfset variables.table=getAttributeCodeTables.value_code_table>
				<!--- check if the table is a special case --->
				<cfif ucase(variables.table) EQ "CTASSOCIATED_GRANTS">
					<cfset variables.field="ASSOCIATED_GRANT">
				<cfelseif ucase(variables.table) EQ "CTCOLLECTION_FULL_NAMES">
					<cfset variables.field="COLLECTION">
				<cfelse>
					<!--- default is attribute field is the attribute code table name with CT prefix removed --->
					<cfset variables.field=replace(getAttributeCodeTables.value_code_table,"CT","","one")>
				</cfif>
				<!--- check if the table has a collection_cde field --->
				<cfquery name="getFieldMetadata" datasource="uam_god">
					SELECT
						COUNT(*) as ct
					FROM
						sys.all_tab_columns
					WHERE
						table_name = <cfqueryparam value="#variables.table#" cfsqltype="CF_SQL_VARCHAR">
						AND owner = 'MCZBASE'
						AND column_name = 'COLLECTION_CDE'
				</cfquery>
				<!--- obtain values, limit by collection if there is one --->
				<cfquery name="getValueCodeTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT distinct
						#variables.field# as value
					FROM
						#variables.table#
					<cfif getFieldMetadata.ct GT 0>
					WHERE
						collection_cde = <cfqueryparam value="#getCatItem.collection_cde#" cfsqltype="CF_SQL_VARCHAR">
					</cfif>
					ORDER BY
						#variables.field#
				</cfquery>
				<cfset values="">
				<cfloop query="getValueCodeTable">
					<cfset values = listAppend(values, getValueCodeTable.value, "|")>
				</cfloop>
				<cfset row["value_values"] = "#values#">
			</cfif>
			<cfif len(getAttributeCodeTables.units_code_table) GT 0>
				<cfset table=getAttributeCodeTables.units_code_table>
				<cfset field=replace(getAttributeCodeTables.units_code_table,"CT","","one")>
				<cfquery name="getUnitsCodeTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT
						#field# as value
					FROM
						#table#
					ORDER BY
						#field#
				</cfquery>
				<cfset units="">
				<cfloop query="getUnitsCodeTable">
					<cfset units = listAppend(units, getUnitsCodeTable.value, "|")>
				</cfloop>
				<cfset row["units_values"] = "#units#">
			</cfif>
			<cfset arrayAppend(result, row)>
		<cfelse>
			<!--- not found, therefore no code tables specified for that attribute.  --->
			<cfset row = StructNew()>
			<cfset row["attribute_type"] = "#variables.attribute_type#">
			<cfset arrayAppend(result, row)>
		</cfif>
	<cfcatch>
		<cfdump var="#cfcatch#">
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn serializeJSON(result)>
</cffunction>

<cffunction name="getEditAttributesHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfset variables.collection_object_id = arguments.collection_object_id>
	<cfthread name="getEditAttributesThread"> 
		<cfoutput>
			<cftry>
				<cfquery name="getCatItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT
						cataloged_item.collection_object_id,
						cataloged_item.cat_num,
						cataloged_item.collection_cde,
						collection.institution_acronym
					FROM
						cataloged_item 
						join collection on cataloged_item.collection_id = collection.collection_id
					WHERE
						cataloged_item.collection_object_id = <cfqueryparam value="#variables.collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
				</cfquery>
				<cfset guid = "#getCatItem.institution_acronym#:#getCatItem.collection_cde#:#getCatItem.cat_num#">
				<!--- obtain a list of attribute types for the collection this specimen is in --->
				<cfquery name="getAttributeTypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT
						attribute_type, description
					FROM
						ctattribute_type
					WHERE 
						collection_cde = <cfqueryparam value="#getCatItem.collection_cde#" cfsqltype="CF_SQL_VARCHAR">
					ORDER BY
						attribute_type
				</cfquery>
				<cfquery name="getCurrentUser" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT agent_id, 
							agent_name
					FROM preferred_agent_name
					WHERE
						agent_id in (
							SELECT agent_id 
							FROM agent_name 
							WHERE upper(agent_name) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(session.username)#">
								and agent_name_type = 'login'
						)
				</cfquery>

				<!--- add new attribute --->
				<div class="col-12 mt-4 px-1">
					<div class="container-fluid">
						<div class="row">
							<div class="col-12">
								<div class="add-form">
									<div class="add-form-header pt-1 px-2" id="headingAttribute">
										<h2 class="h3 my-0 px-1 bp-1">Add New Attribute to #guid#</h2>
									</div>
									<div class="card-body">
										<form name="newAttribute" id="newAttribute">
											<input type="hidden" name="collection_object_id" value="#collection_object_id#">
											<input type="hidden" name="method" value="addAttribute">
											<div class="row mx-0 pb-2">
												<ul class="col-12 px-0 mt-2 mb-1">
													<li class="list-group-item float-left col-12 col-md-4 px-1">
														<label for="attribute_type" class="data-entry-label">Name</label>
														<select name="attribute_type" id="attribute_type" class="data-entry-select reqdClr" required>
															<option value=""></option>
															<cfloop query="getAttributeTypes">
																<option value="#attribute_type#">#attribute_type#</option>
															</cfloop>
														</select>
													</li>
													<li class="list-group-item float-left col-12 col-md-4 px-1">
														<label for="attribute_value" class="data-entry-label">Value</label>
														<input type="text" class="data-entry-input" id="attribute_value" name="attribute_value" value="">
													</li>
													<li class="list-group-item float-left col-12 col-md-4 px-1">
														<label for="attribute_units" class="data-entry-label">Units</label>
														<input type="text" class="data-entry-input" id="attribute_units" name="attribute_units" value="">
													</li>
													<li class="list-group-item float-left col-12 col-md-4 px-1">
														<label for="determined_by_agent" class="data-entry-label">Determiner</label>
														<input type="text" class="data-entry-input" id="determined_by_agent" name="determined_by_agent" value="#getCurrentUser.agent_name#">
														<input type="hidden" name="determined_by_agent_id" id="determined_by_agent_id" value="#getCurrentUser.agent_id#">
													</li>
													<li class="list-group-item float-left col-12 col-md-4 px-1">
														<label for="determined_date" class="data-entry-label">Determined Date</label>
														<input type="text" class="data-entry-input" id="determined_date" name="determined_date" 
															placeholder="yyyy-mm-dd" value="#dateformat(now(),"yyyy-mm-dd")#">
													</li>
													<li class="list-group-item float-left col-12 col-md-4 px-1">
														<label for="determination_method" class="data-entry-label">Determined Method</label>
														<input type="text" class="data-entry-input" id="determination_method" name="determination_method" value="">
													</li>
													<li class="list-group-item float-left col-12 col-md-12 px-1">
														<label for="attribute_remark" class="data-entry-label">Remarks</label>
														<input type="text" class="data-entry-input" id="attribute_remark" name="attribute_remark" value="" maxlength="255">
													</li>
												</ul>
												<div class="col-12 col-md-12 px-1 mt-2">
													<button id="newAttribute_submit" value="Create" class="btn btn-xs btn-primary" title="Create Attribute">Create Attribute</button>
													<output id="newAttribute_output"></output>
												</div>
											</div>
										</form>
									</div>
								</div>
								<script>
									$(document).ready(function() {
										// disable units and value fields until type is selected
										$('##attribute_value').prop('disabled', true);
										$('##attribute_units').prop('disabled', true);
										// make the determined date a date picker
										$("##determined_date").datepicker({ dateFormat: 'yy-mm-dd'});
										// make the determined by agent into an agent autocomplete
										makeAgentAutocompleteMeta('determined_by_agent','determined_by_agent_id');
									});
									function handleTypeChange() {
										var selectedType = $('##attribute_type').val();
										// lookup value code table and units code table from ctattribute_code_tables
										// set select lists for value and units accordingly, or set as text input
										$.ajax({
											url: '/specimens/component/functions.cfc',
											type: 'POST',
											dataType: 'json',
											data: {
												collection_object_id: '#collection_object_id#',
												method: 'getAttributeCodeTables',
												attribute_type: selectedType
											},
											success: function(response) {
												console.log(response);
												// determine if the value field should be a select based on the response
												if (response[0].value_code_table) {
													$('##attribute_value').prop('disabled', false);
													// convert the value field to a select
													$('##attribute_value').replaceWith('<select id="attribute_value" name="attribute_value" class="data-entry-select reqdClr" required></select>');
													// Populate the value select with options from the response
													// value_values is a pipe delimited list of values
													var values = response[0].value_values.split('|');
													$('##attribute_value').append('<option value=""></option>');
													$.each(values, function(index, value) {
														$('##attribute_value').append('<option value="' + value + '">' + value + '</option>');
													});
												} else {
													// enable as a text input, replace any existing select
													$('##attribute_value').replaceWith('<input type="text" class="data-entry-input reqdClr" id="attribute_value" name="attribute_value" value="" required>');
													$('##attribute_value').prop('disabled', false);
												}
												// Determine if the units field should be enabled based on the response
												if (response[0].units_code_table) {
													$('##attribute_units').prop('disabled', false);
													// convert the units field to a select
													$('##attribute_units').replaceWith('<select id="attribute_units" name="attribute_units" class="data-entry-select reqdClr" required></select>');
													// Populate the units select with options from the response
													// units_values is a pipe delimited list of values
													$('##attribute_units').append('<option value=""></option>');
													$.each(response[0].units_values.split('|'), function(index, value) {
														$('##attribute_units').append('<option value="' + value + '">' + value + '</option>');
													});
												} else {
													// units are either picklists or not used.
													$('##attribute_units').prop('disabled', true);
													$('##attribute_units').val('');
													// remove any reqdClr class
													$('##attribute_units').removeClass('reqdClr');
												}
											},
											error: function(xhr, status, error) {
												handleFail(xhr,status,error,"handling change of attribute type.");
											}
										});
									}
									// Add change listener to the attribute type select
									$('##attribute_type').on('change', function() {
										handleTypeChange();
									});
									// Add event listener to the save button
									$('##newAttribute_submit').on('click', function(event) {
										event.preventDefault();
										setFeedbackControlState("newAttribute_output","saving");
										$.ajax({
											url: '/specimens/component/functions.cfc',
											type: 'POST',
											responseType: 'json',
											data: $('##newAttribute').serialize(),
											success: function(response) {
												setFeedbackControlState("newAttribute_output","saved");
												reloadEditExistingAttributes();
											},
											error: function(xhr, status, error) {
												setFeedbackControlState("newAttribute_output","error");
												handleFail(xhr,status,error,"saving attribute.");
											}
										});
									});
									function reloadEditExistingAttributes() {
										// reload the edit existing attributes section
										$.ajax({
											url: '/specimens/component/functions.cfc',
											type: 'POST',
											dataType: 'html',
											data: {
												method: 'getEditExistingAttributesUnthreaded',
												collection_object_id: '#collection_object_id#'
											},
											success: function(response) {
												$('##editExistingAttributesDiv').html(response);
											},
											error: function(xhr, status, error) {
												handleFail(xhr,status,error,"reloading edit existing attributes.");
											}
										});
									}
								</script>
								<!--- edit existing attributes --->
								<div id="editExistingAttributesDiv">
									<!--- this div is replaced with the edit existing attributes HTML attributes are added --->
									<cfset getEditExistingAttributesHTML = getEditExistingAttributesUnthreaded(collection_object_id=variables.collection_object_id)>
								</div>
							</div>
						</div>
					</div>
				</div>
			<cfcatch>
				<p class="mt-2 text-danger">Error: #cfcatch.type# #cfcatch.message# #cfcatch.detail#</p>
			</cfcatch>
			</cftry>
		</cfoutput> 
	</cfthread>
	<cfthread action="join" name="getEditAttributesThread" />
	<cfreturn getEditAttributesThread.output>
</cffunction>

<!--- 
 getEditExistingAttributesUnthreaded returns the HTML for the edit existing attributes section, intended to be used
 from within threaded getEditAttributesHTML or invoked independently to reload just the edit existing attributes section 
 of the dialog.
 @param collection_object_id the collection object id to obtain the collection by which to limit the code table values
 @return a string containing the HTML for the edit existing attributes section
--->
<cffunction name="getEditExistingAttributesUnthreaded" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfset variables.collection_object_id = arguments.collection_object_id>
	<cfoutput>
		<cfquery name="getCatItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT
				cataloged_item.collection_object_id,
				cataloged_item.cat_num,
				cataloged_item.collection_cde,
				collection.institution_acronym
			FROM
				cataloged_item 
				join collection on cataloged_item.collection_id = collection.collection_id
			WHERE
				cataloged_item.collection_object_id = <cfqueryparam value="#variables.collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
		</cfquery>
		<cfset guid = "#getCatItem.institution_acronym#:#getCatItem.collection_cde#:#getCatItem.cat_num#">
		<!--- obtain a list of attribute types for the collection this specimen is in --->
		<cfquery name="getAttributeTypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT
				attribute_type, description
			FROM
				ctattribute_type
			WHERE 
				collection_cde = <cfqueryparam value="#getCatItem.collection_cde#" cfsqltype="CF_SQL_VARCHAR">
			ORDER BY
				attribute_type
		</cfquery>
		<cfquery name="getCurrentUser" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT agent_id, 
					agent_name
			FROM preferred_agent_name
			WHERE
				agent_id in (
					SELECT agent_id 
					FROM agent_name 
					WHERE upper(agent_name) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(session.username)#">
						and agent_name_type = 'login'
				)
		</cfquery>
		<!--- edit existing attributes --->
		<cfquery name="getAttributes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT
				attributes.attribute_id,
				attributes.attribute_type,
				attributes.attribute_value,
				attributes.attribute_units,
				attributes.attribute_remark,
				attributes.determination_method,
				attributes.determined_date,
				attribute_determiner.agent_name attributeDeterminer,
				attributes.determined_by_agent_id
			FROM
				attributes
				LEFT JOIN preferred_agent_name attribute_determiner on attributes.determined_by_agent_id = attribute_determiner.agent_id 
			WHERE
				attributes.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
		</cfquery>
		<div class="row mx-0">
			<div class="bg-light p-2 col-12 row">
				<h1 class="h3">Edit Existing Attributes</h1>
				<div class="col-12 px-0 pb-3">
					<cfif getAttributes.recordCount EQ 0>
						<li>No attributes found for this specimen.</li>
					</cfif>
					<cfset i = 0>
					<cfloop query="getAttributes">
						<cfset i = i + 1>
						<form name="editAttribute#i#" id="editAttribute#i#">
							<input type="hidden" name="collection_object_id" value="#collection_object_id#">
							<input type="hidden" name="attribute_id" value="#attribute_id#">
							<input type="hidden" name="method" value="updateAttribute">
							<div class="row mx-0 border pb-1">
								<div class="col-12 col-md-2">
									<label for="att_name#i#" class="data-entry-label">Name</label>
									<select class="data-entry-select reqdClr" id="att_name#i#" name="attribute_type" required>
										<cfloop query="getAttributeTypes">
											<cfif getAttributeTypes.attribute_type EQ getAttributes.attribute_type>
												<cfset selected = "selected">
											<cfelse>
												<cfset selected = "">
											</cfif>
											<option value="#getAttributeTypes.attribute_type#" #selected#>#getAttributeTypes.attribute_type#</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 col-md-2">
									<label for="att_value" class="data-entry-label reqdClr" required>Value</label>
									<input type="text" class="data-entry-input" id="att_value#i#" name="attribute_value" value="#attribute_value#">
								</div>
								<div class="col-12 col-md-2">
									<label for="att_units" class="data-entry-label">Units</label>
									<input type="text" class="data-entry-input" id="att_units#i#" name="attribute_units" value="#attribute_units#">
								</div>
								<div class="col-12 col-md-2">
									<label class="data-entry-label">Determiner</label>
									<input type="text" class="data-entry-input" id="att_det#i#" name="determined_by_agent" value="#attributeDeterminer#">
									<input type="hidden" name="determined_by_agent_id" id="att_det_id#i#" value="#determined_by_agent_id#">
									<!--- make the determined by agent into an agent autocomplete --->
									<script>
										$(document).ready(function() {
											makeAgentAutocompleteMeta('att_det#i#','att_det_id#i#');
										});
									</script>
								</div>
								<div class="col-12 col-md-2">
									<label class="data-entry-label">Determined Date</label>
									<input type="text" class="data-entry-input" id="att_date#i#" name="determined_date" value="#dateformat(determined_date,"yyyy-mm-dd")#">
								</div>
								<div class="col-12 col-md-2">
									<label class="data-entry-label" for="att_method#i#">Method</label>
									<input type="text" class="data-entry-input" id="att_method#i#" name="determination_method" value="#determination_method#">
								</div>
								<div class="col-12 col-md-9">
									<label for="att_rem" class="data-entry-label">Remarks</label>
									<input type="text" class="data-entry-input" id="att_rem#i#" name="attribute_remark" value="#attribute_remark#">
								</div>
								<div class="col-12 col-md-3 pt-2">
									<button id="att_submit#i#" value="Save" class="btn btn-xs btn-primary" title="Save Attribute">Save</button>
									<button id="att_delete#i#" value="Delete" class="btn btn-xs btn-danger" title="Delete Attribute">Delete</button>
									<output id="att_output#i#"></output>
								</div>
							</div>
							<script>
								$('##att_name#i#').on('change', function() {
									handleTypeChangeExisting('#i#');
								});
							</script>
						</form>
					</cfloop>
					<script>
						// Add event listeners to the buttons
						document.querySelectorAll('button[id^="att_submit"]').forEach(function(button) {
							button.addEventListener('click', function(event) {
								event.preventDefault();
								var id = button.id.slice(-1);
								var feedbackOutput = 'att_output' + id;
								setFeedbackControlState(feedbackOutput,"saving")
								$.ajax({
									url: '/specimens/component/functions.cfc',
									type: 'POST',
									data: $("##editAttribute" + id).serialize(),
									success: function(response) {
										setFeedbackControlState(feedbackOutput,"saved");
										reloadAttributes();
									},
									error: function(xhr, status, error) {
										setFeedbackControlState(feedbackOutput,"error")
										handleFail(xhr,status,error,"saving change to attribute.");
									}
								});
							});
						});
						document.querySelectorAll('button[id^="att_delete"]').forEach(function(button) {
							button.addEventListener('click', function(event) {
								event.preventDefault();
								var id = button.id.slice(-1);
								var feedbackOutput = 'att_output' + id;
								setFeedbackControlState(feedbackOutput,"deleting")
								$.ajax({
									url: '/specimens/component/functions.cfc',
									type: 'POST',
									data: {
										method: 'deleteAttribute',
										attribute_id: $("##editAttribute" + id + " input[name='attribute_id']").val(),
										collection_object_id: $("##editAttribute" + id + " input[name='collection_object_id']").val()
									},
									success: function(response) {
										setFeedbackControlState(feedbackOutput,"deleted");
										reloadAttributes();
										// remove the form from the DOM
										$("##editAttribute" + id).remove();
									},
									error: function(xhr, status, error) {
										setFeedbackControlState(feedbackOutput,"error")
										handleFail(xhr,status,error,"deleting attribute.");
									}
								});
							});
						});
						function handleTypeChangeExisting(id) {
							var selectedType = $('##att_name' + id).val();
							// lookup value code table and units code table from ctattribute_code_tables
							// set select lists for value and units accordingly, or set as text input
							$.ajax({
								url: '/specimens/component/functions.cfc',
								type: 'POST',
								dataType: 'json',
								data: {
									collection_object_id: '#collection_object_id#',
									method: 'getAttributeCodeTables',
									attribute_type: selectedType
								},
								success: function(response) {
									console.log(response);
									// determine if the value field should be a select based on the response
									if (response[0].value_code_table) {
										$('##att_value'+id).prop('disabled', false);
										// convert the value field to a select
										$('##att_value'+id).replaceWith('<select name="attribute_value" id="att_value'+id+'" class="data-entry-select reqdClr" required></select>');
										// Populate the value select with options from the response
										// value_values is a pipe delimited list of values
										var values = response[0].value_values.split('|');
										$('##att_value'+id).append('<option value=""></option>');
										$.each(values, function(index, value) {
											$('##att_value'+id).append('<option value="' + value + '">' + value + '</option>');
										});
									} else {
										// enable as a text input, replace any existing select
										$('##att_value'+id).replaceWith('<input type="text" class="data-entry-input reqdClr" id="att_value'+id+'" name="attribute_value" value="" required>');
										$('##att_value'+id).prop('disabled', false);
									}
									// Determine if the units field should be enabled based on the response
									if (response[0].units_code_table) {
										$('##att_units'+id).prop('disabled', false);
										// convert the units field to a select
										$('##att_units'+id).replaceWith('<select name="attribute_units" id="att_units'+id+'" class="data-entry-select reqdClr" required></select>');
										// Populate the units select with options from the response
										// units_values is a pipe delimited list of values
										$('##att_units'+id).append('<option value=""></option>');
										$.each(response[0].units_values.split('|'), function(index, value) {
											$('##att_units'+id).append('<option value="' + value + '">' + value + '</option>');
										});
									} else {
										// units are either picklists or not used.
										// empty and disable the units field if units are not used
										$('##att_units'+id).val("");  
										$('##att_units'+id).prop('disabled', true);
										// remove any reqdClr class
										$('##att_units'+id).removeClass('reqdClr');
									}
								},
								error: function(xhr, status, error) {
									handleFail(xhr,status,error,"handling change of attribute type.");
								}
							});
						}
					</script>
				</div>
			</div>
		</div>
	</cfoutput>
</cffunction>

<!--- 
 deleteAttribute deletes an attribute for a collection object.
 @param attribute_id the attribute id to delete
 @param collection_object_id the collection object id to delete the attribute for
 @return a JSON object containing status = deleted or an http 500 error
--->
<cffunction name="deleteAttribute" returntype="any" access="remote" returnformat="json">
	<cfargument name="attribute_id" type="string" required="yes">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfset variables.attribute_id = arguments.attribute_id>
	<cfset variables.collection_object_id = arguments.collection_object_id>
	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="deleteAttribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="deleteAttribute_result">
				DELETE FROM attributes
				WHERE
					collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">
					AND attribute_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.attribute_id#">
			</cfquery>
			<cfif deleteAttribute_result.recordCount NEQ 1>
				<cfthrow message="Other than one row deleted.">
			</cfif>
			<cfset row = StructNew()>
			<cfset row["status"] = "deleted">
			<cfset row["id"] = variables.attribute_id>
			<cfset data[1] = row>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn serializeJson(data)>
</cffunction>

<!--- 
 updateAttribute updates an attribute for a collection object.
 @param attribute_id the attribute id to update
 @param collection_object_id the collection object id to update the attribute for
 @param attribute_type the type of attribute to update
 @param attribute_value the value of the attribute
 @param attribute_units the units of the attribute
 @param attribute_remark any remarks about the attribute
 @param determined_by_agent_id the agent id of the person who determined the attribute
 @param determined_date the date the attribute was determined
 @param determination_method how the attribute was determined
 @return a JSON object containing status = updated or an http 500 error
--->
<cffunction name="updateAttribute" returntype="any" access="remote" returnformat="json">
	<cfargument name="attribute_id" type="string" required="yes">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="attribute_type" type="string" required="yes">
	<cfargument name="attribute_value" type="string" required="yes">
	<cfargument name="attribute_units" type="string" required="no">
	<cfargument name="attribute_remark" type="string" required="no">
	<cfargument name="determined_by_agent_id" type="string" required="yes">
	<cfargument name="determined_by_agent" type="string" required="no">
	<cfargument name="determined_date" type="string" required="no">
	<cfargument name="determination_method" type="string" required="no">
	<cfset variables.attribute_id = arguments.attribute_id>
	<cfset variables.collection_object_id = arguments.collection_object_id>
	<cfset variables.attribute_type = arguments.attribute_type>
	<cfset variables.attribute_value = arguments.attribute_value>
	<cfif isdefined("arguments.attribute_units")>
		<cfset variables.attribute_units = arguments.attribute_units>
	<cfelse>
		<cfset variables.attribute_units = "">
	</cfif>
	<cfif isdefined("arguments.attribute_remark")>
		<cfset variables.attribute_remark = arguments.attribute_remark>
	<cfelse>
		<cfset variables.attribute_remark = "">
	</cfif>
	<cfset variables.determined_by_agent_id = arguments.determined_by_agent_id>
	<cfif isdefined("arguments.determined_date")>
		<cfset variables.determined_date = arguments.determined_date>
	<cfelse>
		<cfset variables.determined_date = "">
	</cfif>
	<cfif isdefined("arguments.determination_method")>
		<cfset variables.determination_method = arguments.determination_method>
	<cfelse>
		<cfset variables.determination_method = "">
	</cfif>
	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="updateAttribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateAttribute_result">
				UPDATE attributes
				SET
					attribute_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.attribute_type#">,
					attribute_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.attribute_value#">,
					attribute_units = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.attribute_units#">,
					attribute_remark = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.attribute_remark#">,
					determined_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.determined_by_agent_id#">,
					determined_date = <cfqueryparam cfsqltype="CF_SQL_DATE" value="#variables.determined_date#">,
					determination_method = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.determination_method#">
				WHERE
					collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">
					AND attribute_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.attribute_id#">
			</cfquery>
			<cfif updateAttribute_result.recordCount NEQ 1>
				<cfthrow message="Other than one row updated.">
			</cfif>
			<cfset row = StructNew()>
			<cfset row["status"] = "updated">
			<cfset row["id"] = variables.attribute_id>
			<cfset data[1] = row>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn serializeJSON(data)>
</cffunction>

<!--- 
 addAttribute adds a new attribute to a collection object.
 @param collection_object_id the collection object id to add the attribute to
 @param attribute_type the type of attribute to add
 @param attribute_value the value of the attribute
 @param attribute_units the units of the attribute
 @param attribute_remark any remarks about the attribute
 @param determined_by_agent_id the agent id of the person who determined the attribute
 @param determined_by_agent the agent who determined the attribute
 @param determined_date the date the attribute was determined
 @param determination_method how the attribute was determined
 @return a JSON object containing status = added or an http 500 error
--->
<cffunction name="addAttribute" returntype="any" access="remote" returnformat="json">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="attribute_type" type="string" required="yes">
	<cfargument name="attribute_value" type="string" required="yes">
	<cfargument name="attribute_units" type="string" required="no">
	<cfargument name="attribute_remark" type="string" required="no">
	<cfargument name="determined_by_agent_id" type="string" required="yes">
	<cfargument name="determined_by_agent" type="string" required="yes">
	<cfargument name="determined_date" type="string" required="no">
	<cfargument name="determination_method" type="string" required="no">
	<cfset variables.collection_object_id = arguments.collection_object_id>
	<cfset variables.attribute_type = arguments.attribute_type>
	<cfset variables.attribute_value = arguments.attribute_value>
	<cfif isdefined("arguments.attribute_units")>
		<cfset variables.attribute_units = arguments.attribute_units>
	<cfelse>
		<cfset variables.attribute_units = "">
	</cfif>
	<cfif isdefined("arguments.attribute_remark")>
		<cfset variables.attribute_remark = arguments.attribute_remark>
	<cfelse>
		<cfset variables.attribute_remark = "">
	</cfif>
	<cfset variables.determined_by_agent_id = arguments.determined_by_agent_id>
	<cfif isdefined("arguments.determined_date")>
		<cfset variables.determined_date = arguments.determined_date>
	<cfelse>
		<cfset variables.determined_date = "">
	</cfif>
	<cfif isdefined("arguments.determination_method")>
		<cfset variables.determination_method = arguments.determination_method>
	<cfelse>
		<cfset variables.determination_method = "">
	</cfif>
	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="addAttribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				INSERT INTO attributes (
					collection_object_id, 
					attribute_type, 
					attribute_value, 
					attribute_units, 
					attribute_remark, 
					determined_by_agent_id, 
					determined_date, 
					determination_method
				) values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.attribute_type#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.attribute_value#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.attribute_units#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.attribute_remark#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.determined_by_agent_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DATE" value="#variables.determined_date#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.determination_method#">
				)
			</cfquery>
			<cfset row = StructNew()>
			<cfset row["status"] = "added">
			<cfset row["id"] = "#variables.collection_object_id#">
			<cfset data[1] = row>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn serializeJSON(data)>
</cffunction>

<!---
 getEditLocalityHTML returns the HTML for the locality edit form.
 @param collection_object_id the collection object id to obtain the locality for
 @return a JSON object containing the HTML for the locality edit form
--->
<cffunction name="getEditLocalityHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getEditLocalityThread"> <cfoutput>
			<cftry>
				<cfoutput>
					<cfif not isdefined("collection_object_id") or not isnumeric(collection_object_id)>
						<div class="error"> Improper call. Aborting..... </div>
						<cfabort>
					</cfif>
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
						<cfset oneOfUs = 1>
						<cfelse>
						<cfset oneOfUs = 0>
					</cfif>
				</cfoutput>
				<cfquery name="l" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select distinct
						collection_object_id,
						collecting_event_id,
						LOCALITY_ID,
						nvl(sovereign_nation,'[unknown]') as sovereign_nation,
						geog_auth_rec_id,
						MAXIMUM_ELEVATION,
						MINIMUM_ELEVATION,
						ORIG_ELEV_UNITS,
						SPEC_LOCALITY,
						LOCALITY_REMARKS,
						DEPTH_UNITS,
						MIN_DEPTH,
						MAX_DEPTH,
						NOGEOREFBECAUSE,
						LAT_LONG_ID,
						LAT_DEG,
						DEC_LAT_MIN,
						LAT_MIN,
						LAT_SEC,
						LAT_DIR,
						LONG_DEG,
						DEC_LONG_MIN,
						LONG_MIN,
						LONG_SEC,
						LONG_DIR,
						DEC_LAT,
						DEC_LONG,
						UTM_ZONE,
						UTM_EW,
						UTM_NS,
						DATUM,
						ORIG_LAT_LONG_UNITS,
						DETERMINED_BY_AGENT_ID,
						coordinate_determiner,
						DETERMINED_DATE,
						LAT_LONG_REMARKS,
						MAX_ERROR_DISTANCE,
						MAX_ERROR_UNITS,
						ACCEPTED_LAT_LONG_FG,
						EXTENT,
						GPSACCURACY,
						GEOREFMETHOD,
						VERIFICATIONSTATUS,
						LAT_LONG_REF_SOURCE,
						HIGHER_GEOG,
						BEGAN_DATE,
						ENDED_DATE,
						VERBATIM_DATE,
						VERBATIM_LOCALITY,
						COLL_EVENT_REMARKS,
						COLLECTING_SOURCE,
						COLLECTING_METHOD,
						HABITAT_DESC,
						COLLECTING_TIME,
						FISH_FIELD_NUMBER,
						VERBATIMCOORDINATES,
						VERBATIMLATITUDE,
						VERBATIMLONGITUDE,
						VERBATIMCOORDINATESYSTEM,
						VERBATIMSRS,
						STARTDAYOFYEAR,
						ENDDAYOFYEAR,
						VERIFIED_BY_AGENT_ID,
						VERIFIEDBY
					from
						spec_with_loc
					where
						collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
				</cfquery>
				<cfquery name="g" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select
						GEOLOGY_ATTRIBUTE_ID,
						GEOLOGY_ATTRIBUTE,
						GEO_ATT_VALUE,
						GEO_ATT_DETERMINER_ID,
						geo_att_determiner,
						GEO_ATT_DETERMINED_DATE,
						GEO_ATT_DETERMINED_METHOD,
						GEO_ATT_REMARK
					from
						spec_with_loc
					where
						collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#"> and
						GEOLOGY_ATTRIBUTE is not null
					group by
						GEOLOGY_ATTRIBUTE_ID,
						GEOLOGY_ATTRIBUTE,
						GEO_ATT_VALUE,
						GEO_ATT_DETERMINER_ID,
						geo_att_determiner,
						GEO_ATT_DETERMINED_DATE,
						GEO_ATT_DETERMINED_METHOD,
						GEO_ATT_REMARK
				</cfquery>
				<cfquery name="ctElevUnit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select orig_elev_units from ctorig_elev_units
				</cfquery>
				<cfquery name="ctdepthUnit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select depth_units from ctdepth_units
				</cfquery>
				<cfquery name="ctdatum" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select datum from ctdatum
				</cfquery>
				<cfquery name="ctGeorefMethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select georefMethod from ctgeorefmethod
				</cfquery>
				<cfquery name="ctVerificationStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select VerificationStatus from ctVerificationStatus order by VerificationStatus
				</cfquery>
				<cfquery name="cterror" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select LAT_LONG_ERROR_UNITS from ctLAT_LONG_ERROR_UNITS
				</cfquery>
				<cfquery name="ctew" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select e_or_w from ctew
				</cfquery>
				<cfquery name="ctns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select n_or_s from ctns
				</cfquery>
				<cfquery name="ctunits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select ORIG_LAT_LONG_UNITS from ctLAT_LONG_UNITS
				</cfquery>
				<cfquery name="ctcollecting_source" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select COLLECTING_SOURCE from ctcollecting_source
				</cfquery>
				<cfquery name="ctgeology_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select geology_attribute from ctgeology_attribute order by ordinal
				</cfquery>
				<cfquery name="ctSovereignNation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
					select sovereign_nation from ctsovereign_nation order by sovereign_nation
				</cfquery>
				<cfquery name="cecount" datasource="uam_god">
					select count(collection_object_id) ct from cataloged_item
					where collecting_event_id = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value = "#l.collecting_event_id#">
				</cfquery>
				<cfquery name="loccount" datasource="uam_god">
					select count(ci.collection_object_id) ct from cataloged_item ci
					left join collecting_event on ci.collecting_event_id = collecting_event.collecting_event_id
					where collecting_event.locality_id = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value = "#l.locality_id#">
				</cfquery>
				<cfquery name="getLoc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT
						cataloged_item.collection_object_id as collection_object_id,
						cataloged_item.cat_num,
						collection.collection_cde,
						cataloged_item.accn_id,
						collection.collection,
						identification.scientific_name,
						identification.identification_remarks,
						identification.identification_id,
						identification.made_date,
						identification.nature_of_id,
						collecting_event.collecting_event_id,
						case when
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1 
							and concatencumbrances(cataloged_item.collection_object_id) like '%mask year collected%' 
						then
								replace(began_date,substr(began_date,1,4),'8888')
						else
							collecting_event.began_date
						end began_date,
						case when
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1 
							and concatencumbrances(cataloged_item.collection_object_id) like '%mask year collected%' 
						then
								replace(ended_date,substr(ended_date,1,4),'8888')
						else
							collecting_event.ended_date
						end ended_date,
						case when
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1 
							and concatencumbrances(cataloged_item.collection_object_id) like '%mask year collected%' 
						then
								'Masked'
						else
							collecting_event.verbatim_date
						end verbatim_date,
						collecting_event.startDayOfYear,
						collecting_event.endDayOfYear,
						collecting_event.habitat_desc,
						case when
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1 
							and concatencumbrances(cataloged_item.collection_object_id) like '%mask locality%' 
							and collecting_event.coll_event_remarks is not null
						then 
							'Masked'
						else
							collecting_event.coll_event_remarks
						end COLL_EVENT_REMARKS,
						locality.locality_id,
						locality.minimum_elevation,
						locality.maximum_elevation,
						locality.orig_elev_units,
						case when
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1
							and concatencumbrances(cataloged_item.collection_object_id) like '%mask locality%'
							and locality.spec_locality is not null
						then 
							'Masked'
						else
							locality.spec_locality
						end spec_locality,
						case when
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1
							and concatencumbrances(cataloged_item.collection_object_id) like '%mask locality%' 
							and accepted_lat_long.orig_lat_long_units is not null
						then 
							'Masked'
						else
							decode(accepted_lat_long.orig_lat_long_units,
								'decimal degrees',to_char(accepted_lat_long.dec_lat) || '&deg; ',
								'deg. min. sec.', to_char(accepted_lat_long.lat_deg) || '&deg; ' ||
									to_char(accepted_lat_long.lat_min) || '&acute; ' ||
									decode(accepted_lat_long.lat_sec, null, '', to_char(accepted_lat_long.lat_sec) || '&acute;&acute; ') || accepted_lat_long.lat_dir,
								'degrees dec. minutes', to_char(accepted_lat_long.lat_deg) || '&deg; ' ||
									to_char(accepted_lat_long.dec_lat_min) || '&acute; ' || accepted_lat_long.lat_dir
							)
						end VerbatimLatitude,
						case when
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1 
							and concatencumbrances(cataloged_item.collection_object_id) like '%mask locality%' 
							and accepted_lat_long.orig_lat_long_units is not null
						then 
							'Masked'
						else
							decode(accepted_lat_long.orig_lat_long_units,
								'decimal degrees',to_char(accepted_lat_long.dec_long) || '&deg;',
								'deg. min. sec.', to_char(accepted_lat_long.long_deg) || '&deg; ' ||
									to_char(accepted_lat_long.long_min) || '&acute; ' ||
									decode(accepted_lat_long.long_sec, null, '', to_char(accepted_lat_long.long_sec) || '&acute;&acute; ') || accepted_lat_long.long_dir,
								'degrees dec. minutes', to_char(accepted_lat_long.long_deg) || '&deg; ' ||
									to_char(accepted_lat_long.dec_long_min) || '&acute; ' || accepted_lat_long.long_dir
							)
						end VerbatimLongitude,
						locality.sovereign_nation,
						collecting_event.verbatimcoordinates,
						collecting_event.verbatimlatitude verblat,
						collecting_event.verbatimlongitude verblong,
						collecting_event.verbatimcoordinatesystem,
						collecting_event.verbatimSRS,
						accepted_lat_long.dec_lat,
						accepted_lat_long.dec_long,
						accepted_lat_long.max_error_distance,
						accepted_lat_long.max_error_units,
						accepted_lat_long.determined_date latLongDeterminedDate,
						accepted_lat_long.lat_long_ref_source,
						accepted_lat_long.lat_long_remarks,
						accepted_lat_long.datum,
						latLongAgnt.agent_name latLongDeterminer,
						geog_auth_rec.geog_auth_rec_id,
						geog_auth_rec.continent_ocean,
						geog_auth_rec.country,
						geog_auth_rec.state_prov,
						geog_auth_rec.quad,
						geog_auth_rec.county,
						geog_auth_rec.island,
						geog_auth_rec.island_group,
						geog_auth_rec.sea,
						geog_auth_rec.feature,
						coll_object.coll_object_entered_date,
						coll_object.last_edit_date,
						coll_object.flags,
						coll_object_remark.coll_object_remarks,
						coll_object_remark.disposition_remarks,
						coll_object_remark.associated_species,
						coll_object_remark.habitat,
						enteredPerson.agent_name EnteredBy,
						editedPerson.agent_name EditedBy,
						accn_number accession,
						concatencumbrances(cataloged_item.collection_object_id) concatenatedEncumbrances,
						concatEncumbranceDetails(cataloged_item.collection_object_id) encumbranceDetail,
						case when
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1 
							and concatencumbrances(cataloged_item.collection_object_id) like '%mask locality%' 
							and locality.locality_remarks is not null
						then 
							'Masked'
						else
								locality.locality_remarks
						end locality_remarks,
						case when
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1
							and concatencumbrances(cataloged_item.collection_object_id) like '%mask locality%' 
							and verbatim_locality is not null
						then 
							'Masked'
						else
							verbatim_locality
						end verbatim_locality,
						collecting_time,
						fish_field_number,
						min_depth,
						max_depth,
						depth_units,
						collecting_method,
						geog_auth_rec.higher_geog,
						collecting_source,
						specimen_part.derived_from_cat_item,
						decode(trans.transaction_id, null, 0, 1) vpdaccn
					FROM
						cataloged_item,
						collection,
						identification,
						collecting_event,
						locality,
						accepted_lat_long,
						preferred_agent_name latLongAgnt,
						geog_auth_rec,
						coll_object,
						coll_object_remark,
						preferred_agent_name enteredPerson,
						preferred_agent_name editedPerson,
						accn,
						trans,
						specimen_part
					WHERE
						cataloged_item.collection_id = collection.collection_id AND
						cataloged_item.collection_object_id = identification.collection_object_id AND
						identification.accepted_id_fg = 1 AND
						cataloged_item.collecting_event_id = collecting_event.collecting_event_id AND
						collecting_event.locality_id = locality.locality_id AND
						locality.locality_id = accepted_lat_long.locality_id (+) AND
						accepted_lat_long.determined_by_agent_id = latLongAgnt.agent_id (+) AND
						locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id AND
						cataloged_item.collection_object_id = coll_object.collection_object_id AND
						coll_object.collection_object_id = coll_object_remark.collection_object_id (+) AND
						coll_object.entered_person_id = enteredPerson.agent_id AND
						coll_object.last_edited_person_id = editedPerson.agent_id (+) AND
						cataloged_item.accn_id = accn.transaction_id AND
						accn.transaction_id = trans.transaction_id(+) AND
						cataloged_item.collection_object_id = specimen_part.derived_from_cat_item AND
						cataloged_item.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
					</cfquery>
				<div class="row mx-0">
					<div class="col-6 pl-0 pr-3 mb-2 float-right">
					<cfform name="loc" method="post" action="specLocality.cfm">
						<input type="hidden" name="action" value="saveChange">
						<input type="hidden" name="nothing" id="nothing">
						<input type="hidden" name="collection_object_id" value="#collection_object_id#">
						<img src="/specimens/images/map.png" height="auto" class="w-100 p-1 bg-white mt-2" alt="map placeholder"/>
						</div>
						<div class="col-6 px-0 float-left">
							<p class="font-italic text-danger pt-3">Note: Making changes to data in this form will make a new locality record for this specimen record. It will split from the shared locality.</p>
							<ul class="list-unstyled row mx-0 px-0 py-1 mb-0">
								<cfif len(getLoc.continent_ocean) gt 0>
									<li class="list-group-item col-4 px-0"><em>Continent or Ocean:</em></li>
									<li class="list-group-item col-8 px-0">#getLoc.continent_ocean#</li>
								</cfif>
								<cfif len(getLoc.sea) gt 0>
									<li class="list-group-item col-4 px-0"><em>Sea:</em></li>
									<li class="list-group-item col-8 px-0">value="#getLoc.sea#</li>
								</cfif>
								<cfif len(getLoc.country) gt 0>
									<li class="list-group-item col-4 px-0"><em>Country:</em></li>
									<li class="list-group-item col-8 px-0">#getLoc.country#</li>
								</cfif>
								<cfif len(getLoc.state_prov) gt 0>
									<li class="list-group-item col-4 px-0"><em>State:</em></li>
									<li class="list-group-item col-8 px-0">#getLoc.state_prov#</li>
								</cfif>
								<cfif len(getLoc.feature) gt 0>
									<li class="list-group-item col-4 px-0"><em>Feature:</em></li>
									<li class="list-group-item col-8 px-0">#getLoc.feature#</li>
								</cfif>
								<cfif len(getLoc.county) gt 0>
									<li class="list-group-item col-4 px-0"><em>County:</em></li>
									<li class="list-group-item col-8 px-0">#getLoc.county#</li>
								</cfif>
								<cfif len(getLoc.island_group) gt 0>
									<li class="list-group-item col-4 px-0"><em>Island Group:</em></li>
									<li class="list-group-item col-8 px-0">#getLoc.island_group#</li>
								</cfif>

								<cfif len(getLoc.island) gt 0>
									<li class="list-group-item col-4 px-0"><em>Island:</em></li>
									<li class="list-group-item col-8 px-0">#getLoc.island#</li>
								</cfif>
								<cfif len(getLoc.quad) gt 0>
									<li class="list-group-item col-4 px-0"><em>Quad:</em></li>
									<li class="list-group-item col-8 px-0">#getLoc.quad#</li>
								</cfif>
							</ul>
							<div class="py-3">
								<h4>Higher Geography
									&nbsp;&nbsp;
									<cfif len(session.roles) gt 0 and FindNoCase("manage_geography",session.roles) NEQ 0>
										<button onclick="/localities/HigherGeography.cfm?geog_auth_rec_id=#l.geog_auth_rec_id#" class="btn btn-xs btn-secondary" target="_blank"> Edit Shared Higher Geography</button>
									<cfelse>
										<button onclick="/localities/viewHigherGeography.cfm?geog_auth_rec_id=#l.geog_auth_rec_id#" class="btn btn-xs btn-secondary" target="_blank"> View </button>
									</cfif>
								</h4>
								<input type="text" value="#getLoc.higher_geog#" class="col-12 col-sm-8 reqdClr disabled">
								<input type="button" value="Change" class="btn btn-xs btn-secondary mr-2" id="changeGeogButton">
								<input type="submit" value="Save" class="btn btn-xs btn-secondary" id="saveGeogChangeButton"
			 				style="display:none">
							</div>
						</div>
						<div class="col-12 float-left px-0">
							<h1 class="h3">Specific Locality</h1>
							<ul class="list-unstyled bg-light row mx-0 px-3 pt-2 pb-2 mb-0 border">
								<li class="col-12 col-md-12 px-0 pt-1">
									<label for="spec_locality" class="data-entry-label pt-1"> Specific Locality
										&nbsp;&nbsp; <a href="/localities/Locality.cfm?locality_id=#l.locality_id#" target="_blank"> Edit Shared Specific Locality</a>
										<cfif loccount.ct eq 1>
											(unique to this specimen)
											<cfelse>
											(shared with #loccount.ct# specimens)
										</cfif>
									</label>
								</li>
								<li class="col-12 pb-1 col-md-12 pb-2 px-0">
									<cfinput type="text" class="data-entry-input" name="spec_locality" id="spec_locality" value="#l.spec_locality#" required="true" message="Specific Locality is required.">
								</li>
								<li class=" col-12 col-md-2 px-0 py-1">
									<label for="sovereign_nation" class="data-entry-label pt-1 text-right">Sovereign Nation</label>
								</li>
								<li class="col-12  col-md-10 px-0 pb-2">
									<select name="sovereign_nation" id="sovereign_nation" size="1" class="">
										<cfloop query="ctSovereignNation">
											<option <cfif isdefined("l.sovereign_nation") AND ctsovereignnation.sovereign_nation is l.sovereign_nation> selected="selected" </cfif>value="#ctSovereignNation.sovereign_nation#">#ctSovereignNation.sovereign_nation#</option>
										</cfloop>
									</select>
								</li>
								<li class=" col-12 col-md-2 py-1 px-0">
									<label for="minimum_elevation" class="data-entry-label px-2 text-right"> Min. Elevation </label>
								</li>
								<li class=" col-12 col-md-2 pb-2 px-0">
									<cfinput type="text" class="px-2 data-entry-input mr-2" name="minimum_elevation" id="minimum_elevation" value="#l.MINIMUM_ELEVATION#" validate="numeric" message="Minimum Elevation is a number.">
								</li>
								<li class=" col-12 col-md-2 py-1 px-0">
									<label for="maximum_elevation"  class="data-entry-label px-2 text-right"> Max. Elevation </label>
								</li>
								<li class=" col-12 col-md-2 pb-2 px-0">
									<cfinput type="text" class="data-entry-label px-2 mr-2" id="maximum_elevation" name="maximum_elevation" value="#l.MAXIMUM_ELEVATION#" validate="numeric" message="Maximum Elevation is a number.">
								</li>
								<li class=" col-12 col-md-2 py-1 px-0">
									<label for="orig_elev_units" class="data-entry-label px-2 text-right"> Elevation Units </label>
								</li>
								<li class=" col-12 col-md-2 pb-1 px-0">
									<select name="orig_elev_units" id="orig_elev_units" size="1">
										<option value=""></option>
										<cfloop query="ctElevUnit">
											<option <cfif #ctelevunit.orig_elev_units# is "#l.orig_elev_units#"> selected </cfif>
									value="#ctElevUnit.orig_elev_units#">#ctElevUnit.orig_elev_units#</option>
										</cfloop>
									</select>
								</li>
								<li class=" col-12 col-md-2 py-1 px-0">
									<label for="min_depth" class="data-entry-label px-2 text-right"> Min. Depth </label>
								</li>
								<li class="col-12 col-md-2 pb-1 px-0">
									<cfinput type="text" class="data-entry-input" name="min_depth" id="min_depth" value="#l.min_depth#" validate="numeric" message="Minimum Depth is a number.">
								</li>
								<li class=" col-12 col-md-2 py-1 px-0">
									<label for="max_depth" class="data-entry-label px-2 text-right"> Max. Depth </label>
								</li>
								<li class="col-12 col-md-2 pb-1 px-0">
									<cfinput type="text" id="max_depth" name="max_depth"
								value="#l.max_depth#" size="3" validate="numeric" class="data-entry-input px-2 mr-2" message="Maximum Depth is a number.">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="depth_units"  class="data-entry-label px-2 text-right"> Depth Units </label>
								</li>
								<li class=" col-12 col-md-2 pb-1 px-0">
									<select name="depth_units" id="depth_units" class="" size="1">
										<option value=""></option>
										<cfloop query="ctdepthUnit">
											<option <cfif #ctdepthUnit.depth_units# is "#l.depth_units#"> selected </cfif>
									value="#ctdepthUnit.depth_units#">#ctdepthUnit.depth_units#</option>
										</cfloop>
									</select>
								</li>
								<li class="col-12 col-md-12 pt-1 px-0">
									<label for="locality_remarks" class="data-entry-label px-2">Locality Remarks</label>
								</li>
								<li class="col-12 col-md-12 pb-1 px-0">
									<input type="text" class="data-entry-label px-2" name="locality_remarks" id="locality_remarks" value="#l.LOCALITY_REMARKS#">
								</li>
								<li class=" col-12 col-md-12 pt-1 px-0">
									<label for="NoGeorefBecause" class="data-entry-label px-2"> Not Georefererenced Because <a href="##" onClick="getMCZDocs('Not_Georeferenced_Because')">(Suggested Entries)</a> </label>
								</li>
								<li class=" col-12 col-md-12 pb-2 px-0">
									<input type="text" name="NoGeorefBecause" value="#l.NoGeorefBecause#" class="data-entry-input">
									<cfif #len(l.orig_lat_long_units)# gt 0 AND len(#l.NoGeorefBecause#) gt 0>
										<div class="redMessage"> NotGeorefBecause should be NULL for localities with georeferences.
											Please review this locality and update accordingly. </div>
										<cfelseif #len(l.orig_lat_long_units)# is 0 AND len(#l.NoGeorefBecause#) is 0>
										<div class="redMessage"> Please georeference this locality or enter a value for NoGeorefBecause. </div>
									</cfif>
								</li>
							</ul>
							<h1 class="h3 mt-3">Collecting Event</h1>
							<ul class="list-unstyled bg-light row mx-0 px-3 pt-1 pb-2 mb-0 border">
								<li class="col-12 col-md-12 px-0 pt-1 mt-2">
									<label for="verbatim_locality" class="data-entry-label px-2"> Verbatim Locality &nbsp;&nbsp; <a href="/localities/CollectingEvent.cfm?collecting_event_id=#l.collecting_event_id#" target="_blank"> Edit Shared Collecting Event</a>
										<cfif cecount.ct eq 1>
											(unique to this specimen)
											<cfelse>
											(shared with #cecount.ct# specimens)
										</cfif>
									</label>
								</li>
								<li class="col-12 col-md-12 pb-2 px-0">
									<cfinput type="text" class="data-entry-input" name="verbatim_locality" id="verbatim_locality" value="#l.verbatim_locality#" required="true" message="Verbatim Locality is required.">
								</li>
								<li class="col-12 col-md-2 py-2 px-0">
									<label for="verbatim_date" class="px-2 data-entry-label text-right">Verbatim Date</label>
								</li>
								<li class="col-12 col-md-2 pb-2 px-0">
									<cfinput type="text" class="data-entry-input" name="verbatim_date" id="verbatim_date" value="#l.verbatim_date#" required="true" message="Verbatim Date is a required text field.">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="collecting time" class="px-2 data-entry-label text-right">Collecting Time</label>
								</li>
								<li class="col-12 col-md-2 pb-2 px-0">
									<cfinput type="text" class="data-entry-input" name="collecting_time" id="collecting_time" value="#l.collecting_time#">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="ich field number" class="px-2 data-entry-label text-right"> Ich. Field Number </label>
								</li>
								<li class="col-12 col-md-2 pb-2 px-0">
									<cfinput type="text" class="px-2 data-entry-input" name="ich_field_number" id="ich_field_number" value="#l.fish_field_number#">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="startDayofYear" class="px-2 data-entry-label text-right"> Start Day of Year</label>
								</li>
								<li class="col-12 col-md-4 pb-2 px-0">
									<cfinput type="text" class="px-2 data-entry-input" name="startDayofYear" id="startDayofYear" value="#l.startdayofyear#">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="endDayofYear" class="px-2 data-entry-label text-right"> End Day of Year </label>
								</li>
								<li class="col-12 col-md-4 pb-2 px-0">
									<cfinput type="text" class="px-2 data-entry-input" name="endDayofYear" id="endDayofYear" value="#l.enddayofyear#">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="began_date" class="px-2 data-entry-label text-right">Began Date/Time</label>
								</li>
								<li class="col-12 col-md-4 pb-2 px-0">
									<input type="text" class="px-2 data-entry-input" name="began_date" id="began_date" value="#l.began_date#" class="reqdClr">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="ended_date" class="px-2  data-entry-label text-right"> Ended Date/Time </label>
								</li>
								<li class="col-12 col-md-4 pb-2 px-0">
									<input type="text" class="data-entry-input" name="ended_date" id="ended_date" value="#l.ended_date#" class="reqdClr">
								</li>
								<li class="col-12 col-md-3 py-1 px-0">
									<label for="coll_event_remarks" class="px-2  data-entry-label text-right"> Collecting Event Remarks </label>
								</li>
								<li class="col-12 col-md-9 pb-2 px-0">
									<input type="text" class="data-entry-input" name="coll_event_remarks" id="coll_event_remarks" value="#l.COLL_EVENT_REMARKS#">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="collecting_source" class="px-2 data-entry-label text-right"> Collecting Source </label>
								</li>
								<li class="col-12 col-md-4 pb-2 px-0">
									<select name="collecting_source" class="data-entry-select" id="collecting_source" size="1" class="reqdClr">
									<option value=""></option>
									<cfloop query="ctcollecting_source">
										<option <cfif #ctcollecting_source.COLLECTING_SOURCE# is "#l.COLLECTING_SOURCE#"> selected </cfif>
						value="#ctcollecting_source.COLLECTING_SOURCE#">#ctcollecting_source.COLLECTING_SOURCE#</option>
									</cfloop>
									</select>
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="collecting_method" class="data-entry-label px-2 text-right"> Collecting Method </label>
								</li>
								<li class="col-12 col-md-4 pb-2 px-0">
									<input type="text" name="collecting_method" id="collecting_method" value="#l.COLLECTING_METHOD#" >
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="habitat_desc" class="data-entry-label px-2 text-right"> Habitat </label>
								</li>
								<li class="col-12 col-md-10 pb-2 px-0">
									<input type="text" class="data-entry-input px-2" name="habitat_desc" id="habitat_desc" value="#l.habitat_desc#" >
								</li>
							</ul>
							<h1 class="h3 mt-3">Geology</h1>
							<ul id="gTab" class="list-unstyled bg-light row mx-0 px-3 pt-3 pb-2 mb-0 border">
								<cfloop query="g">
									<cfset thisAttribute=g.geology_attribute>
									<select name="geology_attribute__#geology_attribute_id#"
				id="geology_attribute__#geology_attribute_id#" size="1" class="reqdClr" onchange="populateGeology(this.id)">
										<option value="">DELETE THIS ROW</option>
										<cfloop query="ctgeology_attribute">
											<option
					<cfif thisAttribute is geology_attribute> selected="selected" </cfif>
						value="#geology_attribute#">#geology_attribute#</option>
										</cfloop>
									</select>
									<select id="geo_att_value__#geology_attribute_id#" class="reqdClr"
				name="geo_att_value__#geology_attribute_id#">
										<option value="#geo_att_value#">#geo_att_value#</option>
									</select>
									<input type="text" id="geo_att_determiner__#geology_attribute_id#"
				name="geo_att_determiner__#geology_attribute_id#" value="#geo_att_determiner#"
				size="15"
				onchange="getAgent('geo_att_determiner_id__#geology_attribute_id#','geo_att_determiner__#geology_attribute_id#','loc',this.value); return false;">
									<input type="hidden" name="geo_att_determiner_id__#geology_attribute_id#"
				id="geo_att_determiner_id__#geology_attribute_id#" value="#geo_att_determiner_id#">
									<input type="text" id="geo_att_determined_date__#geology_attribute_id#"
				name="geo_att_determined_date__#geology_attribute_id#"
				value="#dateformat(geo_att_determined_date,'yyyy-mm-dd')#"
				size="10">
									<input type="text" id="geo_att_determined_method__#geology_attribute_id#"
				name="geo_att_determined_method__#geology_attribute_id#" value="#geo_att_determined_method#"
				size="10">
									<input type="text" id="geo_att_remark__#geology_attribute_id#"
				name="geo_att_remark__#geology_attribute_id#" value="#geo_att_remark#"
				size="10">
									<img src="/images/del.gif" class="likeLink" onclick="document.getElementById('geology_attribute__#geology_attribute_id#').value='';">
								</cfloop>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="geology_attribute" class="data-entry-label px-2 text-right">Geology Attribute</label>
								</li>
								<li class="col-12 col-md-2 pb-2 px-0">
									<select name="geology_attribute" onchange="populateGeology(this.id)" id="geology_attribute" class="reqdClr data-entry-select">
										<option value=""></option>
										<cfloop query="ctgeology_attribute">
											<option value="#geology_attribute#">#geology_attribute#</option>
										</cfloop>
									</select>
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="geo_att_value" class="data-entry-label px-2 text-right"> Value</label>
								</li>
								<li class="col-12 col-md-2 pb-2 px-0">
									<select id="geo_att_value" class="reqdClr data-entry-select" name="geo_att_value">
										<option>value</option>
									</select>
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="geo_att_determiner" class="data-entry-label px-2 text-right"> Determiner</label>
								</li>
								<li class="col-12 col-md-2 pb-2 px-0">
									<input type="text" id="geo_att_determiner" name="geo_att_determiner"  class="data-entry-input" onchange="getAgent('geo_att_determiner_id','geo_att_determiner','loc',this.value); return false;">
									<input type="hidden" name="geo_att_determiner_id" id="geo_att_determiner_id">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="geo_att_determined_date" class="data-entry-label px-2 text-right"> Date</label>
								</li>
								<li class="col-12 col-md-2 pb-2 px-0">
									<input type="text" id="geo_att_determined_date" name="geo_att_determined_date" class="data-entry-input">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="geo_att_determined_method" class="data-entry-label px-2 text-right"> Method</label>
								</li>
								<li class="col-12 col-md-2 pb-2 px-0">
									<input type="text" id="geo_att_determined_method" name="geo_att_determined_method" class="data-entry-input">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="geo_att_remark" class="data-entry-label px-2 text-right"> Remark</label>
								</li>
								<li class="col-12 col-md-2 pb-2 px-0">
									<input type="text" id="geo_att_remark" name="geo_att_remark" class="data-entry-input">
								</li>
							</ul>
							<h1 class="h3 mt-3">Coordinates and Coordinate Metadata</h1>
							<ul id="llMeta" class="list-unstyled bg-light row mx-0 px-3 pt-3 pb-2 mb-0 border">
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="coordinate_determiner" class="data-entry-label px-2 text-right"> Coordinate Determiner </label>
								</li>
								<li class="col-12 col-md-10 pb-2 px-0">
									<input type="text" name="coordinate_determiner" id="coordinate_determiner" class="reqdClr" value="#l.coordinate_determiner#" onchange="getAgent('DETERMINED_BY_AGENT_ID','coordinate_determiner','loc',this.value); return false;" onKeyPress="return noenter(event);">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<input type="hidden" name="DETERMINED_BY_AGENT_ID" value="#l.DETERMINED_BY_AGENT_ID#">
									<label for="DETERMINED_DATE" class="data-entry-label px-2"> Determined Date </label>
								</li>
								<li class="col-12 col-md-10 pb-2 px-0">
									<input type="text" name="determined_date" id="determined_date"
									   value="#dateformat(l.determined_date,'yyyy-mm-dd')#" class="reqdClr">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="MAX_ERROR_DISTANCE" class="px-2 data-entry-label text-right"> Maximum Error </label>
								</li>
								<li class="col-12 col-md-2 pb-2 px-0">
									<input type="text" class="data-entry-input" name="MAX_ERROR_DISTANCE" id="MAX_ERROR_DISTANCE" value="#l.MAX_ERROR_DISTANCE#" size="6">
								</li>
								<li class="col-12 col-md-1 pb-2 px-0 mx-1">
									<select name="MAX_ERROR_UNITS" size="1" class="data-entry-select">
										<option value=""></option>
										<cfloop query="cterror">
											<option <cfif #cterror.LAT_LONG_ERROR_UNITS# is "#l.MAX_ERROR_UNITS#"> selected </cfif>
								value="#cterror.LAT_LONG_ERROR_UNITS#">#cterror.LAT_LONG_ERROR_UNITS#</option>
										</cfloop>
									</select>
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="DATUM" class="data-entry-label px-2 text-right"> Datum </label>
								</li>
								<li class="col-12 col-md-3 pb-2 px-0">
									<cfset thisDatum = #l.DATUM#>
									<select name="DATUM" id="DATUM" size="1" class="reqdClr data-entry-select">
										<option value=""></option>
										<cfloop query="ctdatum">
											<option <cfif #ctdatum.DATUM# is "#thisDatum#"> selected </cfif>
							value="#ctdatum.DATUM#">#ctdatum.DATUM#</option>
										</cfloop>
									</select>
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="georefMethod" class="data-entry-label px-2 text-right"> Georeference Method </label>
								</li>
								<li class="col-12 col-md-3 pb-2 px-0">
									<cfset thisGeoMeth = #l.georefMethod#>
									<select name="georefMethod" id="georefMethod" size="1" class="reqdClr data-entry-select">
										<cfloop query="ctGeorefMethod">
											<option
						<cfif #thisGeoMeth# is #ctGeorefMethod.georefMethod#> selected </cfif>
							value="#georefMethod#">#georefMethod#</option>
										</cfloop>
									</select>
								</li>
								<li class="col-12 col-md-1 py-1 px-0">
									<label for="extent" class="data-entry-label px-2 text-right"> Extent </label>
								</li>
								<li class="col-12 col-md-2 pb-2 px-0">
									<input type="text" name="extent" id="extent" value="#l.extent#" class="data-entry-input">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="GpsAccuracy" class="data-entry-label px-2 text-right"> GPS Accuracy </label>
								</li>
								<li class="col-12 col-md-2 pb-2 px-0">
									<input type="text" name="GpsAccuracy" id="GpsAccuracy" value="#l.GpsAccuracy#" class="data-entry-input">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="VerificationStatus" class="data-entry-label px-2 text-right"> Verification Status </label>
								</li>
								<li class="col-12 col-md-3 pb-2 px-0">
									<cfset thisVerificationStatus = #l.VerificationStatus#>
									<select name="VerificationStatus" id="VerificationStatus" size="1" class="reqdClr  data-entry-select"
				onchange="if (this.value=='verified by MCZ collection' || this.value=='rejected by MCZ collection')
									{document.getElementById('verified_by').style.display = 'block';
									document.getElementById('verified_byLBL').style.display = 'block';
									document.getElementById('verified_by').className = 'reqdClr';}
									else
									{document.getElementById('verified_by').value = '';
									document.getElementById('verified_by').style.display = 'none';
									document.getElementById('verified_byLBL').style.display = 'none';
									document.getElementById('verified_by').className = '';}">
										<cfloop query="ctVerificationStatus">
											<option
							<cfif #thisVerificationStatus# is #ctVerificationStatus.VerificationStatus#> selected </cfif>
								value="#VerificationStatus#">#VerificationStatus#</option>
										</cfloop>
									</select>
								</li>
								<li class="col-12 col-md-3 py-1 px-0">
									<cfset thisVerifiedBy = #l.verifiedby#>
									<cfset thisVerifiedByAgentId = #l.verified_by_agent_id#>
									<label for="verified_by" id="verified_byLBL" <cfif #thisVerificationStatus# EQ "verified by MCZ collection" or #thisVerificationStatus# EQ "rejected by MCZ collection">style="display:block"<cfelse>style="display:none"</cfif>> Verified by </label>
								</li>
								<li class="col-12 col-md-4 pb-2 px-0">
									<input type="text" name="verified_by" id="verified_by" value="#thisVerifiedBy#" 
						<cfif #thisVerificationStatus# EQ "verified by MCZ collection" or #thisVerificationStatus# EQ "rejected by MCZ collection">class="reqdClr data-entry-input" style="display:block"
						<cfelse>style="display:none"
						</cfif>
						onchange="if (this.value.length > 0){getAgent('verified_by_agent_id','verified_by','loc',this.value); return false;}"
				onKeyPress="return noenter(event);">
									<input type="hidden" name="verified_by_agent_id" value="#thisVerifiedByAgentId#">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="LAT_LONG_REF_SOURCE" class="data-entry-label px-2 text-right"> Reference </label>
								</li>
								<li class="col-12 col-md-10 pb-2 px-0">
									<input type="text" name="LAT_LONG_REF_SOURCE" id="LAT_LONG_REF_SOURCE"  class="reqdClr data-entry-input"
							   value="#encodeForHTML(l.LAT_LONG_REF_SOURCE)#" />
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="LAT_LONG_REMARKS" class="data-entry-label px-2 text-right"> Remarks </label>
								</li>
								<li class="col-12 col-md-10 pb-2 px-0">
									<input type="text" name="LAT_LONG_REMARKS" id="LAT_LONG_REMARKS" value="#encodeForHTML(l.LAT_LONG_REMARKS)#" class="data-entry-input">
								</li>
							</ul>
							<script>
function showLLFormat(orig_units) {
		//alert(orig_units);
		var llMeta = document.getElementById('llMeta');
		var decdeg = document.getElementById('decdeg');
		var utm = document.getElementById('utm');
		var ddm = document.getElementById('ddm');
		var dms = document.getElementById('dms');
		llMeta.style.display='none';
		decdeg.style.display='none';
		utm.style.display='none';
		ddm.style.display='none';
		dms.style.display='none';
		//alert('everything off');
		if (orig_units.length > 0) {
			//alert('got soemthing');
			llMeta.style.display='';
			if (orig_units == 'decimal degrees') {
				decdeg.style.display='';
			}
			else if (orig_units == 'UTM') {
				//alert(utm.style.display);
				utm.style.display='';
				//alert(utm.style.display);
			}
			else if (orig_units == 'degrees dec. minutes') {
				ddm.style.display='';
			}
			else if (orig_units == 'deg. min. sec.') {
				dms.style.display='';
			}
			else if (orig_units == 'unknown') {
			}
			else {
				alert('I have no idea what to do with ' + orig_units);
			}
		}
	}
		</script> 
							
							<!-- ORIGINAL UNITS -->
							<div class="col-12 col-md-12 py-1 px-0  row mx-0 px-3 pt-3 pb-2 mb-0 border">
								<label for="ORIG_LAT_LONG_UNITS" class="data-entry-label px-2 col-3 text-left"> Select Original Coordinate Units <span class="small d-block">so the appropriate format appears</span> </label>
								<cfset thisUnits = #l.ORIG_LAT_LONG_UNITS#>
								<select name="ORIG_LAT_LONG_UNITS" id="ORIG_LAT_LONG_UNITS" size="1" class="reqdClr" onchange="showLLFormat(this.value)">
									<option value="">Not Georeferenced</option>
									<cfloop query="ctunits">
										<option
						  	<cfif #thisUnits# is "#ctunits.ORIG_LAT_LONG_UNITS#"> selected </cfif>value="#ctunits.ORIG_LAT_LONG_UNITS#">#ctunits.ORIG_LAT_LONG_UNITS#</option>
									</cfloop>
								</select>
							</div>
							<ul id="decdeg" style="display: none;" class="list-unstyled bg-light col-12 row mx-0 px-3 pt-3 pb-2 mb-0 border">
								<li class="col-12 col-md-3 py-1 px-0">
									<label for="dec_lat" class="data-entry-label px-2 text-right">Decimal Latitude</label>
								</li>
								<li class="col-12 col-md-3 pb-2 px-0">
									<cfinput type="text" name="dec_lat" id="dec_lat" value="#l.dec_lat#" class="reqdClr data-entry-input" validate="numeric">
								</li>
								<li class="col-12 col-md-3 py-1 px-0">
									<label for="dec_long" class="data-entry-label px-2 text-right">Decimal Longitude</label>
								</li>
								<li class="col-12 col-md-3 pb-2 px-0">
									<cfinput type="text" name="DEC_LONG" value="#l.DEC_LONG#" id="dec_long" class="reqdClr data-entry-input" validate="numeric">
								</li>
							</ul>
							<ul id="dms" style="display: none;" class="list-unstyled bg-light row mx-0 px-3 pt-3 pb-2 mb-0 border">
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="lat_deg" class="data-entry-label px-2 text-right">Lat. Deg.</label>
								</li>
								<li class="col-12 col-md-1 pb-2 px-0">
									<cfinput type="text" name="LAT_DEG" value="#l.LAT_DEG#" size="4" id="lat_deg" class="reqdClr data-entry-input"
								 validate="numeric">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="lat_min" class="data-entry-label px-2 text-right">Lat. Min.</label>
								</li>
								<li class="col-12 col-md-1 pb-2 px-0">
									<cfinput type="text" name="LAT_MIN" value="#l.LAT_MIN#" size="4" id="lat_min" class="reqdClr data-entry-input" validate="numeric">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="lat_sec" class="data-entry-label px-2 text-right">Lat. Sec.</label>
								</li>
								<li class="col-12 col-md-1 pb-2 px-0">
									<cfinput type="text" name="LAT_SEC" value="#l.LAT_SEC#" id="lat_sec" class="reqdClr data-entry-input" validate="numeric">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="lat_dir" class="data-entry-label px-2 text-right">Lat. Dir.</label>
								</li>
								<li class="col-12 col-md-1 pb-2 px-0">
									<select name="LAT_DIR" size="1" id="lat_dir"  class="reqdClr data-entry-select">
										<option value=""></option>
										<option <cfif #l.LAT_DIR# is "N"> selected </cfif>value="N">N</option>
										<option <cfif #l.LAT_DIR# is "S"> selected </cfif>value="S">S</option>
									</select>
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="long_deg" class="data-entry-label px-2 text-right">Long. Deg.</label>
								</li>
								<li class="col-12 col-md-1 pb-2 px-0">
									<cfinput type="text" name="LONG_DEG" value="#l.LONG_DEG#" size="4" id="long_deg" class="reqdClr data-entry-input"
																	   validate="numeric">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="long_min" class="data-entry-label px-2 text-right">Long. Min.</label>
								</li>
								<li class="col-12 col-md-1 pb-2 px-0">
									<cfinput type="text" name="LONG_MIN" value="#l.LONG_MIN#" size="4" id="long_min" class="reqdClr data-entry-input"
																	   validate="numeric">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="long_sec" class="data-entry-label px-2 text-right">Long. Sec.</label>
								</li>
								<li class="col-12 col-md-1 pb-2 px-0">
									<cfinput type="text" name="LONG_SEC" value="#l.LONG_SEC#" id="long_sec"  class="reqdClr data-entry-input"
																		   validate="numeric">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="long_dir" class="data-entry-label px-2 text-right">Long. Dir.</label>
								</li>
								<li class="col-12 col-md-1 pb-2 px-0">
									<select name="LONG_DIR" size="1" id="long_dir" class="reqdClr data-entry-select">
										<option value=""></option>
										<option <cfif #l.LONG_DIR# is "E"> selected </cfif>value="E">E</option>
										<option <cfif #l.LONG_DIR# is "W"> selected </cfif>value="W">W</option>
									</select>
								</li>
							</ul>
							<ul id="ddm" style="display: none;" class="list-unstyled bg-light row mx-0 px-3 pt-3 pb-2 mb-0 border">
								<li class="col-12 col-md-2 py-1 px-0">
								<label for="dmlat_deg" class="data-entry-label px-2 text-right">
								Lat. Deg.
								<label>
								</li>
								<li class="col-12 col-md-2 pb-2 px-0">
									<input type="text" name="dmLAT_DEG" value="#l.LAT_DEG#" size="4" id="dmlat_deg" class="reqdClr data-entry-input">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
								<label for="dec_lat_min" class="data-entry-label px-2 text-right">
								Lat. Dec. Min.
								<label>
								</li>
								<li class="col-12 col-md-2 pb-2 px-0">
									<cfinput type="text" name="DEC_LAT_MIN" value="#l.DEC_LAT_MIN#" id="dec_lat_min" class="reqdClr data-entry-input"
																	   validate="numeric">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
								<label for="dmlat_dir" class="data-entry-label px-2 text-right">
								Lat. Dir.
								<label>
								</li>
								<li class="col-12 col-md-2 pb-2 px-0">
									<select name="dmLAT_DIR" size="1" id="dmlat_dir" class="reqdClr data-entry-select">
										<option value=""></option>
										<option <cfif #l.LAT_DIR# is "N"> selected </cfif>value="N">N</option>
										<option <cfif #l.LAT_DIR# is "S"> selected </cfif>value="S">S</option>
									</select>
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
								<label for="dmlong_deg" class="data-entry-label px-2 text-right">
								Long. Deg.
								<label>
								</li>
								<li class="col-12 col-md-2 pb-2 px-0">
									<cfinput type="text" name="dmLONG_DEG" value="#l.LONG_DEG#" size="4" id="dmlong_deg" class="reqdClr data-entry-input"
																	   validate="numeric">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
								<label for="dec_long_min" class="data-entry-label px-2 text-right">
								Long. Dec. Min.
								<label>
								</li>
								<li class="col-12 col-md-2 pb-2 px-0">
									<cfinput type="text" name="DEC_LONG_MIN" value="#l.DEC_LONG_MIN#" id="dec_long_min" class="reqdClr data-entry-input"
																	 validate="numeric">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
								<label for="dmlong_dir" class="data-entry-label px-2 text-right">
								Long. Dir.
								<label>
								</li>
								<li class="col-12 col-md-2 pb-2 px-0">
									<select name="dmLONG_DIR" size="1" id="dmlong_dir" class="reqdClr data-entry-select">
										<option value=""></option>
										<option <cfif #l.LONG_DIR# is "E"> selected </cfif>value="E">E</option>
										<option <cfif #l.LONG_DIR# is "W"> selected </cfif>value="W">W</option>
									</select>
								</li>
							</ul>
							<ul id="utm" style="display:none;" class="list-unstyled bg-light row mx-0 px-3 pt-3 pb-2 mb-0 border">
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="utm_zone" class="data-entry-label px-2 text-right"> UTM Zone </label>
								</li>
								<li class="col-12 col-md-2 pb-2 px-0">
									<cfinput type="text" name="UTM_ZONE" value="#l.UTM_ZONE#" id="utm_zone" class="reqdClr data-entry-input" validate="numeric">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="utm_ew" class="data-entry-label px-2 text-right"> UTM East/West </label>
								</li>
								<li class="col-12 col-md-2 pb-2 px-0">
									<cfinput type="text" name="UTM_EW" value="#l.UTM_EW#" id="utm_ew" class="reqdClr data-entry-input"
																	   validate="numeric">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="utm_ns" class="data-entry-label px-2 text-right"> UTM North/South </label>
								</li>
								<li class="col-12 col-md-2 pb-2 px-0">
									<cfinput type="text" name="UTM_NS" value="#l.UTM_NS#" id="utm_ns" class="reqdClr data-entry-input" validate="numeric">
								</li>
							</ul>
							<ul class="list-unstyled bg-light row mx-0 px-3 pt-3 pb-2 mb-0 border">
								<li class="col-12 col-md-2 py-1 px-0">
									<label class="data-entry-label px-2 text-right">Verbatim Coordinates (summary)</label>
								</li>
								<li class="col-12 col-md-2 pb-2 px-0">
									<cfinput type="text" name="verbatimCoordinates" id="verbatimCoordinates" value="#l.verbatimCoordinates#" class="data-entry-input">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label class="data-entry-label px-2 text-right">Verbatim Latitude</label>
								</li>
								<li class="col-12 col-md-2 pb-2 px-0">
									<cfinput type="text" name="verbatimLatitude" id="verbatimLatitude" value="#l.verbatimLatitude#" class="data-entry-input">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label class="data-entry-label px-2 text-right">Verbatim Longitude</label>
								</li>
								<li class="col-12 col-md-2 pb-2 px-0">
									<cfinput type="text" name="verbatimLongitude" id="verbatimLongitude" value="#l.verbatimLongitude#" class="data-entry-input">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label class="data-entry-label px-2 text-right">Verbatim Coordinate System (e.g., decimal degrees)</label>
								</li>
								<li class="col-12 col-md-2 pb-2 px-0">
									<cfinput type="text" name="verbatimCoordinateSystem" id="verbatimCoordinateSystem" value="#l.verbatimCoordinateSystem#" class="data-entry-input">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label class="data-entry-label px-2 text-right">Verbatim SRS (e.g., datum)</label>
								</li>
								<li class="col-12 col-md-2 pb-2 px-0">
									<cfinput type="text" name="verbatimSRS" id="verbatimSRS" value="#l.verbatimSRS#" class="data-entry-input">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="verbatimCoordinates" class="data-entry-label px-2 text-right"> Verbatim Coordinates </label>
								</li>
								<li class="col-12 col-md-2 pb-2 px-0">
									<cfinput type="text" name="verbatimCoordinates" value="#l.verbatimCoordinates#" id="verbatimCoordinates" class="data-entry-input">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="verbatimLatitude" class="data-entry-label px-2 text-right"> Verbatim Latitude </label>
								</li>
								<li class="col-12 col-md-2 pb-2 px-0">
									<cfinput type="text" name="verbatimLatitude" value="#l.verbatimLatitude#" id="verbatimLatitude" class="data-entry-input">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="verbatimLongitude" class="data-entry-label px-2 text-right"> Verbatim Longitude </label>
								</li>
								<li class="col-12 col-md-2 pb-2 px-0">
									<cfinput type="text" name="verbatimLongitude" value="#l.verbatimLongitude#" id="verbatimLongitude" class="data-entry-input">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="verbatimCoordinateSystem" class="data-entry-label px-2 text-right"> Verbatim Coordinate System </label>
								</li>
								<li class="col-12 col-md-2 pb-2 px-0">
									<cfinput type="text" name="verbatimCoordinateSystem" value="#l.verbatimCoordinateSystem#" id="verbatimCoordinateSystem" class="data-entry-input">
								</li>
								<li class="col-12 col-md-2 py-1 px-0">
									<label for="verbatimSRS" class="data-entry-label px-2 text-right"> Verbatim SRS </label>
								</li>
								<li class="col-12 col-md-9 pb-2 px-0">
									<cfinput type="text" name="verbatimSRS" value="#l.verbatimSRS#" id="verbatimSRS" class="data-entry-input">
								</li>
							</ul>
							<script>
		showLLFormat('#l.ORIG_LAT_LONG_UNITS#');
	</script> 
						</div>
						<cfif loccount.ct eq 1 and cecount.ct eq 1>
							<input type="submit" value="Save Changes" class="btn btn-xs btn-primary">
							<cfelse>
							<div class="mt-3">
								<input type="submit" value="Split and Save Changes" class="btn  btn-xs btn-primary">
								<span class="ml-3">A new locality and collecting event will be created with these values and changes will apply to this record only. </span> </div>
						</cfif>
					</cfform>
				</div>
				<cfcatch>
					<cfif isDefined("cfcatch.queryError") >
						<cfset queryError=cfcatch.queryError>
						<cfelse>
						<cfset queryError = ''>
					</cfif>
					<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
					<cfcontent reset="yes">
					<cfheader statusCode="500" statusText="#message#">
					<div class="container">
						<div class="row">
							<div class="alert alert-danger" role="alert"> <img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
								<h2>Internal Server Error.</h2>
								<p>#message#</p>
								<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
							</div>
						</div>
					</div>
				</cfcatch>
			</cftry>
		</cfoutput> </cfthread>
	<cfthread action="join" name="getEditLocalityThread" />
	<cfreturn getEditLocalityThread.output>
</cffunction>

<cffunction name="getEditRelationsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfset variables.collection_object_id = arguments.collection_object_id>
	<cfthread name="getEditRelationsThread">
		<cfoutput>
			<cftry>
				<cfquery name="ctReln" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT biol_indiv_relationship
					FROM ctbiol_relations
				</cfquery>
				<cfquery name="thisCollId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT collection.collection, cat_num, institution_acronym, cataloged_item.collection_cde, cataloged_item.collection_object_id
					FROM cataloged_item
						join collection on cataloged_item.collection_id=collection.collection_id
					WHERE 
						cataloged_item.collection_object_id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#variables.collection_object_id#">
				</cfquery>
				<div id="relationshipEditorDiv">
					<div class="container-fluid">
						<div class="row">
							<div class="col-12 float-left">
								<div class="add-form float-left">
									<div class="add-form-header pt-1 px-2 col-12 float-left">
										<h2 class="h3 my-0 px-1 pb-1">Add New Relationship to #thisCollId.institution_acronym#:#thisCollId.collection_cde#:#thisCollId.cat_num#</h2>
									</div>
									<div class="card-body">
										<form name="newRelationshipForm" id="newRelationshipForm">
											<input type="hidden" name="collection_object_id" value="#thisCollId.collection_object_id#">
											<input type="hidden" name="method" value="createBiolIndivRelation">
											<div class="row mx-0 pb-0">
												<div class="col-12 col-md-6 px-1 mt-3">
													<label class="data-entry-label">Relationship:</label>
													<select name="biol_indiv_relationship" size="1" class="reqdClr data-entry-select" required>
														<cfloop query="ctReln">
															<option value="#ctReln.biol_indiv_relationship#">#ctReln.biol_indiv_relationship#</option>
														</cfloop>
													</select>
												</div>
												<div class="col-12 col-md-6 px-1 mt-3">
													<input type="hidden" id="target_collection_object_id" name="target_collection_object_id" value="">
													<label class="data-entry-label" for="target_guid">Related Cataloged Item:</label>
													<input type="text" id="target_guid" name="target_guid" size="50" class="data-entry-input reqdClr" required>
												</div>
												<div class="col-12 col-md-12 px-1 mt-3">
													<label class="data-entry-label">Remarks:</label>
													<input type="text" id="" name="biol_indiv_relation_remarks" size="50" class="data-entry-input">
												</div>
												<div class="col-12 col-md-3 px-1">
													<input type="submit" id="createRelButton" value="Add Relationship" class="btn btn-xs btn-primary">
												</div>
												<div class="col-12 col-md-9 px-1 mt-3">
													<output id="relationshipFormOutput"></output>
												</div>
											</div>
										</form>
										<script>
											$(document).ready(function() {
												makeCatalogedItemAutocompleteMeta("target_guid", "target_collection_object_id");
												$("##newRelationshipForm").on("submit", createRelationship);
											});
										</script>
										<script>
											function createRelationship(event) {
												event.preventDefault();
												setFeedbackControlState("relationshipFormOutput","saving")
												// ajax post of the form data to create a new relationship
												$.ajax({
													type: "POST",
													url: "/specimens/component/functions.cfc",
													data: $("##newRelationshipForm").serialize(),
													success: function(response) {
														setFeedbackControlState("relationshipFormOutput","saved")
														reloadRelationships();
													},
													error: function(xhr, status, error) {
														setFeedbackControlState("relationshipFormOutput","error")
														handleFail(xhr,status,error,"saving changes to relationship");
													}
												});
											}
											function reloadRelationships() { 
												// reload the relationship list
												$.ajax({
													type: "POST",
													url: "/specimens/component/functions.cfc",
													data: {
														method: "getRelationshipDetailHTML",
														collection_object_id: "#thisCollId.collection_object_id#"
													},
													success: function(data) {
														$("##relationshipDialogList").html(data);
													},
													error: function(xhr, status, error) {
														handleFail(xhr,status,error,"loading specimen media list for editing");
													}
												});
											} 
										</script>
									</div>
								</div>
								<div id="relationshipDialogList" class="col-12 float-left mt-4 mb-4 px-0">
									<!--- include output from getRelationshipDetailHTML to show list of relationships for the cataloged item --->
									<cfset namedGroupList = getRelationshipDetailHTML(collection_object_id = variables.collection_object_id)>
								</div>
							</div>
						</div>
					</div>
				</div>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getEditRelationsThread" />
	<cfreturn getEditRelationsThread.output>
</cffunction>

<cffunction name="getRelationshipDetailHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfset variables.collection_object_id = arguments.collection_object_id>
	<cfoutput>
		<cftry>
			<cfquery name="ctReln" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT biol_indiv_relationship
				FROM ctbiol_relations
			</cfquery>
			<cfquery name="relns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT 
					distinct biol_indiv_relationship, biol_indiv_relations_id,
					related_collection, related_coll_object_id, related_collection_cde, related_institution_acronym, related_cat_num, 
					biol_indiv_relation_remarks, direction 
				FROM (
					SELECT
						rel.biol_indiv_relationship as biol_indiv_relationship,
						collection as related_collection,
						collection.collection_cde as related_collection_cde,
						collection.institution_acronym as related_institution_acronym,
						rel.related_coll_object_id as related_coll_object_id,
						rcat.cat_num as related_cat_num,
						rel.biol_indiv_relation_remarks as biol_indiv_relation_remarks,
						rel.biol_indiv_relations_id,
						'forward' as direction
					FROM
						biol_indiv_relations rel
						left join cataloged_item rcat
						on rel.related_coll_object_id = rcat.collection_object_id
						left join collection
							on collection.collection_id = rcat.collection_id
						left join ctbiol_relations ctrel
							on rel.biol_indiv_relationship = ctrel.biol_indiv_relationship
					WHERE rel.collection_object_id = <cfqueryparam value="#variables.collection_object_id#" cfsqltype="CF_SQL_DECIMAL"> 
							and ctrel.rel_type <> 'functional'
					UNION
					SELECT
						ctrel.inverse_relation as biol_indiv_relationship,
						collection as related_collection,
						collection.collection_cde as related_collection_cde,
						collection.institution_acronym as related_institution_acronym,
						irel.collection_object_id as related_coll_object_id,
						rcat.cat_num as related_cat_num,
						irel.biol_indiv_relation_remarks as biol_indiv_relation_remarks,
						irel.biol_indiv_relations_id,
						'inverse' as direction
					FROM
						biol_indiv_relations irel
						left join ctbiol_relations ctrel
							on irel.biol_indiv_relationship = ctrel.biol_indiv_relationship
						left join cataloged_item rcat
							on irel.collection_object_id = rcat.collection_object_id
						left join collection
						on collection.collection_id = rcat.collection_id
					WHERE irel.related_coll_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
						and ctrel.rel_type <> 'functional'
				)
			</cfquery>
			<cfif relns.recordcount GT 0>
				<cfset inverseRelations = "">
				<cfset i = 0>
				<cfloop query="relns">
					<cfif direction EQ "forward">
						<cfset i = i + 1>
						<form id="editRelationForm_#i#" name="editRelationForm_#i#" onsubmit="return false;" class="mb-0">
							<div class="row m-0 py-1 px-1 border">
								<input type="hidden" name="method" id="method_#i#" value="updateBiolIndivRelation">
								<input type="hidden" name="biol_indiv_relations_id" value="#biol_indiv_relations_id#">
								<input type="hidden" name="collection_object_id" value="#variables.collection_object_id#">
								<div class="col-12 col-md-3 px-0">
									<label class="data-entry-label" for="biol_indiv_relationship_#i#">Relationship:</label>
									<select name="biol_indiv_relationship" size="1" class="data-entry-select" required id="biol_indiv_relationship_#i#">
										<cfloop query="ctReln">
											<cfset selected = "">
											<cfif relns.biol_indiv_relationship EQ ctReln.biol_indiv_relationship>
												<cfset selected = "selected">
											</cfif>
											<option value="#ctReln.biol_indiv_relationship#" #selected#>#ctReln.biol_indiv_relationship#</option>
										</cfloop>
									</select>
								</div>
								<cfset guid = "#relns.related_institution_acronym#:#relns.related_collection_cde#:#relns.related_cat_num#">
								<div class="col-12 col-md-3">
									<label class="data-entry-label" for="target_collection_object_id_#i#">
										To:
										<a href="/specimens/Specimen.cfm?collection_object_id=#related_coll_object_id#" target="_blank">
											#guid#
										</a>
									</label>
									<input type="hidden" id="target_collection_object_id_#i#" name="target_collection_object_id" value="#related_coll_object_id#">
									<input type="text" id="target_guid_#i#" name="target_guid" size="50" class="data-entry-input" value="#guid#">
									<script>
										$(document).ready(function() {
											makeCatalogedItemAutocompleteMeta("target_guid_#i#", "target_collection_object_id_#i#");
										});
									</script>
								</div>
								<div class="col-12 col-md-6 px-0">
									<label class="data-entry-label" for="remarks_#i#" >Remarks:</label>
									<input class="data-entry-input" type="text" id="remarks_#i#" name="biol_indiv_relation_remarks" value="#biol_indiv_relation_remarks#">
								</div>
								<div class="col-12 col-md-2">
									<input type="button" id="updateButton_#i#" value="Update" class="btn btn-xs btn-secondary" onclick="doSave('#i#')">
								</div>
								<div class="col-12 col-md-2">
									<input type="button" id="deleteButton_#i#"
										value="Delete" class="btn btn-xs btn-warning" 
										onclick=" confirmDialog('Delete this relationship (#relns.biol_indiv_relationship# #guid#)?', 'Confirm Delete Relationship', function() { doDelete('#i#'); }  );">
								</div>
								<div class="col-12 col-md-8">
									<output id="editRelationFormOutput_#i#"></output>
								</div>
							</div>
						</form>
					<cfelse>
						<cfset inverseRelations =  "#inverseRelations#<li>#relns.biol_indiv_relationship# <a href='/Specimen.cfm?collection_object_id=#related_coll_object_id#' target='_blank'> #relns.related_institution_acronym#:#relns.related_collection_cde#:#relns.related_cat_num#</a> #relns.biol_indiv_relation_remarks# </li>"><!--- " --->
					</cfif>
				</cfloop>
				<cfif len(inverseRelations) GT 0>
					<div class="row mx-0 mt-3">
						<div class="col-12">
							<strong>Inverse Relationships:</strong>
							<ul>
								#inverseRelations#
							</ul>
						</div>
					</div>
				</cfif>
				<script>
					function doSave(formId) {
						setFeedbackControlState("editRelationFormOutput_"+formId,"saving")
						var form = "editRelationForm_" + formId;
						$("##method_" + formId).val("updateBiolIndivRelation");
						var formData = $("##" + form).serialize();
						$.ajax({
							type: "POST",
							url: "/specimens/component/functions.cfc",
							data: formData,
							success: function(response) {
								setFeedbackControlState("editRelationFormOutput_"+formId,"saved")
								reloadRelationships();
							},
							error: function(xhr, status, error) {
								setFeedbackControlState("editRelationFormOutput_"+formId,"error")
								handleFail(xhr,status,error,"updating relationship");
							}
						});
					}
					function doDelete(formId) {
						setFeedbackControlState("editRelationFormOutput_"+formId,"deleting")
						var form = "editRelationForm_" + formId;
						$("##method_" + formId).val("deleteBiolIndivRelation");
						var formData = $("##" + form).serialize();
						$.ajax({
							type: "POST",
							url: "/specimens/component/functions.cfc",
							data: formData,
							success: function(response) {
								setFeedbackControlState("editRelationFormOutput_"+formId,"deleted")
								reloadRelationships();
							},
							error: function(xhr, status, error) {
								setFeedbackControlState("editRelationFormOutput_"+formId,"error")
								handleFail(xhr,status,error,"deleting relationship");
							}
						});
					}
				</script>
			<cfelse>
				<div class="row mx-0 mt-3">
					<strong>No Relationships to this cataloged item</strong>
				</div>
			</cfif>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cfoutput>
</cffunction>

<!--- ** function createBiolIndivRelation  
 * Creates a new relationship between two collection objects.
 * @param collection_object_id - the collection object id of the first object
 * @param biol_indiv_relationship - the type of relationship
 * @param target_collection_object_id - the collection object id of the second object
 * @param biol_indiv_relation_remarks - optional remarks about the relationship
 * @return JSON object with status and id of the created relationship
--->
<cffunction name="createBiolIndivRelation" returntype="any" access="remote" returnformat="json">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="biol_indiv_relationship" type="string" required="yes">
	<cfargument name="target_collection_object_id" type="string" required="yes">
	<cfargument name="biol_indiv_relation_remarks" type="string" required="no" default="">

	<cfset variables.collection_object_id = arguments.collection_object_id>
	<cfset variables.biol_indiv_relationship = arguments.biol_indiv_relationship>
	<cfset variables.target_collection_object_id = arguments.target_collection_object_id>
	<cfset variables.biol_indiv_relation_remarks = arguments.biol_indiv_relation_remarks>

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="addRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="addRelation_result">
				INSERT INTO biol_indiv_relations
				(
					collection_object_id,
					biol_indiv_relationship,
					related_coll_object_id,
					biol_indiv_relation_remarks,
					created_by
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.biol_indiv_relationship#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.target_collection_object_id#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.biol_indiv_relation_remarks#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				)
			</cfquery>
			<cfif addRelation_result.recordcount NEQ 1>
				<cfthrow message="Error: Other than one record created">
			</cfif>
			<cfquery name="getPK" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="pkResult">
					SELECT biol_indiv_relations_id id
					FROM biol_indiv_relations
					WHERE ROWIDTOCHAR(rowid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#addRelation_result.GENERATEDKEY#">
			</cfquery>
			<cftransaction action="commit">
			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["id"] = "#getPk.id#">
			<cfset data[1] = row>
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn serializeJSON(data)>
</cffunction>


<!--- ** function updateBiolIndivRelation  
 * Updates a relationship between two collection objects.
 * @param biol_indiv_relations_id - the id of the relationship to update
 * @param collection_object_id - the collection object id of the first object
 * @param biol_indiv_relationship - the type of relationship
 * @param target_collection_object_id - the collection object id of the second object
 * @param biol_indiv_relation_remarks - optional remarks about the relationship
 * @return JSON object with status and id of the relationship
--->
<cffunction name="updateBiolIndivRelation" returntype="any" access="remote" returnformat="json">
	<cfargument name="biol_indiv_relations_id" type="string" required="yes">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="biol_indiv_relationship" type="string" required="yes">
	<cfargument name="target_collection_object_id" type="string" required="yes">
	<cfargument name="biol_indiv_relation_remarks" type="string" required="yes">

	<cfset variables.biol_indiv_relations_id = arguments.biol_indiv_relations_id>
	<cfset variables.collection_object_id = arguments.collection_object_id>
	<cfset variables.biol_indiv_relationship = arguments.biol_indiv_relationship>
	<cfset variables.target_collection_object_id = arguments.target_collection_object_id>
	<cfset variables.biol_indiv_relation_remarks = arguments.biol_indiv_relation_remarks>

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="updateRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateRelation_result">
				UPDATE biol_indiv_relations
				SET
					collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">,
					biol_indiv_relationship = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.biol_indiv_relationship#">,
					related_coll_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.target_collection_object_id#">,
					biol_indiv_relation_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.biol_indiv_relation_remarks#">
				WHERE biol_indiv_relations_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.biol_indiv_relations_id#">
			</cfquery>
			<cfif updateRelation_result.recordcount NEQ 1>
				<cfthrow message="Error: Other than one record updated.">
			</cfif>
			<cftransaction action="commit">
			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["id"] = "#variables.biol_indiv_relations_id#">
			<cfset data[1] = row>
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn serializeJSON(data)>
</cffunction>

<!--- ** function deleteBiolIndivRelation  
 * Deletes a relationship between two collection objects.
 * @param biol_indiv_relations_id - the id of the relationship to update
 * @return JSON object with status and id of the deleted relationship
--->
<cffunction name="deleteBiolIndivRelation" returntype="any" access="remote" returnformat="json">
	<cfargument name="biol_indiv_relations_id" type="string" required="yes">
	<cfset variables.biol_indiv_relations_id = arguments.biol_indiv_relations_id>

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="deleteRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="deleteRelation_result">
				DELETE FROM biol_indiv_relations
				WHERE biol_indiv_relations_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.biol_indiv_relations_id#">
			</cfquery>
			<cfif deleteRelation_result.recordcount NEQ 1>
				<cfthrow message="Error: Other than one record deleted">
			</cfif>
			<cftransaction action="commit">
			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["id"] = "#variables.biol_indiv_relations_id#">
			<cfset data[1] = row>
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn serializeJSON(data)>
</cffunction>

<!--- obtain an html rendering of the condition history of a specimen part suitable for display in a dialog 
 @param collection_object_id the collection_object_id of the part for which to obtain the condition history
 @return html block listing condition history for the specified part
--->
<cffunction name="getPartConditionHistoryHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getPartCondHist">
		<cfoutput>
			<cftry>
				<!---- lookup cataloged item for collection object or part we are getting the condition history of ---->
				<cfquery name="itemDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT
						'cataloged item' part_name,
						cat_num,
						collection.collection,
						MCZBASE.get_scientific_name_auths(cataloged_item.collection_object_id) as scientific_name
					FROM
						cataloged_item
						left join collection on cataloged_item.collection_id = collection.collection_id
					WHERE
						cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
					UNION
					SELECT
						part_name,
						cat_num,
						collection.collection,
						MCZBASE.get_scientific_name_auths(cataloged_item.collection_object_id) as scientific_name
					FROM
						cataloged_item
						left join collection on cataloged_item.collection_id = collection.collection_id
						left join specimen_part on  cataloged_item.collection_object_id = specimen_part.derived_from_cat_item
					WHERE
						specimen_part.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
				</cfquery>
				<div> <strong>Condition History of #itemDetails.collection# #itemDetails.cat_num# (<i>#itemDetails.scientific_name#</i>) #itemDetails.part_name# </strong> </div>
				
				<!--- lookup part history --->
				<cfquery name="cond" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT
						object_condition_id,
						determined_agent_id,
						agent_name,
						determined_date,
						condition
					FROM
						object_condition,preferred_agent_name
					where 
						determined_agent_id = agent_id and
						collection_object_id = #collection_object_id#
					group by
						object_condition_id,
						determined_agent_id,
						agent_name,
						determined_date,
						condition
					order by 
						determined_date DESC
				</cfquery>
				<table class="table table-responsive border table-striped table-sm">
					<tr>
						<td><strong>Determined By</strong></td>
						<td><strong>Date</strong></td>
						<td><strong>Condition</strong></td>
					</tr>
					<cfloop query="cond">
						<tr>
							<td>#encodeForHtml(agent_name)#</td>
							<td>#dateformat(determined_date,"yyyy-mm-dd")#</td>
							<td>#condition#</td>
						</tr>
					</cfloop>
				</table>
				<cfcatch>
					<cfset error_message = cfcatchToErrorMessage(cfcatch)>
					<cfset function_called = "#GetFunctionCalledName()#">
					<h2 class="h3">Error in #function_called#:</h2>
					<div>#error_message#</div>
				</cfcatch>
			</cftry>
		</cfoutput> 
	</cfthread>
	<cfthread action="join" name="getPartCondHist" />
	<cfreturn getPartCondHist.output>
</cffunction>

<!---
Function getEncumbranceAutocompleteMeta.  Search for encumbrances, returning json suitable for jquery-ui autocomplete
 with a _renderItem overriden to display more detail on the picklist, and the encumbrance as the selected value.

@param term information to search for.
@return a json structure containing id and value, with encumbrance in value and encumbrane_id in id, and encumbrance with more data in meta.
--->
<cffunction name="getEncumbranceAutocompleteMeta" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result">
			SELECT
				encumbrance_id, 
				expiration_event, 
				to_char(expiration_date,'yyyy-mm-dd') as expiration_date, 
				encumbrance,
				mczbase.get_agentnameoftype(encumbering_agent_id,'preferred') as by_agent
			FROM
				encumbrance
			WHERE
				lower(encumbrance) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#lcase(term)#%">
				OR
				lower(remarks) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#lcase(term)#%">
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.encumbrance_id#">
			<cfset row["value"] = "#search.encumbrance#" >
			<cfset row["meta"] = "#search.encumbrance# (#by_agent# Expires:#search.expiration_event# #search.expiration_date#)" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
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

<!--- obtain a block of html listing encumbrances for a cataloged item 
  @param collection_object_id the primary key for the cataloged item for which to list encumbrances 
  @param containing_block the id, without a leading pound for an element in the dom that is to be
    passed to removeFromEncumbrance and reloaded on success.
  @return a block of html with encumbrances, expects the javascript function 
    removeFromEncumbrance(encumbrance_id, collection_object_id, updateBlockId) to be in scope.
--->
<cffunction name="getEncumbrancesHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="containing_block" type="string" required="yes">

	<cfset variables.collection_object_id = arguments.collection_object_id>
	<cfset variables.containing_block = arguments.containing_block>
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >	
	<cfthread name="getEncumbThread#tn#">
		<cfoutput>
			<cftry>
					<cfquery name="getEncumbrances" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						select 
							collection_object_id,
							encumbrance.encumbrance_id,
							encumbrance,
							encumbrance_action,
							MCZBASE.get_agentnameoftype(encumbrance.encumbering_agent_id) AS encumbering_agent, 
							encumbrance.made_date AS encumbered_date, 
							expiration_date,
							expiration_event,
							remarks
						FROM coll_object_encumbrance
							join encumbrance on coll_object_encumbrance.encumbrance_id = encumbrance.encumbrance_id
						WHERE 
							collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
					</cfquery>
					<ul>
					<cfif getEncumbrances.recordcount EQ 0>
						<li>None</li>
					</cfif>
					<cfloop query="getEncumbrances">
						<li>
							#encumbrance# (#encumbrance_action#) 
							by #encumbering_agent# made 
							#dateformat(encumbered_date,"yyyy-mm-dd")#, 
							expires #dateformat(expiration_date,"yyyy-mm-dd")# 
							#expiration_event# #remarks#
							<form name="removeEncumb_#collection_object_id#_#encumbrance_id#">
								<input type="button" value="Remove" class="btn btn-xs btn-warning"
									aria-label="Remove this cataloged item from this encumbrance"
									onClick="removeFromEncumbrance(#encumbrance_id#,#getEncumbrances.collection_object_id#,'#containing_block#');">
							</form>
						</li>
					</cfloop>
					</ul>
				<cfcatch>
					<cfset error_message = cfcatchToErrorMessage(cfcatch)>
					<cfset function_called = "#GetFunctionCalledName()#">
					<h2 class="h3">Error in #function_called#:</h2>
					<div>#error_message#</div>
				</cfcatch>
			</cftry>
		</cfoutput> 
	</cfthread>
	<cfthread action="join" name="getEncumbThread#tn#" />
	<cfreturn cfthread["getEncumbThread#tn#"].output>
</cffunction>

<!--- function removeObjectFromEncumbrance remove a cataloged item from an encumbrance
  @param collection_object_id the cataloged item to remove from the encumbrance
  @param encumbrance_id the encumbrance from which to remove the item.
  @return a json structure with status=removed, or an http 500 response.
--->
<cffunction name="removeObjectFromEncumbrance" returntype="any" access="remote" returnformat="json">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="encumbrance_id" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>	
			<cfquery name="removeFromEncumbrance" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="removeFromEncumbrance_result">
				DELETE 
				FROM coll_object_encumbrance
				WHERE
					encumbrance_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#encumbrance_id#"> AND
					collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
			</cfquery>
			<cfif removeFromEncumbrance_result.recordcount EQ 1>
				<cftransaction action="commit"/>
				<cfset row = StructNew()>
				<cfset row["status"] = "removed">
				<cfset row["id"] = "#encumbrance_id#">
				<cfset data[1] = row>
			<cfelse>
				<cfthrow message="Error other than one row affected.">
			</cfif>
		<cfcatch>
			<cftransaction action="rollback"/>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>

	<cfreturn #serializeJSON(data)#>
</cffunction>


<!--- getPartContainersHTML get a block of html containing container hierarchy placement for a collection object
 @param collection_object_id for the part, or list of parts, for which to return containers.
 @return a block of html suitable for placement within a dialog listing container hierarchy placement.
--->
<cffunction name="getPartContainersHTML" access="remote" returntype="any" returnformat="json">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >	
	<cfthread name="getContainerThread#tn#">
		<cfoutput>
			<cftry>
				<cfquery name="getPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT DISTINCT
						flat.guid,
						specimen_part.collection_object_id part_id,
						pc.label, 
						pc.container_id as container_id,
						nvl2(specimen_part.preserve_method, specimen_part.part_name || ' (' || specimen_part.preserve_method || ')',specimen_part.part_name) part_name,
						specimen_part.sampled_from_obj_id,
						coll_object.COLL_OBJ_DISPOSITION part_disposition,
						coll_object.CONDITION part_condition,
						nvl2(coll_object.lot_count_modifier, coll_object.lot_count_modifier || coll_object.lot_count, coll_object.lot_count) lot_count
					FROM
						specimen_part
						left join coll_object on specimen_part.collection_object_id=coll_object.collection_object_id
						left join coll_obj_cont_hist on coll_object.collection_object_id=coll_obj_cont_hist.collection_object_id
						left join container oc on coll_obj_cont_hist.container_id=oc.container_id
						left join container pc on oc.parent_container_id=pc.container_id
						left join flat on specimen_part.DERIVED_FROM_CAT_ITEM = flat.collection_object_id
					WHERE
						specimen_part.derived_from_cat_item in (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#" list="yes">)
				</cfquery>
				<cfloop query="getPart">
					<cfif len(getPart.sampled_from_obj_id) GT 0><cfset subsample=" [subsample] "><cfelse><cfset subsample=""></cfif> 
					<h3>Container Placement for #getPart.guid# #getPart.part_name# #subsample#</h3>
					<cfquery name="container_parentage" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT
							label, barcode, 
							to_char(parent_install_date,'yyyy-mm-dd') parent_install_date, 
							container_remarks, container_type,
							container_id, parent_container_id
						FROM
							container
						START WITH container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getPart.container_id#">
						CONNECT BY PRIOR parent_container_id = container_id
					</cfquery>
					<ul class="listgroup">
						<cfloop query="container_parentage">
							<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_container")>
								<li class="listgroupitem">
									<a href="/findContainer.cfm?barcode=#container_parentage.barcode#" target="_blank">#container_parentage.barcode#</a>
									(#container_parentage.container_type#) 
									<cfif len(container_parentage.parent_install_date) GT 0>
										install date #container_parentage.parent_install_date#
									</cfif>
								</li>
							<cfelse>
								<li><#container_parentage.barcode#</a> (#container_parentage.container_type#)</li>
							</cfif>
						</cfloop>
					</ul>
				</cfloop>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class='h3'>Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getContainerThread#tn#"/>
	<cfreturn cfthread["getContainerThread#tn#"].output>
</cffunction>	

<!---function getEditNamedGroupsHTML obtain an html block to popluate an edit dialog for named groups for 
 a cataloged item
 @param collection_object_id the cataloged item for which to edit named group membership.
 @return html for editing the named group membership of a cataloged item
 @see getNamedGroupsDetailHTML for the html block listing named group membership of a cataloged item.
--->
<cffunction name="getEditNamedGroupsHTML" returntype="string" access="remote" returnformat="plain">

	<cfargument name="collection_object_id" type="string" required="yes">

	<cfset variables.collection_object_id = arguments.collection_object_id>

	<cfthread name="getNamedGroupThread">
		<cftry>
			<cfoutput>
				<div id="namedgroupHTML">
					<div class="container-fluid">
						<div class="row">
							<div class="col-12 float-left">
								<div class="add-form float-left">
									<div class="add-form-header pt-1 px-2 col-12 float-left">
										<h2 class="h3 my-0 px-1 pb-1">Add to Named Group</h2>
									</div>
									<div class="card-body">
										<!--- form to add current cataloged item to a named group --->
										<form name="addToNamedGroup">
											<div class="form-row">
												<div class="col-12 col-md-11 pt-3 px-2">
													<label for="underscore_collection_id">Add this cataloged item to Named Group:</label>
													<input type="hidden" name="underscore_collection_id" id="underscore_collection_id">
													<input type="text" name="underscore_collection_name" id="underscore_collection_name" class="data-entry-input">
												</div>
												<div class="col-1 col-md-1 pt-3">
													<label for="addButton" class="data-entry-label">&nbsp;</label>
													<input type="button" value="Add" class="btn btn-xs btn-primary" id="addButton"
														onClick="handleAddToNamedGroup();">
												</div>
											</div>
										</form>
										<script>
											jQuery(document).ready(function() {
												makeNamedCollectionPicker("underscore_collection_name","underscore_collection_id",true);
											});
											function reloadNamedGroupsDialogAndPage() { 
												reloadNamedGroups();
												loadNamedGroupsList("#variables.collection_object_id#","namedGroupDialogList");
											}
											function handleAddToNamedGroup() {
												var underscore_collection_id = $("##underscore_collection_id").val();
												var collection_object_id = "#variables.collection_object_id#";
												addToNamedGroup(underscore_collection_id,collection_object_id,reloadNamedGroupsDialogAndPage);
											}
										</script>
									</div><!--- end card-body for add form --->
								</div><!--- end add-form for add to named group --->
								<div id="namedGroupDialogList" class="col-12 float-left mt-4 mb-4 px-0">
									<!--- include output from getNamedGroupsDetailHTML to show list of named group membership for the cataloged item --->
									<cfset namedGroupList = getNamedGroupsDetailHTML(collection_object_id = variables.collection_object_id)>
								</div>
							</div><!--- end col-12 --->
						</div><!--- end row --->
					</div><!--- end container-fluid --->
				</div><!--- end namedgroupHTML --->
			</cfoutput>
			<cfcatch>
				<cfoutput>
					<p class="mt-2 text-danger">Error: #cfcatch.type# #cfcatch.message# #cfcatch.detail#</p>
				</cfoutput>
			</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getNamedGroupThread" />
	<cfreturn getNamedGroupThread.output>
</cffunction>


<!---function getNamedGroupsDetailHTML obtain an html block listing named groups for 
 a cataloged item with detailed information, not threaded, able to be called from another
 method that itself is threaded.
 @param collection_object_id the cataloged item for which to show named group membership.
 @return, nothing, but output is html showing the named group membership of a cataloged item 
	or an error message.
 @see getEditNamedGroupsHTML which calls this function.
--->
<cffunction name="getNamedGroupsDetailHTML" returntype="string" access="remote" returnformat="plain">

	<cfargument name="collection_object_id" type="string" required="yes">

	<cfset variables.collection_object_id = arguments.collection_object_id>

	<cftry>
		<cfquery name="getUnderscoreRelations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT 
				underscore_collection.underscore_collection_id, collection_name,
				decode(mask_fg, 1, 'Hidden', '') as mask_fg,
				underscore_collection_type,
				to_char(underscore_relation.timestampadded,'yyyy-mm-dd') as date_added,
				underscore_relation.createdby as created_by
			FROM 
				underscore_relation
				join underscore_collection on underscore_relation.underscore_collection_id = underscore_collection.underscore_collection_id
			WHERE 	
				underscore_relation.collection_object_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">
			ORDER BY 
				underscore_collection.collection_name
		</cfquery>
		<cfoutput>
			<h2 class="h3">Named Groups</h2>
			<ul>
				<cfif getUnderscoreRelations.recordcount EQ 0>
					<li>None</li>
				</cfif>
				<cfloop query="getUnderscoreRelations">
					<li>
						<strong>#getUnderscoreRelations.mask_fg#</strong>
						<a href="/grouping/showNamedCollection.cfm?underscore_collection_id=#encodeForUrl(getUnderscoreRelations.underscore_collection_id)#"
							target="_blank">#getUnderscoreRelations.collection_name#</a>
						(#getUnderscoreRelations.underscore_collection_type#)
						<span class="smaller-text"> relation added by #getUnderscoreRelations.created_by# on #getUnderscoreRelations.date_added#</span>
						<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_specimens")>
							<input type="button" value="Remove" class="btn btn-xs btn-warning"
								aria-label="Remove this cataloged item from this named group"
								onClick="removeFromNamedGroup(#getUnderscoreRelations.underscore_collection_id#,#variables.collection_object_id#,reloadNamedGroupsDialogAndPage);">
						</cfif>
					</li>
				</cfloop>
			</ul>
		</cfoutput>
		<cfcatch>
			<cfoutput>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
	</cftry>
</cffunction>

<!--- function addToNamedGroup add a cataloged item to a named group
  @param underscore_collection_id the named group to which to add the item.
  @param collection_object_id the cataloged item to add to the named group
  @return a json structure with status=added, or an http 500 response.
--->
<cffunction name="addToNamedGroup" returntype="any" access="remote" returnformat="json">
	<cfargument name="underscore_collection_id" type="string" required="yes">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>	
			<cfquery name="addToNamedGroup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="addToNamedGroup_result">
				INSERT INTO underscore_relation (
					underscore_collection_id, 
					collection_object_id
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
				)
			</cfquery>
			<cfif addToNamedGroup_result.recordcount EQ 1>
				<cftransaction action="commit"/>
				<cfset row = StructNew()>
				<cfset row["status"] = "added">
				<cfset row["id"] = "#underscore_collection_id#">
				<cfset data[1] = row>
			<cfelse>
				<cfthrow message="Error other than one row affected.">
			</cfif>
		<cfcatch>
			<cftransaction action="rollback"/>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- function removeFromNamedGroup remove a cataloged item from a named group
  @param underscore_collection_id the named group from which to remove the item.
  @param collection_object_id the cataloged item to remove from the named group
  @return a json structure with status=removed, or an http 500 response.
--->
<cffunction name="removeFromNamedGroup" returntype="any" access="remote" returnformat="json">
	<cfargument name="underscore_collection_id" type="string" required="yes">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>	
			<cfquery name="removeFromNamedGroup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="removeFromNamedGroup_result">
				DELETE 
				FROM underscore_relation
				WHERE
					underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#"> AND
					collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
			</cfquery>
			<cfif removeFromNamedGroup_result.recordcount EQ 1>
				<cftransaction action="commit"/>
				<cfset row = StructNew()>
				<cfset row["status"] = "removed">
				<cfset row["id"] = "#underscore_collection_id#">
				<cfset data[1] = row>
			<cfelse>
				<cfthrow message="Error other than one row affected.">
			</cfif>
		<cfcatch>
			<cftransaction action="rollback"/>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>

</cfcomponent>
