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

<!--- updateCatNumber update the catalog number and collection id for a cataloged item identified by the collection object id.
 @param collection_object_id the collection_object_id for the cataloged item to update
 @param cat_num the new catalog number to set
 @param collection_id the new collection id to set
 @return a json structure with status=updated, or an http 500 response.
--->
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
			<cfif isdefined("session.roles") AND listfindnocase(session.roles,"MANAGE_COLLECTION")>
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

<!--- updateAccn update the accession for a cataloged item identified by the collection object id.
 @param collection_object_id the collection_object_id for the cataloged item to update
 @param accession_transaction_id the new accession_transaction_id to set
 @return a json structure with status=updated, or an http 500 response.
--->
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
								<a href="/media.cfm?action=newMedia" target="_blank" class="btn btn-xs btn-secondary float-right">Add New Media Record</a>
							</h1>
							<!--- link existing media to cataloged item --->
							<div class="add-form float-left">
								<div class="add-form-header pt-1 px-2 col-12 float-left">
									<h2 class="h3 my-0 px-1 pb-1">Relate existing media to #getGuid.guid#</h2>
								</div>
								<div class="card-body">
									<!--- form to add current media to cataloged item --->
									<form name="formLinkMedia" id="formLinkMedia" class="mb-0">
										<div class="form-row">	
											<div class="col-12 my-1">
												<label for="underscore_collection_id" class="mt-1">Filename of Media to link:</label>
												<input type="hidden" name="media_id" id="media_id">
												<input type="text" name="media_uri" id="media_uri" class="data-entry-input">
											</div>
											<div class="col-12 col-md-3 my-1">
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
											<div class="col-12 col-md-3 my-1">
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
											<div class="col-12 col-md-1 my-1">
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
			
					<div class="col-12 col-md-2">
						<cfset mediaBlock= getMediaBlockHtmlUnthreaded(media_id="#getMedia.media_id#",displayAs="thumb",captionAs="textNone")>
					
					</div>
					<div class="col-12 col-md-4">
						<!--- metadata for media record --->
						<ul class="pl-0">
							<li>
							#getMedia.auto_filename#
							</li>
							<cfif getMedia.subject is not "">
								<li>#getMedia.subject#</li>
							</cfif>
							<cfif getMedia.aspect is not "">
								<li>#getMedia.aspect#</li>
							</cfif>
							<li>#getMedia.mime_type#</li>
							<li>#getMedia.mask_media#</li>
							<li>
								(<a href="/media.cfm?action=edit&media_id=#getMedia.media_id#" target="_blank" >Edit</a>)
							</li>
						</ul>
					</div>
					<div class="col-12 col-md-4 pr-1">
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
					<div class="col-12 col-md-1 px-1">
						<button class="btn btn-xs btn-primary mt-3" onClick="removeMediaRelationship('#getMedia.media_relations_id#',reloadMediaDialogList);">Remove</button>
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
	<cfargument name="in_page" type="boolean" required="yes">

	<cfthread name="getIdentificationsThread" collection_object_id="#arguments.collection_object_id#" in_page="#arguments.in_page#">
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
					collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#attributes.collection_object_id#">
			</cfquery>
			<cfif getDetermined.recordcount EQ 0>
				<cfthrow message="No such collection_object_id.">
			</cfif>
			<cfset target = "">
			<cfset hasMissingCitations = false>
			<cfset makesMixedCollectionOnSave = false>
			<cfif getDetermined.coll_object_type EQ "CI">
				<cfquery name="getTarget" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" >
					SELECT guid
					FROM FLAT
					WHERE 
						collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#attributes.collection_object_id#">
				</cfquery>
				<cfset target = getTarget.guid>
				<!--- find any citations of this specimen for which there aren't identifications --->
				<cfquery name="getMissingCitations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" >
					SELECT distinct
						taxonomy.scientific_name,
						citation.type_status,
						citation.publication_id,
						formatted_publication.formatted_publication
					FROM 
						citation
						join taxonomy on citation.cited_taxon_name_id = taxonomy.taxon_name_id
						join formatted_publication on citation.publication_id = formatted_publication.publication_id
					WHERE 
						citation.cited_taxon_name_id not in (
							SELECT distinct identification_taxonomy.taxon_name_id
							FROM identification
								join identification_taxonomy on identification.identification_id = identification_taxonomy.identification_id
							WHERE 
								identification.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#attributes.collection_object_id#">
						)
						AND citation.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#attributes.collection_object_id#">
						AND formatted_publication.format_style = 'short'
					ORDER BY 
						taxonomy.scientific_name
				</cfquery>
				<cfif getMissingCitations.recordcount GT 0>
					<cfset hasMissingCitations = true>
				</cfif>
			<cfelseif getDetermined.coll_object_type EQ "SP">
				<cfquery name="getTarget" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" >
					SELECT guid, specimen_part.part_name, specimen_part.preserve_method
					FROM 
						specimen_part
						join FLAT on specimen_part.derived_from_cat_item = flat.collection_object_id 
					WHERE 
						specimen_part.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#attributes.collection_object_id#">
				</cfquery>
				<cfset target = "#getTarget.guid# #getTarget.part_name# (#getTarget.preserve_method#)">
				<!--- count identifications on this part, used to check if page should reload after addition --->
				<cfquery name="countPartIdentifications" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" >
					SELECT count(*) as id_count
					FROM identification
					WHERE 
						collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#attributes.collection_object_id#">
				</cfquery>
				<cfif countPartIdentifications.id_count EQ 0>
					<cfset makesMixedCollectionOnSave = true>
				</cfif>
			<cfelse>
				<cfthrow message="This collection object type (#getDetermined.coll_object_type#) is not supported.">
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
									<cfif attributes.in_page>
										<script>
											function closeIdentificationInPage() { 
												// Close the in-page modal editor, and invoke the reloadIdentifications function
												closeInPage(reloadIdentifications);
											}
										</script>
										<!--- if in_page, provide button to return to specimen details page --->
										<button id="backToSpecimen1" class="btn btn-xs btn-secondary my-3 float-right" onclick="closeIdentificationInPage();">Back to Specimen</button>
									</cfif>
									<!--- identifiable, thus allow add identifications --->
									<div class="add-form float-left">
										<div class="add-form-header pt-1 pb-2 px-2 col-12 float-left">
											<h2 class="h3 my-0 px-1 pb-1 float-left">Add Identification#target#</h2>
									
										</div>
										<div class="card-body">
											<form name="addIdentificationForm" class="my-2" id="addIdentificationForm">
												<input type="hidden" name="collection_object_id" value="#attributes.collection_object_id#">
												<input type="hidden" name="method" value="addIdentification">
												<input type="hidden" name="returnformat" value="json">
												<div class="form-row pt-2">
													<div class="col-12 col-md-2 pb-1">
														<label for="taxa_formula" class="data-entry-label">ID Formula:</label>
														<select name="taxa_formula" id="taxa_formula" class="data-entry-input reqdClr" onchange="updateTaxonBVisibility();" required>
															<cfloop query="ctFormula">
																<option value="#ctFormula.taxa_formula#">#ctFormula.taxa_formula#</option>
															</cfloop>
														</select>
													</div>
													<div class="col-12 col-md-5 pb-1">
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
													<div class="col-12 col-md-3 pb-1">
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
													<div class="col-12 col-md-3 pb-1">
														<label for="nature_of_id" class="data-entry-label">Nature of ID:</label>
														<select name="nature_of_id" id="nature_of_id" class="data-entry-select reqdClr" required>
															<option></option>
															<cfloop query="ctNature">
																<option value="#ctNature.nature_of_id#">#ctNature.nature_of_id# #ctNature.description#</option>
															</cfloop>
														</select>
													</div>
													<div class="col-12 col-md-6 pb-1">
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
													<div class="col-12 col-md-10 pb-1">
														<label for="identification_remarks" class="data-entry-label">Remarks:</label>
														<input type="text" name="identification_remarks" id="identification_remarks" class="data-entry-input">
													</div>
													<div class="col-12 col-md-2 pb-1">
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
													<div class="col-12 pb-1">
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
															</div>
															<!---For change between monitors and phones the button should have its own div--->
															<div class="col-12 col-md-3">
																<!--- button to add another set of determiner controls --->
																<button type="button" class="btn btn-xs btn-secondary mt-md-3" id="addDeterminerButton"
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
																		// no option to change determiner order when creating new identifications
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
														<input type="button" value="Add" class="btn btn-xs btn-primary mt-3" id="addIdButton"
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
													loadIdentificationsList("#attributes.collection_object_id#", "identificationDialogList","true");
												}
												function handleAddIdentification() {
													// Validate required fields
													if (!$("##addIdentificationForm")[0].checkValidity()) {
														$("##addIdentificationForm")[0].reportValidity();
														return;
													}
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
															<cfif makesMixedCollectionOnSave>
																<!--- on subsequent call of reloadParts, trigger a heading reload as a mixed collection has been created --->
																triggerHeadingReload = true;
															</cfif>
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
								<cfif hasMissingCitations>
									<div id="missingCitationList" class="col-12 float-left my-4 px-0 border border-rounded">
										<h3 class="h3">
											There are citations for taxa that do not have corresponding identifications.
										</h3>
										<cfif isDefined("getMissingCitations") >
											<p class="mb-1">Please consider adding identifications for the following taxa:</p>
											<ul>
												<cfloop query="getMissingCitations">
													<li>
														#getMissingCitations.scientific_name#
														#getMissingCitations.type_status#
														<a href="/publications/showPublication.cfm?publication_id=#getMissingCitations.publication_id#" target="_blank">#getMissingCitations.formatted_publication#</a>
													</li>
												</cfloop>
											</ul>
										</cfif>
									</div>
								</cfif>
								<div id="identificationDialogList" class="col-12 float-left my-3 px-0">
									<cfset idList = getIdentificationsUnthreadedHTML(collection_object_id = attributes.collection_object_id, editable=true)>
								</div>
								<cfif attributes.in_page>
									<!--- if in_page, provide button to return to specimen details page --->
									<div class="col-12 px-0 mt-0">
										<button id="backToSpecimen2" class="btn btn-xs btn-secondary mb-3 float-right" onclick="closeIdentificationInPage();">Back to Specimen</button>
									</div>
								</cfif>
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
	@return a json structure with status=added, or an http 500 response.
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

	<cftransaction>
		<cftry>

			<!--- setup variables for either 1 (A) or 2 (A and B) taxa from formula in identification --->
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
			<!--- lookup the taxon A name in the taxon name table to not include the authorship --->
			<cfif variables.taxona_id EQ "">
				<cfthrow message="Taxon A taxon_name_id is required, you must select a taxon from the autocomplete list.">
			</cfif>
			<cfquery name="getTaxonA" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT scientific_name
				FROM taxonomy
				WHERE taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.taxona_id#">
			</cfquery>
			<cfset scientific_name = replace(scientific_name, "TAXON_A", getTaxonA.scientific_name)>
			<cfif len(variables.taxonb)>
				<!--- replace the placeholder for B with the taxon B name if provided --->
				<!--- lookup the taxon B name in the taxon name table to not include the authorship --->
				<cfquery name="getTaxonB" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT scientific_name
					FROM taxonomy
					WHERE taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.taxonb_id#">
				</cfquery>
				<cfset scientific_name = replace(scientific_name, "TAXON_B", getTaxonB.scientific_name)>
			</cfif>
			<!--- Clean up any double spaces or trailing punctuation --->
			<cfset scientific_name = Trim(REReplace(scientific_name, "[ ]{2,}", " ", "all"))>

			<!--- Check if the collection_object_id exists and is of a type that takes identifications --->
			<cfquery name="getType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" >
				SELECT coll_object_type
				FROM coll_object
				WHERE 
					collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">
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
				<cfquery name="unsetStoredFG" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
  @return a json structure with status=removed, or an http 500 response.
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
											<input type="hidden" name="accepted_id_fg" id="eid_edit_accepted_id_fg" value="#idData.accepted_id_fg#">
											<input type="hidden" name="stored_as_fg" id="eid_edit_stored_as_fg" value="#idData.stored_as_fg#">
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
														$(document).ready(function() {
															makeScientificNameAutocompleteMeta("eid_edit_taxona","eid_edit_taxona_id");
														});
													</script>
												</div>
												<div class="col-12 col-md-5">
													<div class="form-row" id="eid_edit_taxonb_row" <cfif NOT idData.taxa_formula CONTAINS "B">style="display:none;"</cfif>>
														<label for="taxonb" class="data-entry-label">Taxon B:</label>
														<input type="text" name="taxonb" id="eid_edit_taxonb" class="data-entry-input" value="#taxonB.scientific_name#">
														<input type="hidden" name="taxonb_id" id="eid_edit_taxonb_id" value="#taxonB.taxon_name_id#">
														<script>
															$(document).ready(function() {
																makeScientificNameAutocompleteMeta("eid_edit_taxonb","eid_edit_taxonb_id");
															});
														</script>
													</div>
												</div>
												<div class="col-12 col-md-3">
													<label for="made_date" class="data-entry-label">Date Identified:</label>
													<input type="text" name="made_date" id="eid_edit_made_date" class="data-entry-input" value="#idData.made_date#">
													<script>
														$(document).ready(function() {
															$("##eid_edit_made_date").datepicker({
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
													<label for="publication" class="data-entry-label">Sensu:</label>
													<input type="text" name="sensu" id="eid_edit_publication" class="data-entry-input" value="#idData.short_citation#">
													<input type="hidden" name="publication_id" id="eid_edit_publication_id" value="#idData.publication_id#">
													<script>
														$(document).ready(function() {
															makePublicationAutocompleteMeta("eid_edit_publication","eid_edit_publication_id");
														});
													</script>
												</div>
												<div class="col-12 col-md-10">
													<label for="identification_remarks" class="data-entry-label">Remarks:</label>
													<input type="text" name="identification_remarks" id="eid_edit_identification_remarks" class="data-entry-input" value="#idData.identification_remarks#">
												</div>
												<div class="col-12 col-md-2">
													<!--- Unified identification state (current, and stored as flags) select --->
													<!--- Determine id_state based on accepted_id_fg and stored_as_fg --->
													<cfset id_state = "previous">
													<cfif idData.accepted_id_fg EQ 1>
														<cfset id_state = "current">
													<cfelseif idData.stored_as_fg EQ 1>
														<cfset id_state = "stored_as">
													</cfif>
													<label for="id_state" class="data-entry-label">Id is:</label>
													<select name="id_state" id="eid_edit_id_state" class="data-entry-select reqdClr" required>
														<option value="current" <cfif id_state EQ "current">selected</cfif>>Current</option>
														<option value="previous" <cfif id_state EQ "previous">selected</cfif>>Previous</option>
														<option value="stored_as" <cfif id_state EQ "stored_as">selected</cfif>>Previous: Stored As</option>
													</select>
													<script>
														$(document).ready(function() {
															$("##eid_edit_id_state").change(function() {
																var state = $(this).val();
																if (state === "current") {
																	$("##eid_edit_accepted_id_fg").val("1");
																	$("##eid_edit_stored_as_fg").val("0");
																} else if (state === "previous") {
																	$("##eid_edit_accepted_id_fg").val("0");
																	$("##eid_edit_stored_as_fg").val("0");
																} else if (state === "stored_as") {
																	$("##eid_edit_accepted_id_fg").val("0");
																	$("##eid_edit_stored_as_fg").val("1");
																}
															});
														});
													</script>
												</div>
								
												<!--- Determiners --->
												<div class="col-12">
													<div class="form-row" id="eid_edit_determiners_form_row">
														<cfset determiner_count = 0>
														<cfloop query="determiners">
															<cfset determiner_count = determiner_count + 1>
															<div class="col-12 col-md-3 form-row" id="eid_det_div_#determiner_count#">
																<div class="col-12 col-md-10 pr-0">
																	<label id="eid_det_label_#determiner_count#" for="eid_det_name_#determiner_count#" class="data-entry-label">Determiner #determiner_count#:</label>
																	<input type="text" name="eid_det_name_#determiner_count#" id="eid_det_name_#determiner_count#" class="data-entry-input reqdClr" value="#determiners.agent_name#" required>
																	<input type="hidden" name="eid_determiner_id_#determiner_count#" id="eid_determiner_id_#determiner_count#" value="#determiners.agent_id#">
																	<input type="hidden" name="eid_identification_agent_id_#determiner_count#" value="#determiners.identification_agent_id#">
																</div>
																<div class="col-12 col-md-2 pl-0">
																	<!--- select to change position --->
																	<label for="eid_det_position_#determiner_count#" class="data-entry-label" aria-label="Ordinal Position">&nbsp;</label>
																	<select name="det_position_#determiner_count#" id="eid_det_position_#determiner_count#" class="data-entry-select">
																		<cfloop from="1" to="#determiners.recordcount#" index="pos">
																			<cfif pos EQ determiner_count>
																				<cfset selected="selected">
																			<cfelse>
																				<cfset selected="">
																			</cfif>
																			<option value="#pos#" #selected#>#pos#</option>
																		</cfloop>
																	</select>
																</div>
																<button type="button" class="btn btn-xs btn-secondary ml-1" id="eid_removeDet#determiner_count#" onClick="removeEditDeterminerControl(#determiner_count#);">Remove</button>
																<script>
																	$(document).ready(function() {
																		makeAgentAutocompleteMeta("eid_det_name_#determiner_count#", "eid_determiner_id_#determiner_count#");
																	});
																</script>
															</div>
														</cfloop>
														<!--- Failover case: if no determiners are present, ensure at least one set of controls is shown --->
														<cfif determiner_count EQ 0>
															<cfset determiner_count = 1>
															<div class="col-12 col-md-3 form-row" id="eid_det_div_1">
																<div class="col-12 col-md-10 pr-0">
																	<label id="eid_det_label_1" for="eid_det_name_1" class="data-entry-label">Determiner 1:</label>
																	<input type="text" name="eid_det_name_1" id="eid_det_name_1" class="data-entry-input reqdClr" required>
																	<input type="hidden" name="eid_determiner_id_1" id="eid_determiner_id_1">
																	<input type="hidden" name="eid_identification_agent_id_1" value="new">
																	<input type="hidden" name="det_position_1" id="eid_det_position_1" value="1">
																</div>
																<div class="col-12 col-md-2 pl-0">
																	&nbsp;<!--- no position select for failover case --->
																</div>
																<button type="button" class="btn btn-xs btn-secondary ml-1" id="eid_removeDet1" onClick="removeEditDeterminerControl(1);">Remove</button>
																<script>
																	$(document).ready(function() {
																		makeAgentAutocompleteMeta("eid_det_name_1", "eid_determiner_id_1");
																	});
																</script>
															</div>
														</cfif>
														<input type="hidden" name="determiner_count" id="eid_determiner_count" value="#determiner_count#">
														<!--- List of agent ids of determiners that were selected --->
														<input type="hidden" name="determiner_ids" id="eid_determiner_ids" class="data-entry-input">
														<!--- List of primary key values for existing identification_agent records --->
														<input type="hidden" name="identification_agent_ids" id="eid_identification_agent_ids" class="data-entry-input">
														<!--- List of positions for each determiner (1 to n) --->
														<input type="hidden" name="determiner_positions" id="eid_determiner_positions" class="data-entry-input">
													</div>
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
								
											// Determiner controls logic, matching Add form
											function addEditDeterminerControl() {
												var currentCount = parseInt($("##eid_determiner_count").val());
												currentCount++;
												var newControl = '<div class="col-12 col-md-3 form-row" id="eid_det_div_' + currentCount + '">';
												newControl += '<div class="col-12 col-md-10 pr-0">';
												newControl += '<label id="eid_det_label_' + currentCount + '" for="eid_det_name_' + currentCount + '" class="data-entry-label">Determiner ' + currentCount + ':</label>';
												newControl += '<input type="text" name="eid_det_name_' + currentCount + '" id="eid_det_name_' + currentCount + '" class="data-entry-input reqdClr" required>';
												newControl += '<input type="hidden" name="eid_determiner_id_' + currentCount + '" id="eid_determiner_id_' + currentCount + '">';
												newControl += '<input type="hidden" name="eid_identification_agent_id_' + currentCount + '" value="new">';
												newControl += '</div>';
												newControl += '<div class="col-12 col-md-2 pl-0">';
												// select to change position 
												newControl += '<label for="eid_det_position_' + currentCount + '" class="data-entry-label" aria-label="Ordinal Position">&nbsp;</label>';
												newControl += '<select name="det_position_' + currentCount + '" id="eid_det_position_' + currentCount + '" class="data-entry-select">';
												for (var i = 1; i <= currentCount; i++) {
													if (i === currentCount) {
														newControl += '<option value="' + i + '" selected>' + i + '</option>';
													} else {
														// For previous positions, we can only select up to currentCount - 1
														newControl += '<option value="' + i + '">' + i + '</option>';
													}
												}
												newControl += '</select>';
												newControl += '</div>';
												newControl += '<button type="button" class="btn btn-xs btn-secondary ml-1" id="eid_removeDet' + currentCount + '" onClick="removeEditDeterminerControl(' + currentCount + ');">Remove</button>';
												newControl += '</div>';
												$("##eid_edit_determiners_form_row").append(newControl);
												makeAgentAutocompleteMeta("eid_det_name_" + currentCount, "eid_determiner_id_" + currentCount);
												$("##eid_determiner_count").val(currentCount);
											}
											function removeEditDeterminerControl(index) {
												$("##eid_det_div_" + index).remove();
												// Optionally decrement the count, but keep unique indexes
											}
								
											function closeEditDialog() {
												$("##editIdentificationDialog").dialog("close");
												reloadIdentifications();
											}
								
											function handleSaveIdentification() {
												// Validate required fields
												if (!$("##editIdentificationForm")[0].checkValidity()) {
													$("##editIdentificationForm")[0].reportValidity();
													return;
												}
												setFeedbackControlState("editIdStatus", "saving");
												// Expected number of determiner field sets 
												var count = parseInt($("##eid_determiner_count").val());
												// Collect all identification_agent_ids for determiner records
												var identificationAgentIds = [];
												for (var i=1; i<=count; i++) {
													var $div = $("##eid_det_div_" + i);
													if ($div.length > 0) {
														var idAgentId = $div.find("[name='eid_identification_agent_id_" + i + "']").val();
														if (idAgentId) {
															identificationAgentIds.push(idAgentId);
														}
													}
												}
												$("##eid_identification_agent_ids").val(identificationAgentIds.join(','));
												// Collect all determiner agent_ids
												var determinerIds = [];
												for (var i = 1; i <= count; i++) {
													var $div = $("##eid_det_div_" + i);
													if ($div.length > 0) {
														var agentId = $div.find("[id^='eid_determiner_id_']").val();
														if (agentId) {
															determinerIds.push(agentId);
														}
													}
												}
												$("##eid_determiner_ids").val(determinerIds.join(','));
												// Collect all determiner positions
												var determinerPositions = [];
												for (var i = 1; i <= count; i++) {
													var $div = $("##eid_det_div_" + i);
													if ($div.length > 0) {
														var position = $div.find("[id^='eid_det_position_']").val();
														if (position) {
															determinerPositions.push(position);
														}
													}
												}
												$("##eid_determiner_positions").val(determinerPositions.join(','));
												var form = $('##editIdentificationForm');
												var formData = form.serialize();
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
								
											// Init on load
											document.addEventListener('DOMContentLoaded', function() {
												updateEditTaxonBVisibility();
											});
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
	@param identification_agent_ids a comma-separated list of identification agent IDs for the associative entity.
	@param determiner_ids a comma-separated list of agent IDs for the determiners.
	@param determiner_positions a comma-separated list of positions for the determiners.
	@return JSON object with status and identification ID.
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
	<cfargument name="identification_agent_ids" type="string" required="yes"><!--- the list of identification_agent_ids for the associative entity --->
	<cfargument name="determiner_ids" type="string" required="yes"> <!--- the list of agent_ids for determiners --->
	<cfargument name="determiner_positions" type="string" required="yes"> <!--- the list of positions for determiners --->	

	<cfset var data = ArrayNew(1)>
	
	<cfset var scientific_name = arguments.taxa_formula>
	
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
			<!--- throw an exception if formula contains B but taxon B is not provided --->
			<cfif arguments.taxa_formula contains "B" and len(arguments.taxonb) EQ 0>	
				<cfthrow message="Taxon B is required when the formula contains 'B'.">
			</cfif>
			<!--- check that the lists of determiner information are the same length --->
			<cfif listLen(arguments.identification_agent_ids) NEQ listLen(arguments.determiner_ids)>
				<cfthrow message="The number of identification_agent_ids must match the number of determiner_ids.">
			</cfif>
			<cfif listLen(arguments.identification_agent_ids) NEQ listLen(arguments.determiner_positions)>
				<cfthrow message="The number of identification_agent_ids must match the number of determiner_positions.">
			</cfif>
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
			
			<cfset variables.existingIds = ValueList(existingDeterminers.identification_agent_id)>
			<cfset variables.processedIds = "">

			<!--- ensure determiner_positions are not duplicated and represent a user selected order with duplicated moved down the list --->
			<cfset posArray = listToArray(determiner_positions)>
			<cfset n = arrayLen(posArray)>
			<cfset newPositions = arrayNew(1)>
			<!--- Create a copy of the determiner position array --->
			<cfset tempArray = arrayNew(1)>
			<cfloop from="1" to="#n#" index="i">
				<cfset tempArray[i] = posArray[i]>
			</cfloop>
			<!--- Work backwards, so the last occurrence of a given number is kept (supporting a user moving determiner 3 to position 1, but not changing other positions) --->
			<cfloop index="i" from="#n#" to="1" step="-1">
				<cfset currVal = tempArray[i]>
				<!--- Make sure currVal is unique for indices > i --->
				<cfset start= i + 1>
				<cfloop index="j" from="#start#" to="#n#">
					<cfif tempArray[j] EQ currVal>
						<cfset currVal = currVal + 1>
						<!--- Restart inner loop if we change currVal --->
						<cfset j = i>
					</cfif>
				</cfloop>
				<cfset newPositions[i] = currVal>
			</cfloop>
			<!--- Now, ensure all values are in 1..N and unique --->
			<cfset seen = structNew()>
			<cfloop index="i" from="1" to="#n#">
				<!--- If out of range or already seen, increment up to find available slot --->
				<cfset val = newPositions[i]>
				<cfloop condition="val LT 1 OR val GT n OR structKeyExists(seen, val)">
					<cfset val = val + 1>
					<cfif val GT n>
						<cfset val = 1>
					</cfif>
				</cfloop>
				<cfset newPositions[i] = val>
				<cfset seen[val] = true>
			</cfloop>
			<cfset determiner_positions = arrayToList(newPositions)>
			
			<!--- combine determiner_ids, determiner_positions, and identification_agent_ids lists into a two dimensional array for processing --->
			<cfset variables.determinersArray = ArrayNew(1)>
			<cfset var agentId = 0>
			<cfset var orderNum = 0>
			<cfset var processedIds = "">
			<cfloop list="#arguments.identification_agent_ids#" index="id">
												<cfset variables.detStruct = StructNew()>
				<cfset detStruct["identification_agent_id"] = id>
				<cfset detStruct["agent_id"] = ListGetAt(arguments.determiner_ids, ListFindNoCase(arguments.identification_agent_ids, id))>
				<cfset var ordinalPosition = ListGetAt(arguments.determiner_positions, ListFindNoCase(arguments.identification_agent_ids, id))>
				<cfif len(ordinalPosition)>
					<cfset orderNum = Val(ordinalPosition)>
				</cfif>
				<cfset detStruct["identifier_order"] = orderNum>
				<cfset ArrayAppend(variables.determinersArray, detStruct)>
				<cfset orderNum = orderNum + 1>
			</cfloop>

			<!--- Process each determiner from the form --->
			<cfloop array="#variables.determinersArray#" index="det">
				<cfset var detId = det.identification_agent_id>
				<cfset var agentId = det.agent_id>
				<cfset var orderNum = det.identifier_order>
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
						WHERE
							identification_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#existingId#">
							AND identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.identification_id#">
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

<!--- Bulk update identifications for a collection object (edit/save all fields, triggers, flags, etc.) 
  @param collection_object_id the collection_object_id for the specimen.
  @param identificationUpdates an array of structs, each struct containing all fields for an identification to update, including accepted_id_fg, stored_as_fg, sort_order, etc.
  @return JSON object with status for each identification updated or a http 500 error on failure.
--->
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
						concatEncumbranceDetails(cataloged_item.collection_object_id) encumbranceDetail,
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
					<cfquery name="getRestrictions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT distinct
							case when length(permit.restriction_summary) > 30 then substr(permit.restriction_summary,1,30) || '...' else permit.restriction_summary end as restriction_summary,
							permit.specific_type,
							permit.permit_num,
							permit.permit_title,
							permit.permit_id
						FROM 
							cataloged_item
							join accn on cataloged_item.accn_id = accn.transaction_id
							join permit_trans on accn.transaction_id = permit_trans.transaction_id
							join permit on permit_trans.permit_id = permit.permit_id
						WHERE 
							cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
							and permit.restriction_summary is not null
					</cfquery>
					<cfif getRestrictions.recordcount GT 0>
						<cfset local.restrictions = "Permits with restrictions on use:<ul>"><!--- " --->
						<cfloop query="getRestrictions">
							<cfset local.restrictions = "#local.restrictions#<li><strong><a href='/transactions/Permit.cfm?action=view&permit_id=#getRestrictions.permit_id#' target='_blank'>#getRestrictions.specific_type# #getRestrictions.permit_num#</a></strong> #getRestrictions.restriction_summary#</li>"><!--- " --->
						</cfloop>
						<cfset local.restrictions = "#local.restrictions#</ul>"><!--- " --->
					</cfif>
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
									<cfif isDefined("local.restrictions") and len(local.restrictions) GT 0>
										<li>#local.restrictions#</li>
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
									<cfif len(getCatalog.encumbranceDetail) GT 0>
										<li>Encumbrances: #getCatalog.encumbranceDetail#</li>
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
									<cfset variables.coll_object_type="#variables.coll_object_type#: Mixed Collection">
								</cfif>
								<cfset guidLink = "https://mczbase.mcz.harvard.edu/guid/#getCatalog.institution_acronym#:#getCatalog.collection_cde#:#getCatalog.cat_num#">
								#variables.coll_object_type# #getCatalog.cataloged_item_type_description# 
								( occurrenceID: #guidLink# <a href="#guidLink#/json"> <img src='/shared/images/json-ld-data-24.png' alt='JSON-LD'> </a>)
								<cfquery name="getComponents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									SELECT count(specimen_part.collection_object_id) ct, coll_object_type, part_name, count(identification.collection_object_id) identifications
									FROM 
										specimen_part 
										join coll_object on coll_object.collection_object_id=specimen_part.collection_object_id
										left join identification on coll_object.collection_object_id=identification.collection_object_id
									WHERE derived_from_cat_item = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getCatalog.collection_object_id#">
									GROUP BY coll_object_type, part_name
									ORDER BY count(identification.collection_object_id) asc, part_name asc
								</cfquery>
								<ul>
								<cfloop query="getComponents">
									<cfset variables.occurrences="">
									<cfset variables.subtype="">
									<cfif getComponents.identifications gt 0>
										<cfset variables.subtype=": <strong>Different Organism</strong>"><!--- " --->
										<!--- Show occurrence ID value(s) for the identifiable object(s) --->
										<cfquery name="getComponentOccurrenceID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
											SELECT assembled_identifier, assembled_resolvable, identification.scientific_name sc_name
											FROM 
												specimen_part 
												join guid_our_thing on specimen_part.collection_object_id=guid_our_thing.co_collection_object_id
												join identification on specimen_part.collection_object_id=identification.collection_object_id
											WHERE specimen_part.derived_from_cat_item = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getCatalog.collection_object_id#">
												and identification.accepted_id_fg=1
										</cfquery>
										<cfloop query="getComponentOccurrenceID">
											<cfset variables.occurrences="(occurrenceID: #getComponentOccurrenceID.assembled_identifier# <a href='#getComponentOccurrenceID.assembled_resolvable#/json'> <img src='/shared/images/json-ld-data-24.png' alt='JSON-LD'> </a> #getComponentOccurrenceID.sc_name# )">
										</cfloop>
									</cfif>
									<cfif getComponents.coll_object_type is "SP">
										<cfset variables.coll_object_type="Specimen Part#variables.subtype#">
									<cfelseif getComponents.coll_object_type is "SS">
										<cfset variables.coll_object_type="Subsample#variables.subtype#">
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
							<div class="card add-form mt-3">
								<div class="add-form-header px-3">
									<h2 class="h3">Add other identifier for #getCatalog.institution_acronym#:#getCatalog.collection_cde#:#getCatalog.cat_num#</h2>
								</div>
								<div class="card-body mt-2 py-0">
									<form name="addOtherIDForm" id="addOtherIDForm" class="form-row mx-0 px-2 mb-0 pt-1">
										<div class="col-12 col-md-4 px-0 mt-2 py-0">
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
										<div class="col-12 col-md-4 px-0 px-xl-2 py-0 mt-2">
											<label class="data-entry-label" id="display_value">Other ID Number</label>
											<input type="text" class="reqdClr data-entry-input" name="display_value" required>
										</div>
										<div class="col-12 col-md-4 px-0 py-0 mt-2">
											<input type="button" value="Create Identifier" class="btn btn-xs btn-primary mt-3" onClick="if (checkFormValidity($('##addOtherIDForm')[0])) { addOtherIDSubmit();  } ">
											<output id="addOtherIDResultDiv" class="d-block text-danger">&nbsp;</output>
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
														reloadOtherIDs();
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
							<div class="col-12 my-0 px-0 pt-1 pb-0">
								<h2 class="h3 mt-3 px-2 mb-0">Edit Existing Identifiers</h1>
								<cfset i=1>
								<cfloop query="getIDs">
									<form name="getIDs#i#" id="editOtherIDForm#i#" class="mb-0">
										<input type="hidden" name="method" value="updateOtherID" id="getIDsMethod#i#">
										<input type="hidden" name="returnformat" value="json">
										<input type="hidden" name="queryformat" value="column">
										<input type="hidden" name="collection_object_id" value="#collection_object_id#">
										<input type="hidden" name="coll_obj_other_id_num_id" value="#coll_obj_other_id_num_id#">
										<input type="hidden" name="number_of_ids" id="number_of_ids" value="#getIDs.recordcount#">
									

										<div class="border bg-light rounded mx-0 px-2 mt-2 form-row" id="otherIDEditControls#i#">
											<div class="col-12 border-bottom py-2 my-1 form-row">

												<div class="col-12 col-xl-4">
													Identifier: #getIDs.other_id_type#:
													<strong> 
														<cfif getIds.base_url NEQ "">
															<a href="#getIDs.base_url##getIDs.display_value#" target="_blank">#getIDs.display_value#</a>
														<cfelse>
															#getIDs.display_value#
														</cfif>
													</strong>
												</div>
												<div class="col-12 col-md-8">
													<cfif getIds.description NEQ "">Description:</cfif> #getIDs.description#
												</div>
											</div>
											<div class="form-group mt-2 col-12 col-md-4 px-1">
												<cfset thisType = #getIDs.other_id_type#>
												<label class="data-entry-label" for="other_id_type#i#" >Type</label>
												<select name="other_id_type" class="data-entry-select" style="" size="1" id="other_id_type#i#">
													<cfloop query="ctType">
														<cfif #thisType# is #ctType.other_id_type#><cfset selected="selected"><cfelse><cfset selected=""></cfif>
														<option #selected# value="#ctType.other_id_type#">#ctType.other_id_type#</option>
													</cfloop>
												</select>
											</div>
											<div class="form-group mt-2 col-12 col-md-4 px-1">
												<label class="data-entry-label" for="display_value#i#" >Number</label>
												<input type="text" class="data-entry-input" value="#encodeForHTML(getIDs.display_value)#" size="12" name="display_value" id="display_value#i#">
											</div>
											<div class="form-group mt-2 col-12 col-md-4 px-1">
												<input type="button" value="Save" aria-label="Save Changes" class="mt-3 btn btn-xs btn-primary"
													onClick="if (checkFormValidity($('##editOtherIDForm#i#')[0])) { editOtherIDsSubmit(#i#);  } ">
												<input type="button" value="Delete" class="btn btn-xs mt-3 px-1 btn-danger" onclick="doDelete(#i#);">
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
													$("##otherIDEditControls"+num).remove();
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
													reloadOtherIDs();
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
							<!--- End of List/Edit existing --->
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
	<cfargument name="display_value" type="string" required="yes">

	<cftry>
		<cfset data=queryNew("status, message, id")>
		<cfstoredproc procedure="parse_other_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			<cfprocparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">
			<cfprocparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.display_value#">
			<cfprocparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.other_id_type#">
		</cfstoredproc>
		<cftransaction action="commit">
		<cfset t = queryaddrow(data,1)>
		<cfset t = QuerySetCell(data, "status", "1", 1)>
		<cfset t = QuerySetCell(data, "message", "Record added.", 1)>
		<cfset t = QuerySetCell(data, "id", "#arguments.collection_object_id#", 1)>
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
	<cfargument name="display_value" type="string" required="yes">

	<cftry>
		<cfset data=queryNew("status, message, id")>
		<cfstoredproc procedure="update_other_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			<cfprocparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">
			<cfprocparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.COLL_OBJ_OTHER_ID_NUM_ID#">
			<cfprocparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.display_value#">
			<cfprocparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.other_id_type#">
		</cfstoredproc>	
		<cftransaction action="commit">
		<cfset t = queryaddrow(data,1)>
		<cfset t = QuerySetCell(data, "status", "1", 1)>
		<cfset t = QuerySetCell(data, "message", "Record updated.", 1)>
		<cfset t = QuerySetCell(data, "id", "#arguments.collection_object_id#", 1)>
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
		<cfquery name="deleteOtherID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="deleteOtherID_result">
			DELETE FROM coll_obj_other_id_num 
			WHERE coll_obj_other_id_num_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.coll_obj_other_id_num_id#">
			AND collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">
		</cfquery>
		<cfif deleteOtherID_result.recordcount EQ 0>
			<cfthrow message = "Error: delete failed, record not found.">
		<cfelseif deleteOtherID_result.recordcount GT 1>
			<cfthrow message = "Error: delete failed, multiple records would be deleted.">
		</cfif>
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
											<cfquery name="fromCollEvent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												SELECT verbatim_collectors
												FROM collecting_event
													join cataloged_item on collecting_event.collecting_event_id = cataloged_item.collecting_event_id
												WHERE
													cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">
													AND collecting_event.verbatim_collectors IS NOT NULL
											</cfquery>
											<cfif fromCollEvent.recordcount GT 0>
												<h3 class="h5 mt-3">Verbatim Collectors from collecting event</h3>
												<cfloop query="fromCollEvent">
													<p class="mb-0">#fromCollEvent.verbatim_collectors#</p>
												</cfloop>
											</cfif>
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


<!--- getEditPartsHTML returns the HTML for the edit parts dialog.
 @param collection_object_id the collection_object_id for the cataloged item to edit parts for.
 @return HTML for the edit parts dialog, including a form to add new parts and a table of existing parts.
--->
<cffunction name="getEditPartsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="dialog" type="boolean" required="no" default="true">

	<!--- TODO: Cases to handle: 
	  One Cataloged Item, one occurrence, one or more parts, each a material sample, each part in one container.
	  One Cataloged Item, a set of parts may be a separate occurrence with a separate identification history, each part a material sample, each part in one container, need occurrence ids for additional parts after the first, need rows in at least digir_filtered_flat for additional occurrences.
	  More than one cataloged item, each a separate occurrence, with a set of parts, each part a material sample, parts may be in the same collection object container (thus loanable only as a unit).
   --->
	<cfthread name="getEditPartsThread" collection_object_id="#arguments.collection_object_id#" dialog="#arguments.dialog#">
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
						cataloged_item.collection_object_id = <cfqueryparam value="#attributes.collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
				</cfquery>
				<cfset guid = "#getCatItem.institution_acronym#:#getCatItem.collection_cde#:#getCatItem.cat_num#">
				<!--- check for mixed collection --->
				<cfquery name="checkMixed" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT count(identification_id) ct
					FROM coll_object
						join specimen_part on specimen_part.derived_from_cat_item = coll_object.collection_object_id
						join identification on specimen_part.collection_object_id = identification.collection_object_id
					WHERE coll_object.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getCatItem.collection_object_id#">
				</cfquery>
				<cfif checkMixed.ct gt 0>
					<cfset var mixedCollection = true>
					<cfset guid = "#guid# (mixed collection)">
				<cfelse>
					<cfset var mixedCollection = false>
				</cfif>

				<cfquery name="ctDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT coll_obj_disposition 
					FROM ctcoll_obj_disp 
					ORDER BY coll_obj_disposition
				</cfquery>
				
				<cfquery name="ctModifiers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT modifier 
					FROM ctnumeric_modifiers 
					ORDER BY modifier DESC
				</cfquery>
				
				<cfquery name="ctPreserveMethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT preserve_method
					FROM ctspecimen_preserv_method
					WHERE collection_cde = <cfqueryparam value="#getCatItem.collection_cde#" cfsqltype="CF_SQL_VARCHAR">
					ORDER BY preserve_method
				</cfquery>

				<!--- add new part --->
				<div class="container-fluid">
					<div class="row">
						<div class="col-12">
							<cfif NOT dialog>
									<!---<h2 class="h2">Parts for #guid#</h2> // seems redundant since it is on the page with the catalog number at the top--->
									<button class="btn btn-xs btn-secondary my-3 float-right" onclick="closePartsInPage();">
										Back to Specimen</button>
							</cfif>
							<div class="add-form float-left">								
								<div class="add-form-header pt-1 pb-2 px-2" id="headingPart">
									<h2 class="h3 my-0 px-1 pb-1">Add New Part for #guid#</h2>
								</div>
								<div class="card-body">
									<form name="newPart" id="newPart" class="mb-0">
										<input type="hidden" name="derived_from_cat_item" value="#getCatItem.collection_object_id#">
										<input type="hidden" name="method" value="createSpecimenPart">
										<input type="hidden" name="is_subsample" value="false"><!--- TODO: Add subsample support --->
										<input type="hidden" name="subsampled_from_obj_id" value="">
										<div class="row mx-0 pb-2 col-12 px-0 mt-2 mb-1">
											<div class="float-left col-12 col-md-4 mb-2 px-1">
												<label for="part_name" class="data-entry-label">
													<span>Part Name</span>
													<span>[<a href="/vocabularies/ControlledVocabulary.cfm?table=CTSPECIMEN_PART_NAME&collection_cde=#getCatItem.collection_cde#" title="List of part names specific to the #getCatItem.collection_cde# collection." target="_blank">Define Values</a>]</span>
												</label>
												<input name="part_name" class="data-entry-input reqdClr" id="part_name" type="text" required>
											</div>
											<div class="float-left col-12 col-md-4 mb-2 px-1">
												<label for="preserve_method" class="data-entry-label">
													<span>Preserve Method</span>
													<span>[<a href="/vocabularies/ControlledVocabulary.cfm?table=CTSPECIMEN_PRESERV_METHOD&collection_cde=#getCatItem.collection_cde#" title="List of preserve methods specific to the #getCatItem.collection_cde# collection." target="_blank">Define Values</a>]</span>
												</label>
												<select name="preserve_method" id="preserve_method" class="data-entry-select reqdClr" required>
													<option value=""></option>
													<cfloop query="ctPreserveMethod">
														<option value="#preserve_method#">#preserve_method#</option>
													</cfloop>
												</select>
											</div>
											<div class="float-left col-12 col-md-2 mb-2 px-1">
												<label for="lot_count_modifier" class="data-entry-label">Count Modifier</label>
												<select name="lot_count_modifier" id="lot_count_modifier" class="data-entry-select">
													<option value=""></option>
													<cfloop query="ctModifiers">
														<option value="#modifier#">#modifier#</option>
													</cfloop>
												</select>
											</div>
											<div class="float-left col-12 col-md-2 mb-2 px-1">
												<label for="lot_count" class="data-entry-label">Count</label>
												<input name="lot_count" id="lot_count" class="data-entry-input reqdClr" type="text" required>
											</div>
											<div class="float-left col-12 col-md-4 mb-2 px-1">
												<label for="coll_obj_disposition" class="data-entry-label">Disposition</label>
												<select name="coll_obj_disposition" id="coll_obj_disposition" class="data-entry-select reqdClr" required>
													<option value=""></option>
													<cfloop query="ctDisp">
														<option value="#coll_obj_disposition#">#coll_obj_disposition#</option>
													</cfloop>
												</select>
											</div>
											<div class="float-left col-12 col-md-4 mb-2 px-1">
												<label for="condition" class="data-entry-label">Condition</label>
												<input name="condition" id="condition" class="data-entry-input reqdClr" type="text" required>
											</div>
											<div class="float-left col-12 col-md-4 mb-2 px-1">
												<label for="container_barcode" class="data-entry-label">Container</label>
												<input name="container_barcode" id="container_barcode" class="data-entry-input" type="text" placeholder="Scan or type barcode">
											</div>
											<div class="float-left col-12 col-md-10 px-1">
												<label for="coll_object_remarks" class="data-entry-label">Remarks (<span id="length_remarks"></span>)</label>
												<textarea id="coll_object_remarks" name="coll_object_remarks" 
													onkeyup="countCharsLeft('coll_object_remarks', 4000, 'length_remarks');"
													class="data-entry-textarea autogrow mb-1" maxlength="4000"></textarea>
											</div>
											<div class="col-12 col-md-2 px-1 mt-3">
												<button id="newPart_submit" value="Create" class="btn btn-xs btn-primary" title="Create Part">Create Part</button>
												<output id="newPart_output"></output>
											</div>
										</div>
									</form>
								</div>
							</div>
							<script>
							$(document).ready(function() {
								// make container barcode autocomplete, reference containers that can contain collection objects
								makeContainerAutocompleteMetaExcludeCO("container_barcode", "container_id");
								// make part name autocomplete, limiting to parts in the collection for the collection object
								makePartNameAutocompleteMetaForCollection("part_name", "#getCatItem.collection_cde#");
							});
							// Add event listener to the save button
							$('##newPart_submit').on('click', function(event) {
								event.preventDefault();
								// Validate the form
								if ($('##newPart')[0].checkValidity() === false) {
									// If the form is invalid, show validation messages
									$('##newPart')[0].reportValidity();
									return false; // Prevent form submission if validation fails
								}
								setFeedbackControlState("newPart_output","saving");
								$.ajax({
									url: '/specimens/component/functions.cfc',
									type: 'POST',
									responseType: 'json',
									data: $('##newPart').serialize(),
									success: function(response) {
										console.log(response);
										setFeedbackControlState("newPart_output","saved");
										reloadEditExistingParts();
									},
									error: function(xhr, status, error) {
										setFeedbackControlState("newPart_output","error");
										handleFail(xhr,status,error,"saving part.");
									}
								});
							});
							function reloadEditExistingParts() {
								// reload the edit existing parts section
								$.ajax({
									url: '/specimens/component/functions.cfc',
									type: 'POST',
									dataType: 'html',
									data: {
										method: 'getEditExistingPartsUnthreaded',
										collection_object_id: '#attributes.collection_object_id#'
									},
									success: function(response) {
										$('##editExistingPartsDiv').html(response);
									},
									error: function(xhr, status, error) {
										handleFail(xhr,status,error,"reloading edit existing parts.");
									}
								});
							}
						</script>
							<!--- edit existing parts --->
							<div id="editExistingPartsDiv" class="col-12 px-0 float-left">
								<!--- this div is replaced with the edit existing parts HTML when parts are added --->
								#getEditExistingPartsUnthreaded(collection_object_id=attributes.collection_object_id)#
							</div>
							<button class="btn btn-xs btn-secondary float-right my-3" onclick="closePartsInPage();">
								Back to Specimen</button>
						</div>
					</div>
				</div>
				<script>
					function closePartsInPage() {
						closeInPage(reloadParts);
					}
				</script>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<p class="mt-2 text-danger">Error: #cfcatch.type# #error_message#</p>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
					<cfdump var="#cfcatch#">
				</cfif>
			</cfcatch>
			</cftry>
		</cfoutput> 
	</cfthread>
	<cfthread action="join" name="getEditPartsThread" />
	<cfreturn getEditPartsThread.output>
</cffunction>

<!--- 
 getEditExistingPartsUnthreaded returns the HTML for the edit existing parts section, intended to be used
 from within threaded getEditPartsHTML or invoked independently to reload just the edit existing parts section 
 of the dialog.
 @param collection_object_id the collection object id to obtain existing parts for
 @return a string containing the HTML for the edit existing parts section
--->
<cffunction name="getEditExistingPartsUnthreaded" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">

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
					cataloged_item.collection_object_id = <cfqueryparam value="#arguments.collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
			</cfquery>
			<cfset guid = "#getCatItem.institution_acronym#:#getCatItem.collection_cde#:#getCatItem.cat_num#">
			
			<cfquery name="ctDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT coll_obj_disposition 
				FROM ctcoll_obj_disp 
				ORDER BY coll_obj_disposition
			</cfquery>
			
			<cfquery name="ctModifiers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT modifier 
				FROM ctnumeric_modifiers 
				ORDER BY modifier DESC
			</cfquery>
			<cfquery name="ctPreserveMethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT preserve_method
				FROM ctspecimen_preserv_method
				WHERE collection_cde = <cfqueryparam value="#getCatItem.collection_cde#" cfsqltype="CF_SQL_VARCHAR">
				ORDER BY preserve_method
			</cfquery>
			<cfquery name="rparts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT
					specimen_part.collection_object_id part_id,
    				CASE
    				    WHEN identification.collection_object_id IS NOT NULL THEN 1
       				 ELSE 0
    				END AS has_identification,
					pc.label label,
					pc.container_id container_id,
					nvl2(preserve_method, part_name || ' (' || preserve_method || ')',part_name) part_name,
					specimen_part.part_name as base_part_name,
					specimen_part.preserve_method,
					sampled_from_obj_id,
					coll_object.COLL_OBJ_DISPOSITION part_disposition,
					coll_object.CONDITION part_condition,
					coll_object.lot_count_modifier,
					coll_object.lot_count,
					nvl2(lot_count_modifier, lot_count_modifier || lot_count, lot_count) display_lot_count,
					coll_object_remarks part_remarks,
					attribute_type,
					attribute_value,
					attribute_units,
					determined_date,
					attribute_remark,
					agent_name
				FROM
					specimen_part
					LEFT JOIN specimen_part_attribute on specimen_part.collection_object_id=specimen_part_attribute.collection_object_id
					JOIN coll_object on specimen_part.collection_object_id=coll_object.collection_object_id
					LEFT JOIN coll_object_remark on coll_object.collection_object_id=coll_object_remark.collection_object_id
					LEFT JOIN coll_obj_cont_hist on coll_object.collection_object_id=coll_obj_cont_hist.collection_object_id
					left join container oc on coll_obj_cont_hist.container_id=oc.container_id
					left join container pc on oc.parent_container_id=pc.container_id
					left join preferred_agent_name on specimen_part_attribute.determined_by_agent_id=preferred_agent_name.agent_id
    				LEFT JOIN identification ON specimen_part.collection_object_id = identification.collection_object_id
				WHERE
					specimen_part.derived_from_cat_item = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">
			</cfquery>
			<cfquery name="parts" dbtype="query">
				SELECT
					part_id,
					label,
					container_id,
					part_name,
					base_part_name,
					preserve_method,
					sampled_from_obj_id,
					part_disposition,
					part_condition,
					lot_count_modifier,
					lot_count,
					display_lot_count,
					part_remarks,
					has_identification
				FROM
					rparts
				GROUP BY
					part_id,
					label,
					container_id,
					part_name,
					base_part_name,
					preserve_method,
					sampled_from_obj_id,
					part_disposition,
					part_condition,
					lot_count_modifier,
					lot_count,
					display_lot_count,
					part_remarks,
					has_identification
				ORDER BY
					has_identification asc, part_name
			</cfquery>
			<cfquery name="mPart" dbtype="query">
				SELECT * 
				FROM parts 
				WHERE sampled_from_obj_id IS NULL 
				ORDER BY has_identification asc, part_name
			</cfquery>
	
				<div class="col-12 py-3">
					<h1 class="h3">Edit Existing Parts</h1>
					<cfif mPart.recordCount EQ 0>
						<div class="bg-white border p-2">
							<p>No parts found</p>
						</div>
					<cfelse>
						<cfset var i = 0>
						<cfloop query="mPart">
							<cfset i = i + 1>
							<!--- lookup material sample id from guid_our_thing table --->
							<cfquery name="getMaterialSampleID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								SELECT guid_our_thing_id, assembled_identifier, assembled_resolvable, internal_fg, local_identifier
								FROM guid_our_thing
								WHERE guid_is_a = 'materialSampleID'
								  AND sp_collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#mPart.part_id#">
							</cfquery>
							<cfif mPart.has_identification EQ "1">
								<cfset addedClass = "part_occurrence">
							<cfelse>
								<cfset addedClass = "">
							</cfif>
							<div class="mx-0 py-1 mb-0 #addedClass#">
								<!--- find identifications of the part to see if this is a mixed collection --->
								<cfquery name="getIdentifications" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									SELECT identification_id
									FROM identification
									WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
								</cfquery>
								<form name="editPart#i#" id="editPart#i#" class="mb-2">
									<div class="col-12 form-row px-0">
										<input type="hidden" name="part_collection_object_id" value="#part_id#">
										<input type="hidden" name="method" value="updatePart">
										<div class="col-12 col-md-4 mb-2">
											<label for="part_name#i#" class="data-entry-label">Part Name</label>
											<input type="text" class="data-entry-input reqdClr" id="part_name#i#" name="part_name" value="#base_part_name#" required>
										</div>
										<div class="col-12 col-md-4 mb-2">
											<label for="preserve_method#i#" class="data-entry-label">Preserve Method</label>
											<select name="preserve_method" id="preserve_method#i#" class="data-entry-select reqdClr" required>
												<option value=""></option>
												<cfloop query="ctPreserveMethod">
													<cfif ctPreserveMethod.preserve_method EQ mPart.preserve_method>
														<cfset selected = "selected">
													<cfelse>
														<cfset selected = "">
													</cfif>
													<option value="#ctPreserveMethod.preserve_method#" #selected#>#ctPreserveMethod.preserve_method#</option>
												</cfloop>
											</select>
										</div>
										<div class="col-12 col-md-2 mb-2">
											<label for="lot_count_modifier#i#" class="data-entry-label">Count Modifier</label>
											<select name="lot_count_modifier" id="lot_count_modifier#i#" class="data-entry-select">
												<option value=""></option>
												<cfloop query="ctModifiers">
													<cfif ctModifiers.modifier EQ mPart.lot_count_modifier>
														<cfset selected = "selected">
													<cfelse>
														<cfset selected = "">
													</cfif>
													<option value="#ctModifiers.modifier#" #selected#>#ctModifiers.modifier#</option>
												</cfloop>
											</select>
										</div>
										<div class="col-12 col-md-2 mb-2">
											<label for="lot_count#i#" class="data-entry-label">Count</label>
											<input type="text" class="data-entry-input reqdClr" id="lot_count#i#" name="lot_count" value="#lot_count#" required>
										</div>
										<div class="col-12 col-md-4 mb-2">
											<label for="part_disposition#i#" class="data-entry-label">Disposition</label>
											<select name="disposition" id="part_disposition#i#" class="data-entry-select reqdClr" required>
												<option value=""></option>
												<cfloop query="ctDisp">
													<cfif ctDisp.coll_obj_disposition EQ mPart.part_disposition>
														<cfset selected = "selected">
													<cfelse>
														<cfset selected = "">
													</cfif>
													<option value="#ctDisp.coll_obj_disposition#" #selected#>#ctDisp.coll_obj_disposition#</option>
												</cfloop>
											</select>
										</div>
										<div class="col-12 col-md-4 mb-2">
											<label for="part_condition#i#" class="data-entry-label">Condition</label>
											<input type="text" class="data-entry-input reqdClr" id="part_condition#i#" name="condition" value="#part_condition#" required>
										</div>
										<div class="col-12 col-md-4 mb-2">
											<label for="container_label#i#" class="data-entry-label">Container</label>
											<input type="text" class="data-entry-input" id="container_label#i#" name="container_barcode" value="#label#">
											<input type="hidden" id="container_id#i#" name="container_id" value="#container_id#">
										</div>
										<div class="col-12 col-md-9 mb-2">
											<label for="part_remarks#i#" class="data-entry-label">Remarks (<span id="length_remarks_#i#"></span>)</label>
											<textarea id="part_remarks#i#" name="coll_object_remarks" 
												onkeyup="countCharsLeft('part_remarks#i#', 4000, 'length_remarks_#i#');"
												class="data-entry-textarea autogrow mb-1" maxlength="4000"
											>#part_remarks#</textarea>
										</div>
										<div class="col-12 col-md-3 pt-2">
											<button id="part_submit#i#" value="Save" class="mt-2 btn btn-xs btn-primary" title="Save Part">Save</button>
											<cfif getIdentifications.recordcount EQ 0>
												<button id="part_delete#i#" value="Delete" class="mt-2 btn btn-xs btn-danger" title="Delete Part">Delete</button>
												<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
													<button id="newpart_mixed#i#" value="Mixed" class="mt-2 btn btn-xs btn-warning" title="Make Mixed Collection">ID Mixed</button>
												</cfif>
											<cfelse>
												<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
													<button id="part_mixed#i#" value="Mixed" class="mt-2 btn btn-xs btn-warning" title="Make Mixed Collection">Edit Identifications</button>
												</cfif>
											</cfif>
											<output id="part_output#i#"></output>
										</div>
									</div>
								</form>

								<!--- Show identifications if this is a mixed collection --->
								<cfif getIdentifications.recordcount GT 0>
									<div class="col-12 small">
										<strong>Mixed Collection Identifications of #mpart.base_part_name# (#mpart.preserve_method#)</strong>
										#getIdentificationsUnthreadedHTML(collection_object_id=part_id)#
									</div>
								</cfif>

								<!--- Show part attributes --->
								<cfquery name="patt" dbtype="query">
									SELECT
										attribute_type,
										attribute_value,
										attribute_units,
										determined_date,
										attribute_remark,
										agent_name
									FROM
										rparts
									WHERE
										attribute_type IS NOT NULL AND
										part_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
									GROUP BY
										attribute_type,
										attribute_value,
										attribute_units,
										determined_date,
										attribute_remark,
										agent_name
								</cfquery>
								<div class="col-12 row mx-0 d-flex bg-white border py-1">
									<cfif patt.recordcount EQ 0>
										<span class="small90 font-weight-lessbold vertical-align-stretch">No Part Attributes:</span>
										<button class="btn btn-xs btn-secondary py-0 mx-3" onclick="editPartAttributes('#part_id#',reloadPartsAndSection)">Edit</button>
									<cfelse>
										<div class="col-12 px-0 small">
											<strong>Part Attributes (#patt.recordcount#):</strong>
											<button class="btn btn-xs btn-secondary mx-3" onclick="editPartAttributes('#part_id#',reloadPartsAndSection)">Edit</button>
											<cfloop query="patt">
												<div class="ml-2">
													#attribute_type# = #attribute_value#
													<cfif len(attribute_units) GT 0> #attribute_units#</cfif>
													<cfif len(determined_date) GT 0> (determined: #dateformat(determined_date,"yyyy-mm-dd")#)</cfif>
													<cfif len(agent_name) GT 0> by #agent_name#</cfif>
													<cfif len(attribute_remark) GT 0> - #attribute_remark#</cfif>
												</div>
											</cfloop>
										</div>
									</cfif>
								</div>
								<cfif getMaterialSampleID.recordcount GT 0>
									<!--- only show, and only allow addition of, materialSampleID values if there are any assigned to this part --->
									<div class="col-12">
										<ul class="list-unstyled pl-1">
											<cfloop query="getMaterialSampleID">
												<li>
													<strong>materialSampleID:</strong> <a href="#assembled_resolvable#" target="_blank">#assembled_identifier#</a>
													<cfif internal_fg EQ 1>
														<cfif left(assembled_identifier,9) EQ "urn:uuid:"> 
															<a href="/uuid/#local_identifier#/json" target="_blank"><img src="/shared/images/json-ld-data-24.png" alt="JSON-LD"></a>
														</cfif>
													</cfif>
												</li>
											</cfloop>
											<li>
												<button type="button" id="btn_pane1" class="btn btn-xs btn-secondary py-0 small" onclick="openEditMaterialSampleIDDialog(#part_id#,'materialSampleIDEditDialog','#guid# #part_name#',reloadPartsAndSection)">
													<cfif getMaterialSampleID.recordcount EQ 1>
														Add 
													<cfelse>
														Edit
													</cfif>
													externally assigned dwc:MaterialSampleID
												</button>
											</li>
										</ul>
									</div>
								</cfif>
							</div>

							<!--- Show subsamples --->
							<cfquery name="sPart" dbtype="query">
								SELECT * FROM parts WHERE sampled_from_obj_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
							</cfquery>
							<cfloop query="sPart">
								<div class="row mx-0 border-left border-right px-2 py-1 bg-light">
									<div class="col-12 small">
										<strong>Subsample:</strong> #part_name# | Condition: #part_condition# | Disposition: #part_disposition# | Count: #display_lot_count# | Container: #label#
										<cfif len(part_remarks) GT 0><br><em>Remarks:</em> #part_remarks#</cfif>
									</div>
								</div>
							</cfloop>

							<script>
								$(document).ready(function() {
									// make container barcode autocomplete
									makeContainerAutocompleteMetaExcludeCO("container_label#i#", "container_id#i#");
									// make part name autocomplete
									makePartNameAutocompleteMetaForCollection("part_name#i#", "#getCatItem.collection_cde#");
								});
							</script>
						</cfloop>
						<script>
							// Make all textareas with autogrow class be bound to the autogrow function on key up
							$(document).ready(function() { 
								$("textarea.autogrow").keyup(autogrow);
								$('textarea.autogrow').keyup();
							});
							// Add event listeners to the buttons
							document.querySelectorAll('button[id^="part_submit"]').forEach(function(button) {
								button.addEventListener('click', function(event) {
									event.preventDefault();
									// save changes to a part
									var id = button.id.replace('part_submit', '');
									// check form validity
									if (!$("##editPart" + id).get(0).checkValidity()) {
										// If the form is invalid, show validation messages
										$("##editPart" + id).get(0).reportValidity();
										return false; // Prevent form submission if validation fails
									}
									var feedbackOutput = 'part_output' + id;
									setFeedbackControlState(feedbackOutput,"saving")
									$.ajax({
										url: '/specimens/component/functions.cfc',
										type: 'POST',
										dataType: 'json',
										data: $("##editPart" + id).serialize(),
										success: function(response) {
											setFeedbackControlState(feedbackOutput,"saved");
											reloadPartsAndSection();
										},
										error: function(xhr, status, error) {
											setFeedbackControlState(feedbackOutput,"error")
											handleFail(xhr,status,error,"saving change to part.");
										}
									});
								});
							});
							document.querySelectorAll('button[id^="part_delete"]').forEach(function(button) {
								button.addEventListener('click', function(event) {
									event.preventDefault();
									// delete a part record
									var id = button.id.replace('part_delete', '');
									var feedbackOutput = 'part_output' + id;
									confirmDialog('Remove this part? This action cannot be undone.', 'Confirm Delete Part', function() {
										setFeedbackControlState(feedbackOutput,"deleting")
										$.ajax({
											url: '/specimens/component/functions.cfc',
											type: 'POST',
											dataType: 'json',
											data: {
												method: 'deletePart',
												collection_object_id: $("##editPart" + id + " input[name='part_collection_object_id']").val()
											},
											success: function(response) {
												setFeedbackControlState(feedbackOutput,"deleted");
												reloadPartsAndSection();
											},
											error: function(xhr, status, error) {
												setFeedbackControlState(feedbackOutput,"error")
												handleFail(xhr,status,error,"deleting part.");
											}
										});
									});
								});
							});
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
								document.querySelectorAll('button[id^="part_mixed"]').forEach(function(button) {
									button.addEventListener('click', function(event) {
										event.preventDefault();
										// make mixed collection
										var id = button.id.replace('part_mixed', '');
										var partId = $("##editPart" + id + " input[name='part_collection_object_id']").val();
										var guid = "#getCatItem.institution_acronym#:#getCatItem.collection_cde#:#getCatItem.cat_num# " + $('##editPart' + id + ' input[name="part_name"]').val() + ' (' + $('##editPart' + id + ' select[name="preserve_method"]').val() + ')';
										openEditIdentificationsDialog(partId,'identificationsDialog',guid,function(){
											reloadPartsAndSection();
										});
									});
								});
								document.querySelectorAll('button[id^="newpart_mixed"]').forEach(function(button) {
									button.addEventListener('click', function(event) {
										event.preventDefault();
										// confirm making mixed collection
										confirmDialog('Adding identifications to this part will make this cataloged item into a mixed collection.  This means that the cataloged item will no longer be a single taxon, but rather a collection of parts with different identifications.  <strong>Are you sure you want to do this?</strong>  This is appropriate for some cases in some collections, such as when a cataloged item is a composite of multiple taxa, such as pin with an ant and an associated insect on the same pin and a single catalog number, but not appropriate for all collections.  If you are unsure, please seek guidance before proceeding.', 
											'Confirm Mixed Collection', 
											function() {
												// make mixed collection
												var id = button.id.replace('newpart_mixed', '');
												var partId = $("##editPart" + id + " input[name='part_collection_object_id']").val();
												var guid = "#getCatItem.institution_acronym#:#getCatItem.collection_cde#:#getCatItem.cat_num# " + $('##editPart' + id + ' input[name="part_name"]').val() + ' (' + $('##editPart' + id + ' select[name="preserve_method"]').val() + ')';
												openEditIdentificationsDialog(partId,'identificationsDialog',guid,function(){
													reloadPartsAndSection();
												});
											}
										);
									});
								});
							</cfif>
							function reloadPartsSection() {
								// reload the edit existing parts section
								$.ajax({
									url: '/specimens/component/functions.cfc',
									type: 'POST',
									dataType: 'html',
									data: {
										method: 'getEditExistingPartsUnthreaded',
										collection_object_id: '#arguments.collection_object_id#'
									},
									success: function(response) {
										$('##editExistingPartsDiv').html(response);
									},
									error: function(xhr, status, error) {
										handleFail(xhr,status,error,"reloading edit existing parts.");
									}
								});
							}
						</script>
					</cfif>
				</div>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<p class="mt-2 text-danger">Error: #cfcatch.type# #error_message#</p>
			<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
				<cfdump var="#cfcatch#">
			</cfif>
		</cfcatch>
		</cftry>
	</cfoutput>
</cffunction>

<!--- createSpecimenPart creates a new specimen part record.
 @param derived_from_cat_item the collection object id of the cataloged item this part is derived from
 @param part_name the name of the part
 @param preserve_method the preservation method for the part
 @param lot_count the count of the lot
 @param lot_count_modifier the modifier for the lot count (optional)
 @param coll_obj_disposition the disposition of the specimen part collection object
 @param condition the condition of the specimen part collection object
 @param condition_remarks remarks about the condition (optional)
 @param container_barcode barcode of the container (optional)
 @param coll_object_remarks remarks about the specimen part collection object (optional)
 @param is_subsample whether this is a subsample (default false)
 @param subsampled_from_obj_id if this is a subsample, the collection object id it was sampled from (optional, required if is_subsample is true)
 @return a JSON object with success status or an http 500 error if there was an error
--->
<cffunction name="createSpecimenPart" returntype="any" access="remote" returnformat="json">
	<cfargument name="derived_from_cat_item" type="string" required="yes">
	<cfargument name="part_name" type="string" required="yes">
	<cfargument name="preserve_method" type="string" required="yes">
	<cfargument name="lot_count" type="string" required="yes">
	<cfargument name="lot_count_modifier" type="string" required="no" default="">
	<cfargument name="coll_obj_disposition" type="string" required="yes">
	<cfargument name="condition" type="string" required="yes">
	<cfargument name="condition_remarks" type="string" required="no" default="">
	<cfargument name="container_barcode" type="string" required="no" default="">
	<cfargument name="coll_object_remarks" type="string" required="no" default="">
	<cfargument name="is_subsample" type="boolean" required="no" default="false">
	<cfargument name="subsampled_from_obj_id" type="string" required="no" default="">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfif is_subsample>
				<cfif len(arguments.subsampled_from_obj_id) EQ 0>
					<cfthrow message="Error: subsampled_from_obj_id is required if is_subsample is true.">
				</cfif>
			</cfif>
			<!--- check that specified derived_from_cat_item exists --->
			<cfquery name="checkDerivedFrom" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT collection_object_id
				FROM cataloged_item
				WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.derived_from_cat_item#">
			</cfquery>
			<cfif checkDerivedFrom.recordcount EQ 0>
				<cfthrow message="Error: Specified derived_from_cat_item does not exist.">
			</cfif>
			<!--- if subsample, check that the part being sampled from exists --->
			<cfif arguments.is_subsample>
					<cfquery name="checkSubsampledFrom" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT collection_object_id
					FROM collection_object
					WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.subsampled_from_obj_id#">
						AND coll_object_type = 'SP'
				</cfquery>
				<cfif checkSubsampledFrom.recordcount NEQ 1>
					<cfthrow message="Error: Specified subsampled_from_obj_id does not exist or is not a specimen part.">
				</cfif>
			</cfif>
			<!--- obtain the next collection_object_id from the sequence to use for the new part --->
			<cfquery name="getPK" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getPK_result">
				SELECT sq_collection_object_id.nextval as part_id 
				FROM dual
			</cfquery>
			<cfset var newPartCollObjectID = getPK.part_id>
			<!--- insert a collection object record for the specimen part --->
			<cfquery name="newCollObject" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="newCollObject_result">
				INSERT INTO coll_object (
					COLLECTION_OBJECT_ID,
					COLL_OBJECT_TYPE,
					entered_person_id,
					coll_object_entered_date,
					COLL_OBJ_DISPOSITION,
					LOT_COUNT,
					LOT_COUNT_MODIFIER,
					CONDITION,
					CONDITION_REMARKS
				)
				VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.newPartCollObjectID#">,
					<cfif is_subsample> 'SS' <cfelse> 'SP' </cfif>,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.myAgentId#">,
					sysdate,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.coll_obj_disposition#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.lot_count#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.lot_count_modifier#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.condition#">,
					<cfif len(arguments.condition_remarks) GT 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.condition_remarks#">
					<cfelse>
						NULL
					</cfif>
				)
			</cfquery>
			<cfquery name="newPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="newPart_result">
				INSERT INTO specimen_part (
					COLLECTION_OBJECT_ID
					,PART_NAME
					,PRESERVE_METHOD
					,DERIVED_FROM_CAT_ITEM)
				VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.newPartCollObjectID#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.part_name#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.preserve_method#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.derived_from_cat_item#">)
			</cfquery>
			<cfif newPart_result.recordcount NEQ 1>
				<cfthrow message="Error: Other than one specimen_art record created">
			</cfif>
			<!--- insert collection object remarks if they were provided --->
			<cfif len(arguments.coll_object_remarks) GT 0>
				<cfquery name="newCollObjectRemark" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					INSERT INTO coll_object_remark (
						collection_object_id
						,coll_object_remarks
					) VALUES (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.newPartCollObjectID#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.coll_object_remarks#">
					)
				</cfquery>
			</cfif>
			<!--- from procedure b_bulkload_parts 
			    SELECT container_id INTO r_container_id FROM coll_obj_cont_hist WHERE collection_object_id = part_id;
			    --dbms_output.put_line ('CURRENT part IS : ' || r_container_id);
				SELECT container_id into r_parent_container_id FROM container WHERE barcode = r_barcode;
				--dbms_output.put_line ('got parent contianer id: ' || r_parent_container_id);
				UPDATE container SET 
					parent_container_id = r_parent_container_id,
					parent_install_date = sysdate
				WHERE 
					container_id = r_container_id;
			--->
			<!--- insert of a container of type collection object to represent the part is performed by trigger MAKE_PART_COLL_OBJ_CONT	--->
			<cfif len(arguments.container_barcode) GT 0>
				<!--- place the collection object container into the specified container and --->
				<!--- insert a collection object container history record if a container barcode was provided --->
				<!--- first, find the current collection object container --->
				<cfquery name="getPartContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT container_id 
					FROM coll_obj_cont_hist 
					WHERE collection_object_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.newPartCollObjectID#">
						and current_container_fg = 1
				</cfquery>
				<cfif getPartContainer.recordcount EQ 0>
					<cfthrow message = "Unable to find the current container of type collection object for the part">
				</cfif>
				<!--- then find the container into which to place it --->
				<cfquery name="getParentContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT container_id 
					FROM container 
					WHERE barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.container_barcode#">
				</cfquery>
				<cfif getParentContainer.recordcount EQ 0>
					<cfthrow message="Unable to find specified parent container">
				</cfif>
				<!--- then place the container into the specified parent --->
				<!--- trigger MOVE_CONTAINER enforces rules on container movement --->
				<!--- trigger GET_CONTAINER_HISTORY updates the container_history to reflect the move --->
				<cfquery name="moveToParent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="moveToParent_result">
					UPDATE container 
					SET parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getParentContainer.container_id#">
					WHERE container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getPartContainer.container_id#">
				</cfquery>
				<cfif moveToParent_result.recordcount NEQ 1>
					<cfthrow message="Unable to move to parent container, move altered other than 1 container. ">
				</cfif>
			</cfif>

			<cftransaction action="commit">
			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["id"] = "#newPartCollObjectID#">
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

<!--- deletePart deletes a specimen part record.
 @param collection_object_id the collection_object_id of the part to delete
 @return a JSON object with success status or an http 500 error if there was an error
--->
<cffunction name="deletePart" returntype="any" access="remote" returnformat="json">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<!--- check that the specified collection_object_id exists and is a specimen part --->
			<cfquery name="checkPartExists" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT collection_object_id
				FROM coll_object
				WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">
					AND coll_object_type = 'SP'
			</cfquery>
			<cfif checkPartExists.recordcount EQ 0>
				<cfthrow message="Error: Specified collection_object_id does not exist or is not a specimen part.">
			</cfif>
			<!--- check if the part has subsamples --->
			<cfquery name="checkSubsamples" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT collection_object_id
				FROM specimen_part
				WHERE sampled_from_obj_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">
			</cfquery>
			<!--- if it does, throw an error --->
			<cfif checkSubsamples.recordcount GT 0>
				<cfthrow message="Error: Cannot delete part with subsamples. Please remove subsamples first.">
			</cfif>

			<!--- check if the part has identifications --->
			<cfquery name="checkIdentifications" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT identification_id
				FROM identification
				WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">
			</cfquery>
			<cfif checkIdentifications.recordcount GT 0>
				<cfthrow message="Error: Cannot delete part with identifications. Please remove identifications first.">
			</cfif>

			<!--- check if the part has attributes --->
			<cfquery name="checkAttributes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT part_attribute_id
				FROM specimen_part_attribute
				WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">
			</cfquery>
			<cfif checkAttributes.recordcount GT 0>
				<cfthrow message="Error: Cannot delete part with attributes. Please remove attributes first.">
			</cfif>
			<!--- if there is a materialSampleID, set its foreign key to null --->
			<cfquery name="nullMaterialSampleID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE guid_our_thing
				SET sp_collection_object_id = NULL
				WHERE sp_collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">
			</cfquery>

			<!--- if there is an occurrenceID, set its foreign key to null --->
			<cfquery name="nullOccurrenceID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE guid_our_thing
				SET co_collection_object_id = NULL
				WHERE co_collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">
			</cfquery>

			<!--- delete the specimen part record --->
			<cfquery name="deletePart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="deletePart_result">
				DELETE FROM specimen_part
				WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">
			</cfquery>
			<!--- delete of the collection object record is done by TR_SPECIMENPART_AD --->
			<!--- delete of the coll_object_remark record is done by TR_SPECIMENPART_AD --->
			<!--- delete of any coll_obj_cont_hist records is done by TR_SPECIMENPART_AD --->
			<cfif deletePart_result.recordcount NEQ 1>
				<cfthrow message="Error: Other than one coll_object or specimen_part record deleted">
			</cfif>

			<cftransaction action="commit">
			<cfset row = StructNew()>
			<cfset row["status"] = "deleted">	
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

<cffunction name="updatePart" returntype="any" access="remote" returnformat="json">
	<cfargument name="part_collection_object_id" type="string" required="yes">
	<cfargument name="part_name" type="string" required="yes">
	<cfargument name="preserve_method" type="string" required="yes">
	<cfargument name="disposition" type="string" required="yes">
	<cfargument name="condition" type="string" required="yes">
	<cfargument name="lot_count" type="string" required="yes">
	<cfargument name="lot_count_modifier" type="string" required="yes">
	<cfargument name="coll_object_remarks" type="string" required="yes">
	<!--- TODO: Update container code --->
	<cfargument name="parent_container_id" type="string" required="no" default="">
	<cfargument name="part_container_id" type="string" required="no" default="">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<!--- TODO: Unused???  --->
			<cfset enteredbyid = session.myAgentId>

			<cfquery name="upPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE specimen_part 
				SET
					part_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.part_name#">,
					preserve_method = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.preserve_method#">
				WHERE 
					collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.part_collection_object_id#">
			</cfquery>
			<cfquery name="upPartCollObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE coll_object 
				SET
					coll_obj_disposition = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.disposition#">,
					condition = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.condition#">,
					lot_count_modifier= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.lot_count_modifier#">,
					lot_count = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.lot_count#">
				WHERE 
					collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.part_collection_object_id#">
			</cfquery>

			<!--- check if a remarks record exists for this specimen part --->
			<cfquery name="ispartRem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT coll_object_remarks 
				FROM coll_object_remark 
				WHERE
					collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.part_collection_object_id#">
			</cfquery>
			<cfif ispartRem.recordcount is 0>
				<!--- if not and there are remarks, add a record --->
				<cfif len(arguments.coll_object_remarks) gt 0>
					<cfquery name="newCollRem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						INSERT INTO coll_object_remark (
							collection_object_id, 
						coll_object_remarks
						) VALUES (
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.part_collection_object_id#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.coll_object_remarks#">
						)
					</cfquery>
				</cfif>
			<cfelse>
				<!--- if one exists, update it. --->
				<cfquery name="updateCollRem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE coll_object_remark 
					SET
						<cfif len(arguments.coll_object_remarks) gt 0>
							coll_object_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.coll_object_remarks#">
						<cfelse>
							coll_object_remarks = null
						</cfif>
					WHERE 
							collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.part_collection_object_id#">
				</cfquery>
			</cfif>

			<!---- TODO: Update container placement code 
			<cfif len(this.newCode) gt 0>
				<cfquery name="isCont" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT
						container_id, container_type, parent_container_id
					FROM
						container
					WHERE
						barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisnewCode#">
						AND container_type <> 'collection object'
						AND institution_acronym = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#institution_acronym#">
				</cfquery>
				<cfif #isCont.container_type# is 'cryovial label'>
					<cfquery name="upCont" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE container 
						SET container_type='cryovial'
						WHERE container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#isCont.container_id#">
							AND container_type='cryovial label'
					</cfquery>
				</cfif>
				<cfif isCont.recordcount is 1>
					<cfquery name="thisCollCont" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT
							container_id
						FROM
							coll_obj_cont_hist
						WHERE
						collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisPartId#">
					</cfquery>
					<cfquery name="upPartBC" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE
							container
						SET
							parent_install_date = sysdate,
							parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#isCont.container_id#">
						WHERE
							container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisCollCont.container_id#">
					</cfquery>
					<cfquery name="upPartPLF" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE container 
						SET print_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisprint_fg#">
						WHERE
							container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#isCont.container_id#">
					</cfquery>
				</cfif>
				<cfif isCont.recordcount lt 1>
					<cfthrow message = "That barcode was not found in the container database. You can only put parts into appropriate pre-existing containers.">
				</cfif>
				<cfif #isCont.recordcount# gt 1>
					<cfthrow message="That barcode has multiple matches, that should not occurr.. Please file a bug report">
				</cfif>
			</cfif>
			--->

			<cftransaction action="commit">
			<cfset row = StructNew()>
			<cfset row["status"] = "deleted">	
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


<!--- getEditCitationHTML returns the HTML for the edit citations dialog.
 @param collection_object_id the collection_object_id for the cataloged item to edit citations for.
 @return HTML for the edit citations dialog, including a form to add new citations and a table of existing citations.
--->
<cffunction name="getEditCitationHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfthread name="getEditCitationThread" collection_object_id = "#arguments.collection_object_id#">
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
						cataloged_item.collection_object_id = <cfqueryparam value="#attributes.collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
				</cfquery>
				<cfset guid = "#getCatItem.institution_acronym#:#getCatItem.collection_cde#:#getCatItem.cat_num#">
				
				<cfquery name="ctTypeStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT type_status 
					FROM ctcitation_type_status 
					ORDER BY type_status
				</cfquery>

				<!--- add new citation --->
				<div class="col-12 mt-4 px-1">
					<div class="container-fluid">
						<div class="row">
							<div class="col-12">
								<div class="add-form">
									<div class="add-form-header pt-1 px-2" id="headingCitation">
										<h2 class="h3 my-0 px-1 pb-1">Add New Citation of #guid#</h2>
									</div>
									<div class="card-body">
										<form name="newCitation" id="newCitation" class="mb-0">
											<input type="hidden" name="collection_object_id" value="#getCatItem.collection_object_id#">
											<input type="hidden" name="method" value="createCitation">
											<div class="row mx-0 pb-2 col-12 px-0 mt-2 mb-1">
												<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_publications")>
													<cfset cols = "col-12 col-md-9">
												<cfelse>
													<cfset cols = "col-12">
												</cfif>
												<div class="float-left #cols# px-1 pb-2">
													<label for="publication" class="data-entry-label">Publication <span id="lookedUpPublicationLink"></span></label>
													<input type="hidden" name="publication_id" id="publication_id" value="">
													<input type="text" id="publication" value="" class="data-entry-input reqdClr" required>
													<script>
														/**
														 * Sets the publication link and short title in the UI.
														 * @param {string} publicationId - The ID of the publication.
														 * @see makePublicationAutocompleteMeta, where this can be passed as the callback
														 */
														function setPublicationLink(publicationId) {
															if (publicationId) {
																var text = "<span id='lookedUpPublicationShort'>View</span>";
																document.getElementById("lookedUpPublicationLink").innerHTML = '(<a href="/publications/showPublication.cfm?publication_id=' + publicationId + '" target="_blank">'+text+'</a>)';
																// lookup the publication short citation
																$.ajax({
																	url: '/publications/component/search.cfc',
																	type: 'POST',
																	dataType: 'json',
																	data: {
																		method: 'getPublicationCitationForms',
																		publication_id: publicationId
																	},
																	success: function(response) {
																		console.log(response);
																		// Check if the response contains a short title
																		if (response && response[0].short) {
																			document.getElementById("lookedUpPublicationShort").innerHTML = response[0].short;
																		}
																	},
																	error: function(xhr, status, error) {
																		console.error('Error fetching publication short title:', error);
																	}
																});
															} else {
																document.getElementById("lookedUpPublicationLink").innerHTML = '';
															}
														}
													</script>
												</div>
												<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_publications")>
													<div class="col-12 col-md-3 px-1 mt-3 pb-2">
														<a class="btn btn-xs btn-outline-primary w-100 py-1" target="_blank" href="/publications/Publication.cfm?action=new">Add New Publication <i class="fas fa-external-link-alt"></i></a>
													</div>
												</cfif>
												<div class="float-left col-12 col-md-4 pb-2 px-1">
													<label for="cited_sci_Name" class="data-entry-label">Cited Scientific Name</label>
													<input name="citsciname" class="data-entry-input reqdClr" id="cited_sci_Name" type="text" required>
													<input type="hidden" name="cited_taxon_name_id" id="cited_taxon_name_id" value="">
												</div>
												<div class="float-left col-12 col-md-3 pb-2 px-1">
													<label for="type_status" class="data-entry-label">Citation Type</label>
													<select name="type_status" id="type_status" class="data-entry-select reqdClr" required>
														<option value=""></option>
														<cfloop query="ctTypeStatus">
															<option value="#type_status#">#type_status#</option>
														</cfloop>
													</select>
												</div>
												<div class="float-left col-12 col-md-2 pb-2 px-1">
													<label for="occurs_page_number" class="data-entry-label">Page ##</label>
													<input name="occurs_page_number" id="occurs_page_number" class="data-entry-input" type="text" value="">
												</div>
												<div class="float-left col-12 col-md-3 pb-2 px-1">
													<label for="citation_page_uri" class="data-entry-label">Page URI</label>
													<input name="citation_page_uri" id="citation_page_uri" class="data-entry-input" type="text" value="">
												</div>
												<div class="float-left col-12 pb-1 px-1 pb-2">
													<label for="citation_remarks" class="data-entry-label">Remarks <span id="length_remarks"></span></label>
													<textarea id="citation_remarks" name="citation_remarks" 
														onkeyup="countCharsLeft('citation_remarks', 4000, 'length_remarks');"
														class="data-entry-textarea autogrow mb-1" maxlength="4000"></textarea>
												</div>
												<div class="col-12 col-md-12 px-1 mt-2 pb-2">
													<button id="newCitation_submit" value="Create" class="btn btn-xs btn-primary" title="Create Citation">Create Citation</button>
													<output id="newCitation_output"></output>
												</div>
											</div>
										</form>
									</div>
								</div>
								<script>
									$(document).ready(function() {
										// make publication autocomplete
										makePublicationAutocompleteMeta("publication", "publication_id",setPublicationLink);
										// make scientific name autocompletes
										makeScientificNameAutocompleteMeta("cited_sci_Name", "cited_taxon_name_id");
									});
									// Add event listener to the save button
									$('##newCitation_submit').on('click', function(event) {
										event.preventDefault();
										// Validate the form
										if ($('##newCitation')[0].checkValidity() === false) {
											// If the form is invalid, show validation messages
											$('##newCitation')[0].reportValidity();
											return false; // Prevent form submission if validation fails
										}
										setFeedbackControlState("newCitation_output","saving");
										$.ajax({
											url: '/publications/component/functions.cfc',
											type: 'POST',
											responseType: 'json',
											data: $('##newCitation').serialize(),
											success: function(response) {
												console.log(response);
												setFeedbackControlState("newCitation_output","saved");
												reloadEditExistingCitations();
											},
											error: function(xhr, status, error) {
												setFeedbackControlState("newCitation_output","error");
												handleFail(xhr,status,error,"saving citation.");
											}
										});
									});
									function reloadEditExistingCitations() {
										// reload the edit existing citations section
										$.ajax({
											url: '/specimens/component/functions.cfc',
											type: 'POST',
											dataType: 'html',
											data: {
												method: 'getEditExistingCitationsUnthreaded',
												collection_object_id: '#attributes.collection_object_id#'
											},
											success: function(response) {
												$('##editExistingCitationsDiv').html(response);
											},
											error: function(xhr, status, error) {
												handleFail(xhr,status,error,"reloading edit existing citations.");
											}
										});
									}
								</script>
								<!--- edit existing citations --->
								<div id="editExistingCitationsDiv">
									<!--- this div is replaced with the edit existing citations HTML when citations are added --->
									#getEditExistingCitationsUnthreaded(collection_object_id=attributes.collection_object_id)#
								</div>
							</div>
						</div>
					</div>
				</div>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<p class="mt-2 text-danger">Error: #cfcatch.type# #error_message#</p>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
					<cfdump var="#cfcatch#">
				</cfif>
			</cfcatch>
			</cftry>
		</cfoutput> 
	</cfthread>
	<cfthread action="join" name="getEditCitationThread" />
	<cfreturn getEditCitationThread.output>
</cffunction>

<!--- 
 getEditExistingCitationsUnthreaded returns the HTML for the edit existing citations section, intended to be used
 from within threaded getEditCitationHTML or invoked independently to reload just the edit existing citations section 
 of the dialog.
 @param collection_object_id the collection object id to obtain existing citations for
 @return a string containing the HTML for the edit existing citations section
--->
<cffunction name="getEditExistingCitationsUnthreaded" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">

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
					cataloged_item.collection_object_id = <cfqueryparam value="#arguments.collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
			</cfquery>
			<cfset guid = "#getCatItem.institution_acronym#:#getCatItem.collection_cde#:#getCatItem.cat_num#">
			
			<cfquery name="ctTypeStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT type_status 
				FROM ctcitation_type_status 
				ORDER BY type_status
			</cfquery>
			
			<cfquery name="getCited" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT
					'TODO' as citation_id,
					citation.publication_id,
					citation.collection_object_id,
					cat_num,
					identification.scientific_name,
					citedTaxa.scientific_name as citSciName,
					occurs_page_number,
					citation_page_uri,
					citation.type_status,
					citation_remarks,
					cit_current_fg,
					citation_remarks,
					publication_title,
					REGEXP_REPLACE(longpub.formatted_publication, '<[\\/]?(i|em|b)>', '', 1, 0) as formpublong,
					short.formatted_publication as formpubshort,
					publication.publication_id,
					publication.published_year,
					publication.publication_type,
					doi,
					cited_taxon_name_id,
					ctcitation_type_status.category
				FROM
					citation
					join cataloged_item on citation.collection_object_id = cataloged_item.collection_object_id
					left join identification on cataloged_item.collection_object_id = identification.collection_object_id AND identification.accepted_id_fg = 1
					join ctcitation_type_status on citation.type_status = ctcitation_type_status.type_status 
					left join taxonomy citedTaxa on citation.cited_taxon_name_id = citedTaxa.taxon_name_id
					join publication on citation.publication_id = publication.publication_id 
					join formatted_publication longpub on citation.publication_id = longpub.publication_id AND longpub.format_style='long'
					join formatted_publication short on citation.publication_id = short.publication_id AND short.format_style='short'
				WHERE
					citation.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">
				ORDER BY
					ctcitation_type_status.ordinal,
					citation.type_status,
					publication.published_year DESC
			</cfquery>
			
			<div class="row">
				<div class="col-12">
					<h1 class="h3 mb-1 mt-3 px-1">Edit Existing Citations</h1>
					<div class="col-12 px-0 pb-3">
						<cfif getCited.recordCount EQ 0>
							<li>No citations</li>
						<cfelse>
							<cfset var i = 0>
							<cfloop query="getCited">
								<cfset i = i + 1>
								<form name="editCitation#i#" id="editCitation#i#">
									<input type="hidden" name="collection_object_id" value="#collection_object_id#">
									<input type="hidden" name="citation_id" value="#citation_id#">
									<!--- TODO: add citation_id, until then use weak key values --->
									<input type="hidden" name="original_collection_object_id" id="orig_col_obj_id#i#"  value="#collection_object_id#">
									<input type="hidden" name="original_publication_id" id="orig_publication_id#i#" value="#publication_id#">
									<input type="hidden" name="original_cited_taxon_name_id" id="orig_cited_name_id#i#" value="#cited_taxon_name_id#">
									<input type="hidden" name="method" value="updateCitation">
									<div class="row mx-0 border bg-light rounded pt-3 pb-2 mb-0">
										<div class="col-12 px-1 pb-2">
											<label for="cit_publication#i#" class="data-entry-label">
												Publication 
												(<a href="/publications/showPublication.cfm?publication_id=#publication_id#" target="_blank">#formpubshort#</a>)
											</label>
											<input type="hidden" name="publication_id" id="cit_publication_id#i#" value="#publication_id#">
											<input type="text" class="data-entry-input" id="cit_publication#i#" name="publication" value="#formpublong#">
										</div>
										<div class="col-12 col-md-4 px-1 pb-2">
											<label for="cit_cited_name#i#" class="data-entry-label">Cited Scientific Name</label>
											<input type="hidden" name="cited_taxon_name_id" id="cit_cited_name_id#i#" value="#cited_taxon_name_id#">
											<input type="text" class="data-entry-input reqdClr" id="cit_cited_name#i#" name="cited_name" value="#citSciName#" required>
										</div>
										<div class="col-12 col-md-3 px-1 pb-2">
											<label for="cit_type_status#i#" class="data-entry-label">Citation Type</label>
											<select name="type_status" id="cit_type_status#i#" class="data-entry-select reqdClr" required>
												<option value=""></option>
												<cfloop query="ctTypeStatus">
													<cfif ctTypeStatus.type_status EQ getCited.type_status>
														<cfset selected = "selected">
													<cfelse>
														<cfset selected = "">
													</cfif>
													<option value="#ctTypeStatus.type_status#" #selected#>#ctTypeStatus.type_status#</option>
												</cfloop>
											</select>
										</div>
										<div class="col-12 col-md-2 px-1 pb-2">
											<label for="cit_page#i#" class="data-entry-label">Page ##</label>
											<input type="text" class="data-entry-input" id="cit_page#i#" name="occurs_page_number" value="#occurs_page_number#">
										</div>
										<div class="col-12 col-md-3 px-1 pb-2">
											<label for="cit_page_uri#i#" class="data-entry-label">Page URI</label>
											<input type="text" class="data-entry-input" id="cit_page_uri#i#" name="citation_page_uri" value="#citation_page_uri#">
										</div>
										<div class="col-12 col-md-9 px-1 pb-2">
											<label for="cit_remarks#i#" class="data-entry-label">Remarks (<span id="length_remarks_#i#"></span>)</label>
											<textarea id="cit_remarks#i#" name="citation_remarks" 
												onkeyup="countCharsLeft('cit_remarks#i#', 4000, 'length_remarks_#i#');"
												class="data-entry-textarea autogrow mb-1" maxlength="4000"
											>#citation_remarks#</textarea>
										</div>
										<div class="col-12 col-md-3 px-1 mt-3">
											<button id="cit_submit#i#" value="Save" class="btn btn-xs btn-primary" title="Save Citation">Save</button>
											<button id="cit_delete#i#" value="Delete" class="btn btn-xs mx-1 btn-danger" title="Delete Citation">Delete</button>
											<output id="cit_output#i#"></output>
										</div>
									</div>
								</form>
								<script>
									$(document).ready(function() {
										// make publication autocomplete
										makePublicationAutocompleteMeta("cit_publication#i#", "cit_publication_id#i#");
										// make cited name autocomplete
										makeScientificNameAutocompleteMeta("cit_cited_name#i#", "cit_cited_name_id#i#");
									});
								</script>
							</cfloop>
							<script>
								// Make all textareas with autogrow class be bound to the autogrow function on key up
								$(document).ready(function() { 
									$("textarea.autogrow").keyup(autogrow);
									$('textarea.autogrow').keyup();
								});
								// Add event listeners to the buttons
								document.querySelectorAll('button[id^="cit_submit"]').forEach(function(button) {
									button.addEventListener('click', function(event) {
										event.preventDefault();
										// save changes to a citation
										var id = button.id.replace('cit_submit', '');
										// check form validity
										if (!$("##editCitation" + id).get(0).checkValidity()) {
											// If the form is invalid, show validation messages
											$("##editCitation" + id).get(0).reportValidity();
											return false; // Prevent form submission if validation fails
										}
										var feedbackOutput = 'cit_output' + id;
										setFeedbackControlState(feedbackOutput,"saving")
										$.ajax({
											url: '/publications/component/functions.cfc',
											type: 'POST',
											dataType: 'json',
											data: $("##editCitation" + id).serialize(),
											success: function(response) {
												setFeedbackControlState(feedbackOutput,"saved");
												reloadCitations();
											},
											error: function(xhr, status, error) {
												setFeedbackControlState(feedbackOutput,"error")
												handleFail(xhr,status,error,"saving change to citation.");
											}
										});
									});
								});
								document.querySelectorAll('button[id^="cit_delete"]').forEach(function(button) {
									button.addEventListener('click', function(event) {
										event.preventDefault();
										// delete a citation record
										var id = button.id.replace('cit_delete', '');
										var feedbackOutput = 'cit_output' + id;
										setFeedbackControlState(feedbackOutput,"deleting")
										$.ajax({
											url: '/publications/component/functions.cfc',
											type: 'POST',
											dataType: 'json',
											data: {
												method: 'deleteCitation',
												citation_id: $("##editCitation" + id + " input[name='citation_id']").val(),
												publication_id: $("##editCitation" + id + " input[name='publication_id']").val(),
												cited_taxon_name_id: $("##editCitation" + id + " input[name='cited_taxon_name_id']").val(),
												collection_object_id: $("##editCitation" + id + " input[name='collection_object_id']").val()
											},
											success: function(response) {
												if (response && response[0].status == "deleted") {
													setFeedbackControlState(feedbackOutput,"deleted");
													reloadCitations();
													// remove the form from the DOM
													$("##editCitation" + id).remove();
												} else {
													setFeedbackControlState(feedbackOutput,"error");
													console.log(response)
												}
											},
											error: function(xhr, status, error) {
												setFeedbackControlState(feedbackOutput,"error")
												handleFail(xhr,status,error,"deleting citation.");
											}
										});
									});
								});
							</script>
						</cfif>
					</div>
				</div>
			</div>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<p class="mt-2 text-danger">Error: #error_message#</p>
			<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
				<cfdump var="#cfcatch#">
			</cfif>
		</cfcatch>
		</cftry>
	</cfoutput>
</cffunction>	


<!--- Duplicate of function in ajax/functions.cfc TODO: Determine where this goes --->
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

<!--- getEditAttributesHTML obtain the content of a dialog for editing attributes for a collection object.
 @param collection_object_id the collection object id to obtain the attributes for
 @return a string containing the HTML for the edit attributes dialog
--->
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
										<h2 class="h3 my-0 px-1 pb-1">Add New Attribute to #guid#</h2>
									</div>
									<div class="card-body">
										<form name="newAttribute" id="newAttribute" class="mb-1">
											<input type="hidden" name="collection_object_id" value="#collection_object_id#">
											<input type="hidden" name="method" value="addAttribute">
											<div class="row mx-0 pb-2">
												<div class="col-12 col-md-4 pb-2 px-1">
													<label for="attribute_type" class="data-entry-label">Name</label>
													<select name="attribute_type" id="attribute_type" class="data-entry-select reqdClr" required>
														<option value=""></option>
														<cfloop query="getAttributeTypes">
															<option value="#attribute_type#">#attribute_type#</option>
														</cfloop>
													</select>
												</div>
												<div class="col-12 col-md-4 pb-2 px-1">
													<label for="attribute_value" class="data-entry-label">Value</label>
													<input type="text" class="data-entry-input" id="attribute_value" name="attribute_value" value="">
												</div>
												<div class="col-12 col-md-4 pb-2 px-1">
													<label for="attribute_units" class="data-entry-label">Units</label>
													<input type="text" class="data-entry-input" id="attribute_units" name="attribute_units" value="">
												</div>
												<div class="col-12 col-md-4 pb-2 px-1">
													<label for="determined_by_agent" class="data-entry-label">Determiner</label>
													<input type="text" class="data-entry-input" id="determined_by_agent" name="determined_by_agent" value="#getCurrentUser.agent_name#">
													<input type="hidden" name="determined_by_agent_id" id="determined_by_agent_id" value="#getCurrentUser.agent_id#">
												</div>
												<div class="col-12 col-md-4 pb-2 px-1">
													<label for="determined_date" class="data-entry-label">Determined Date</label>
													<input type="text" class="data-entry-input" id="determined_date" name="determined_date" 
														placeholder="yyyy-mm-dd" value="#dateformat(now(),"yyyy-mm-dd")#">
												</div>
												<div class="col-12 col-md-4 pb-2 px-1">
													<label for="determination_method" class="data-entry-label">Determined Method</label>
													<input type="text" class="data-entry-input" id="determination_method" name="determination_method" value="">
												</div>
												<div class="col-12 col-md-10 pb-2 px-1">
													<label for="attribute_remark" class="data-entry-label">Remarks</label>
													<input type="text" class="data-entry-input" id="attribute_remark" name="attribute_remark" value="" maxlength="255">
												</div>
												<div class="col-12 col-md-2 px-1 mt-2">
													<button id="newAttribute_submit" value="Create" class="mt-2 btn btn-xs btn-primary" title="Create Attribute">Create Attribute</button>
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
		<h2 class="h3 mt-4 px-2 mb-0">Edit Existing Attributes</h2>
		<div class="col-12 px-0 pb-3">
			<cfif getAttributes.recordCount EQ 0>
				<li>No attributes found for this specimen.</li>
			</cfif>
			<cfset i = 0>
			<cfloop query="getAttributes">
				<cfquery name="getAttributeCodeTables" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT
						attribute_type,
						upper(value_code_table) value_code_table,
						upper(units_code_table) units_code_table
					FROM
						ctattribute_code_tables
					WHERE 
						attribute_type = <cfqueryparam value="#getAttributes.attribute_type#" cfsqltype="CF_SQL_VARCHAR">
				</cfquery>
				<cfset i = i + 1>
				<form name="editAttribute#i#" id="editAttribute#i#" class="my-0 py-2">
					<input type="hidden" name="collection_object_id" value="#collection_object_id#">
					<input type="hidden" name="attribute_id" value="#attribute_id#">
					<input type="hidden" name="method" value="updateAttribute">
					<div class="row mx-0 border bg-light py-2">
						<div class="col-12 col-md-2 mt-1 pb-2">
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
						<div class="col-12 col-md-2 mt-1 pb-2">
							<label for="att_value" class="data-entry-label reqdClr" required>Value</label>
							<cfif getAttributeCodeTables.recordcount GT 0 AND len(getAttributeCodeTables.value_code_table) GT 0>
								<cfset valueCodeTable = getAttributeCodeTables.value_code_table>
								<!--- find out if the value code table has a collection_cde field --->
								<cfquery name="checkForCollectionCde" datasource="uam_god">
									SELECT
										COUNT(*) as ct
									FROM
										sys.all_tab_columns
									WHERE
										table_name = <cfqueryparam value="#valueCodeTable#" cfsqltype="CF_SQL_VARCHAR">
										AND owner = 'MCZBASE'
										AND column_name = 'COLLECTION_CDE'
								</cfquery>
								<!--- default is attribute field is the attribute code table name with CT prefix removed --->
								<cfset var field="">
								<cfif ucase(valueCodeTable) EQ "CTASSOCIATED_GRANTS">
									<cfset field="ASSOCIATED_GRANT">
								<cfelseif ucase(valueCodeTable) EQ "CTCOLLECTION_FULL_NAMES">
									<cfset field="COLLECTION">
								<cfelse>
									<cfset field=replace(valueCodeTable,"CT","","one")>
								</cfif>
								<cfquery name="getValueCodeTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									SELECT
										#field# as value
									FROM
										#valueCodeTable#
									<cfif checkForCollectionCde.ct GT 0>
										WHERE
											collection_cde = <cfqueryparam value="#getCatItem.collection_cde#" cfsqltype="CF_SQL_VARCHAR">
									</cfif>
									ORDER BY
										#field#
								</cfquery>
								<select class="data-entry-select reqdClr" id="att_value#i#" name="attribute_value" required>
									<option value=""></option>
									<cfloop query="getValueCodeTable">
										<option value="#getValueCodeTable.value#" <cfif getValueCodeTable.value EQ getAttributes.attribute_value>selected</cfif>>#value#</option>
									</cfloop>
								</select>
							<cfelse>
								<input type="text" class="data-entry-input" id="att_value#i#" name="attribute_value" value="#attribute_value#">
							</cfif>
						</div>
						<div class="col-12 col-md-2 mt-1 pb-2">
							<label for="att_units" class="data-entry-label">Units</label>
							<cfif getAttributeCodeTables.recordcount GT 0 AND len(getAttributeCodeTables.units_code_table) GT 0>
								<cfset unitsCodeTable = getAttributeCodeTables.units_code_table>
								<cfquery name="getUnitsCodeTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									SELECT
										#replace(unitsCodeTable,"CT","","one")# as unit
									FROM
										#unitsCodeTable#
									ORDER BY
										#replace(unitsCodeTable,"CT","","one")#
								</cfquery>
								<select class="data-entry-select" id="att_units#i#" name="attribute_units">
									<option value=""></option>
									<cfloop query="getUnitsCodeTable">
										<option value="#getUnitsCodeTable.unit#" <cfif getUnitsCodeTable.unit EQ getAttributes.attribute_units>selected</cfif>>#unit#</option>
									</cfloop>
								</select>
							<cfelse>
								<!--- if no code table for units, use a text input, but disable it --->
								<cfif len(attribute_units) EQ 0>
									<input type="text" class="data-entry-input" id="att_units#i#" name="attribute_units" value="" disabled>
								<cfelse>
									<!--- but if there is a value, which there shouldn't be, failover and use a text input --->
									<input type="text" class="data-entry-input" id="att_units#i#" name="attribute_units" value="#attribute_units#">
								</cfif>
							</cfif>
						</div>
						<div class="col-12 col-md-2 mt-1 pb-2">
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
						<div class="col-12 col-md-2 mt-1 pb-2">
							<label class="data-entry-label">Determined Date</label>
							<input type="text" class="data-entry-input" id="att_date#i#" name="determined_date" value="#dateformat(determined_date,"yyyy-mm-dd")#">
						</div>
						<div class="col-12 col-md-2 mt-1 pb-2">
							<label class="data-entry-label" for="att_method#i#">Method</label>
							<input type="text" class="data-entry-input" id="att_method#i#" name="determination_method" value="#determination_method#">
						</div>
						<div class="col-12 col-md-9 mt-1 pb-2">
							<label for="att_rem" class="data-entry-label">Remarks</label>
							<input type="text" class="data-entry-input" id="att_rem#i#" name="attribute_remark" value="#attribute_remark#">
						</div>
						<div class="col-12 col-md-3 mt-1 pt-3">
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
					</div>
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
 getEditLocalityHTML returns the HTML for the locality and collecting event edit form.
 @param collection_object_id the collection object id to obtain the collecting event and 
  locality for editing
 @return a JSON object containing the HTML for the locality/collecting event edit form
--->
<cffunction name="getEditLocalityHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfthread name="getEditLocalityThread"> 
		<cfoutput>
			<cftry>
				<cfif not isdefined("collection_object_id") or not isnumeric(collection_object_id)>
					<cfthrow message="No or uninterpretable collection_object_id was provided.">
				</cfif>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<cfset oneOfUs = 1>
					<cfelse>
					<cfset oneOfUs = 0>
				</cfif>
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
	
				<cfquery name="getLoc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT
						cataloged_item.collection_object_id as collection_object_id,
						cataloged_item.cat_num,
						collection.collection_cde,
						collection.institution_acronym,
						cataloged_item.accn_id,
						collection.collection,
						identification.scientific_name,
						identification.identification_remarks,
						identification.identification_id,
						identification.made_date,
						identification.nature_of_id,
						collecting_event.collecting_event_id,
						collecting_event.began_date,
						collecting_event.ended_date,
						collecting_event.verbatim_date,
						collecting_event.startDayOfYear,
						collecting_event.endDayOfYear,
						collecting_event.habitat_desc,
						collecting_event.coll_event_remarks,
						collecting_event.verbatimelevation,
						collecting_event.verbatimdepth,
						locality.locality_id,
						locality.minimum_elevation,
						locality.maximum_elevation,
						locality.orig_elev_units,
						locality.spec_locality,
						locality.section_part,
						locality.section,
						locality.township,
						locality.township_direction,
						locality.range,
						locality.range_direction,
						decode(accepted_lat_long.orig_lat_long_units,
							'decimal degrees',to_char(accepted_lat_long.dec_lat) || '&deg; ',
							'deg. min. sec.', to_char(accepted_lat_long.lat_deg) || '&deg; ' ||
							to_char(accepted_lat_long.lat_min) || '&acute; ' ||
							decode(accepted_lat_long.lat_sec, null, '', to_char(accepted_lat_long.lat_sec) || '&acute;&acute; ') || accepted_lat_long.lat_dir,
							'degrees dec. minutes', to_char(accepted_lat_long.lat_deg) || '&deg; ' ||
							to_char(accepted_lat_long.dec_lat_min) || '&acute; ' || accepted_lat_long.lat_dir
						) constructedLatitude,
						decode(accepted_lat_long.orig_lat_long_units,
							'decimal degrees',to_char(accepted_lat_long.dec_long) || '&deg;',
							'deg. min. sec.', to_char(accepted_lat_long.long_deg) || '&deg; ' ||
								to_char(accepted_lat_long.long_min) || '&acute; ' ||
								decode(accepted_lat_long.long_sec, null, '', to_char(accepted_lat_long.long_sec) || '&acute;&acute; ') || accepted_lat_long.long_dir,
							'degrees dec. minutes', to_char(accepted_lat_long.long_deg) || '&deg; ' ||
								to_char(accepted_lat_long.dec_long_min) || '&acute; ' || accepted_lat_long.long_dir
						) constructedLongitude,
						locality.sovereign_nation,
						locality.nogeorefbecause,
						locality.curated_fg,
						collecting_event.verbatimcoordinates,
						collecting_event.verbatimlatitude,
						collecting_event.verbatimlongitude,
						collecting_event.verbatimcoordinatesystem,
						collecting_event.verbatimSRS,
						collecting_event.date_determined_by_agent_id,
						collecting_event.verbatim_habitat,
						collecting_event.verbatim_collectors,
						collecting_event.verbatim_field_numbers,
						accepted_lat_long.lat_long_id,
						accepted_lat_long.orig_lat_long_units,
						latLongAgnt.agent_name coordinate_determiner,
						geog_auth_rec.geog_auth_rec_id,
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
						locality.locality_remarks,
						verbatim_locality,
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
						cataloged_item
						join collection on cataloged_item.collection_id = collection.collection_id
						join identification on cataloged_item.collection_object_id = identification.collection_object_id AND identification.accepted_id_fg = 1
						join collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id
						join locality on collecting_event.locality_id = locality.locality_id
						left join accepted_lat_long on locality.locality_id = accepted_lat_long.locality_id
						left join preferred_agent_name latLongAgnt on accepted_lat_long.determined_by_agent_id = latLongAgnt.agent_id
						join geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
						join coll_object on cataloged_item.collection_object_id = coll_object.collection_object_id
						left join coll_object_remark on coll_object.collection_object_id = coll_object_remark.collection_object_id
						join preferred_agent_name enteredPerson on coll_object.entered_person_id = enteredPerson.agent_id
						left join preferred_agent_name editedPerson on coll_object.last_edited_person_id = editedPerson.agent_id
						join accn on cataloged_item.accn_id = accn.transaction_id
						left join trans on accn.transaction_id = trans.transaction_id
						join specimen_part on cataloged_item.collection_object_id = specimen_part.derived_from_cat_item
					WHERE
						cataloged_item.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
				</cfquery>
				<!--- check for a current georeference --->
				<cfquery name="getCurrentGeoreference" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT 
						lat_long_id
					FROM
						lat_long
					WHERE
						locality_id = <cfqueryparam value="#getLoc.locality_id#" cfsqltype="CF_SQL_DECIMAL">
						AND
						accepted_lat_long_fg = 1
				</cfquery>
				<cfquery name="getGeology" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT
						GEOLOGY_ATTRIBUTE_ID,
						GEOLOGY_ATTRIBUTE,
						GEO_ATT_VALUE,
						GEO_ATT_DETERMINER_ID,
						geo_att_determiner,
						GEO_ATT_DETERMINED_DATE,
						GEO_ATT_DETERMINED_METHOD,
						GEO_ATT_REMARK
					FROM
						spec_with_loc
					WHERE
						collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#"> and
						GEOLOGY_ATTRIBUTE is not null
					GROUP BY
						GEOLOGY_ATTRIBUTE_ID,
						GEOLOGY_ATTRIBUTE,
						GEO_ATT_VALUE,
						GEO_ATT_DETERMINER_ID,
						geo_att_determiner,
						GEO_ATT_DETERMINED_DATE,
						GEO_ATT_DETERMINED_METHOD,
						GEO_ATT_REMARK
				</cfquery>
	
				<!--- find what elements are shared with other specimens, use data source that spans VPNs to obtain correct counts despite visibility to user --->
				<cfquery name="cecount" datasource="uam_god">
					select count(collection_object_id) ct from cataloged_item
					where collecting_event_id = <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value = "#getLoc.collecting_event_id#">
				</cfquery>
				<cfquery name="loccount" datasource="uam_god">
					select count(ci.collection_object_id) ct from cataloged_item ci
					left join collecting_event on ci.collecting_event_id = collecting_event.collecting_event_id
					where collecting_event.locality_id = <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value = "#getLoc.locality_id#">
				</cfquery>
				<cfquery name="sharedHigherGeogCount" datasource="uam_god">
					select count(cataloged_item.collection_object_id) as ct
					FROM cataloged_item
						JOIN collecting_event ON cataloged_item.collecting_event_id = collecting_event.collecting_event_id
						JOIN locality ON collecting_event.locality_id = locality.locality_id
					WHERE
						geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getLoc.geog_auth_rec_id#">
				</cfquery>
	
				<div class="row mx-0">
					<cfset guid = "#getLoc.institution_acronym#:#getLoc.collection_cde#:#getLoc.cat_num#">
					<div class="col-12 px-0 pt-1">
						<h2 class="h2 float-left">Edit Collecting Event, Locality, Higher Geography for #guid#</h2>
						<button id="backToSpecimen1" class="btn btn-xs btn-secondary float-right my-3" onclick="closeLocalityInPage();">Back to Specimen</button>
					</div>
					<cfset splitToSave = true>
					<cfif loccount.ct eq 1 and cecount.ct eq 1>
						<cfset splitToSave = false>
					</cfif>
					<script>
						function changeMadeInLocForm() { 
							// indicate that a change has been made in the locality form
							$('##locFormOutput').text('Unsaved changes');
							$('##locFormOutput').addClass('text-danger');
							$("##backToSpecimen1").html("Back to Specimen without saving changes");
							$("##backToSpecimen2").html("Back to Specimen without saving changes");
							$("##splitAndSaveButton").removeAttr("disabled");
							$("##launchCollEventPickerButtonFromFormButton").prop('disabled', true);
						}
						function submitLocForm() {
							console.log("submitLocForm");


							// validate the form
							if ($('##locForm')[0].checkValidity() === false) {
								// If the form is invalid, show validation messages
								$('##locForm')[0].reportValidity();
								setFeedbackControlState("locFormOutput","error")
								return;
							}
							// gather the geology data from the table
							$('##geologyTableSection').show(); // ensure the table is open so data will be aggregated
							var geologyData = aggregateGeologyTable();
							console.log(geologyData);
							// save the geology data to a single input submitted as a single known argument 
							$("##geology_data").val(encodeURIComponent(JSON.stringify(geologyData)));

							// gather the collecting event numbers from the table
							$('##collectingEventNumbersTableSection').show(); // ensure the table is open so data will be aggregated
							var collEventNumberData = aggregateCollectingEventNumbersTable();
							console.log(collEventNumberData);
							// save the collecting event numbers to a single input submitted as a single known argument
							$("##coll_event_numbers_data").val(encodeURIComponent(JSON.stringify(collEventNumberData)));

	
							// submit the form
							// ajax submit the form to localities/component/functions.cfc
							setFeedbackControlState("locFormOutput","saving")
							$.ajax({
								url: '/localities/component/combined.cfc',
								type: 'POST',
								data: $('##locForm').serialize(),
								dataType: 'json',
								success: function(response) {
									if (response[0].status === "saved") {
										setFeedbackControlState("locFormOutput","saved")
										closeLocalityInPage();
										reloadLocality();
									} else {
										setFeedbackControlState("locFormOutput","error")
									}
								},
								error: function(xhr, status, error) {
									setFeedbackControlState("locFormOutput","error")
									handleFail(xhr,status,error,"saving locality.");
								}
							});
						}
						$(document).ready(function() {
							// bind submit handler to the form
							$('##locForm').submit(function(event) {
								event.preventDefault();
								submitLocForm();
							});
						});
					</script>
					<form id="locForm" name="locForm" method="post" class="row border p-1 m-1 bg-light">
						<cfif splitToSave>	
							<input type="hidden" name="action" id="action" value="splitAndSave">
						<cfelse>
							<input type="hidden" name="action" id="action" value="saveCurrent">
						</cfif>
						<input type="hidden" name="collection_object_id" value="#collection_object_id#">
						<input type="hidden" name="returnformat" value="json">
						<input type="hidden" name="method" value="handleCombinedEditForm">
						<input type="hidden" name="locality_id" value="#getLoc.locality_id#">
						<input type="hidden" name="collecting_event_id" value="#getLoc.collecting_event_id#">
						<input type="hidden" name="geology_data" id="geology_data" value="">
						<input type="hidden" name="coll_event_numbers_data" id="coll_event_numbers_data" value="">
	
						<!--- higher geography --->
						<div class="col-12 px-2 form-row">
	
							<!--- describe action this form will take --->
							<cfif cecount.ct GT 1 OR loccount.ct GT 1>
								<h3 class="h3">
									<cfset separator = "">
									<cfif cecount.ct GT 1>
										Collecting Event is <span class="text-danger">Shared with #cecount.ct# other specimens</span> 
										<cfset separator = " ; ">
									</cfif>
									<cfif loccount.ct GT 1>
										#separator#Locality is <span class="text-danger">Shared with #loccount.ct# other specimens</span>
									</cfif>
								</h3>
								<p class="font-italic text-danger">Note: Making changes to data in this form will make a new locality record for this specimen record. It will split from the shared locality.</p>
							<cfelse>
								<p class="font-italic text-success">The collecting event and locality are used only by this specimen.</p>
							</cfif>
	
							<!--- Display of higher geography --->
	
							<cfquery name="getGeography" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								SELECT 
									geog_auth_rec_id,
									continent_ocean,
									country,
									state_prov,
									county,
									quad,
									feature,
									island,
									island_group,
									sea,
									valid_catalog_term_fg,
									source_authority,
									higher_geog,
									ocean_region,
									ocean_subregion,
									water_feature,
									wkt_polygon,
									highergeographyid_guid_type,
									highergeographyid,
									curated_fg, 
									management_remarks
								FROM 
									geog_auth_rec
								WHERE
									geog_auth_rec.geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getLoc.geog_auth_rec_id#">
							</cfquery>
							<cfset fieldLabels = [
								{field: "continent_ocean", label: "Continent/Ocean"},
								{field: "ocean_region", label: "Ocean Region"},
								{field: "ocean_subregion", label: "Ocean Subregion"},
								{field: "sea", label: "Sea"},
								{field: "water_feature", label: "Water Feature"},
								{field: "island_group", label: "Island Group"},
								{field: "island", label: "Island"},
								{field: "country", label: "Country"},
								{field: "state_prov", label: "State/Province"},
								{field: "county", label: "County"},
								{field: "feature", label: "Feature"},
								{field: "quad", label: "Quad"},
								{field: "source_authority", label: "Source Authority"}
							]>
	
							<cfloop query="getGeography">
								<div class="col-12 px-0 py-1">
									<h3 class="h3">
										Higher Geography
										<cfif len(session.roles) gt 0 and FindNoCase("manage_geography",session.roles) NEQ 0>
											<a href="/localities/HigherGeography.cfm?geog_auth_rec_id=#getLoc.geog_auth_rec_id#" class="btn btn-xs btn-warning" target="_blank"> Edit Higher Geography</a>
										</cfif>
									</h3>
									<span class="font-weight-lessbold" id="higherGeographySpan">#getGeography.higher_geog#</span>
									<input type="text" class="data-entry-input reqdClr" id="higherGeographyInput" name="higher_geog" value="#getGeography.higher_geog#" style="display: none;">
									<input type="hidden" name="geog_auth_rec_id" id="geog_auth_rec_id" value="#getGeography.geog_auth_rec_id#">
									<input type="button" value="Change" class="btn btn-xs btn-secondary mr-2" id="changeGeogButton">
									<input type="button" value="Details" class="btn btn-xs btn-info mr-2" id="showGeogButton">
									<a href="/localities/viewHigherGeography.cfm?geog_auth_rec_id=#getLoc.geog_auth_rec_id#" class="btn btn-xs btn-secondary" target="_blank"> View </a>
								</div>
								<script>
									$("##changeGeogButton").click(function() {
										// Hide the span and show the input field
										$("##higherGeographySpan").hide();
										$("##higherGeographyInput").show();
										$("##changeGeogButton").hide();
									});
									$("##showGeogButton").click(function() {
										// Toggle the visibility of the higher geography details
										$("##higherGeographyDetailsDiv").toggle();
										// Change button text based on visibility
										if ($("##higherGeographyDetailsDiv").is(":visible")) {
											$("##showGeogButton").val("Hide Details");
										} else {
											$("##showGeogButton").val("Details");
										}
									});
									// make higher geography inputs into an autocomplete
									$(document).ready(function() {
										makeHigherGeogAutocomplete("higherGeographyInput","geog_auth_rec_id");
									});
								</script>
								<div class="col-12 px-2 pb-1" id="higherGeographyDetailsDiv" style="display: none;">
	 							   <ul class="list-unstyled sd small95 row mx-0 px-0 py-1 mb-0">
										<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Higher Geography:</li>
										<li class="list-group-item col-7 col-xl-8 px-0">#getGeography.higher_geog#</li>
										<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Shared with:</li>
										<li class="list-group-item col-7 col-xl-8 px-0">#sharedHigherGeogCount.ct# cataloged items</li>
		 							   <cfif getGeography.valid_catalog_term_fg EQ "1">
											<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Valid for Data Entry:</li>
											<li class="list-group-item col-7 col-xl-8 px-0">Yes</li>
										</cfif>
										<cfif getGeography.curated_fg EQ "1">
											<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Vetted:</li>
											<li class="list-group-item col-7 col-xl-8 px-0">Yes</li>
										</cfif>
										<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_geography")>
											<cfif len(getGeography.management_remarks) GT 0>
												<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Management Remarks:</li>
												<li class="list-group-item col-7 col-xl-8 px-0">#getGeography.management_remarks#</li>
											</cfif>
										</cfif>
				
										<!--- Loop through fields and display if they have values --->
										<cfloop array="#fieldLabels#" index="fieldInfo">
											<cfset fieldValue = getGeography[fieldInfo.field][currentRow]>
		   								<cfif len(fieldValue) gt 0>
												<!--- Special handling for continent_ocean label --->
												<cfif fieldInfo.field EQ "continent_ocean">
													<cfif find('Ocean', fieldValue) GT 0>
														<cfset displayLabel = "Ocean">
													<cfelse>
														<cfset displayLabel = "Continent">
													</cfif>
												<cfelse>
													<cfset displayLabel = fieldInfo.label>
												</cfif>
												<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">#displayLabel#:</li>
												<li class="list-group-item col-7 col-xl-8 px-0">#fieldValue#</li>
											</cfif>
										</cfloop>
										<cfif len(getGeography.wkt_polygon) gt 0>
											<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Has Polygon to show on map:</li>
											<li class="list-group-item col-7 col-xl-8 px-0">Yes</li>
										</cfif>
										<cfif len(getGeography.highergeographyid) GT 0>
											<cfset geogLink = getGuidLink(guid=#getGeography.highergeographyid#,guid_type=#getGeography.highergeographyid_guid_type#)>
											<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Higher Geography ID:</li>
											<li class="list-group-item col-7 col-xl-8 px-0">#getGeography.highergeographyid# #geogLink#</li>
										</cfif>
									</ul>
								</div>
							</cfloop>
	
						</div>
	
						<!--- locality --->
						<div class="col-12 float-left px-0">
							<h2 class="h3">
								Locality
								<span class="pl-2">
									<cfif loccount.ct eq 1>
										<cfset shared_loc= "">
										<cfset followText = "(unique to this specimen)">
									<cfelse>
										<cfset shared_loc= "Shared">
										<cfset followText = "(shared_loc with #loccount.ct# specimens)">
									</cfif>
									<a class="btn btn-xs btn-info" href="/localities/viewLocality.cfm?locality_id=#getLoc.locality_id#" target="_blank">View #shared_loc# Locality</a>
									<a class="btn btn-xs btn-warning" href="/localities/Locality.cfm?locality_id=#getLoc.locality_id#" target="_blank">Edit #shared_loc# Locality</a>
									#followText#
								</span>
							</h2>
							<div class="form-row mx-0 mb-0 border-bottom p-2">
								<div class="col-12 mb-2 mt-0">
									<label class="data-entry-label" for="spec_locality">
										Specific Locality
									</label>
									<input type="text" name="spec_locality" id="spec_locality" class="data-entry-input reqdClr" value="#encodeForHTML(getLoc.spec_locality)#" required>
								</div>
								
								<div class="col-12 col-md-5 py-1 mt-0">
									<label class="data-entry-label" for="sovereign_nation">Sovereign Nation</label>
									<select name="sovereign_nation" id="sovereign_nation" size="1" class="data-entry-select reqdClr">
										<cfloop query="ctSovereignNation">
											<cfif isdefined("getLoc.sovereign_nation") AND ctSovereignNation.sovereign_nation is getLoc.sovereign_nation>
												<cfset selected="selected">
											<cfelse>
												<cfset selected="">
											</cfif>
											<option #selected# value="#ctSovereignNation.sovereign_nation#">#ctSovereignNation.sovereign_nation#</option>
										</cfloop>
									</select>
								</div>
	
								<div class="col-12 col-md-2 py-1 mt-0">
									<label class="data-entry-label" for="curated_fg">Vetted</label>
									<select name="curated_fg" id="curated_fg" size="1" class="data-entry-select reqdClr">
										<cfif not isDefined("getLoc.curated_fg") OR (isdefined("getLoc.curated_fg") AND getLoc.curated_fg NEQ 1) >
											<cfset selected="selected">
										<cfelse>
											<cfset selected="">
										</cfif>
										<option value="0" #selected#>No</option>
										<cfif isdefined("getLoc.curated_fg") AND getLoc.curated_fg EQ 1 >
											<cfset selected="selected">
										<cfelse>
											<cfset selected="">
										</cfif>
										<option value="1" #selected#>Yes (*)</option>
									</select>
								</div>
								
								<div class="col-12 col-md-5 py-1 mt-0">
									<label class="data-entry-label" for="NoGeorefBecause">
										Not Georeferenced Because
										<i class="fas fa-info-circle" onClick="getMCZDocs('Not_Georeferenced_Because')" aria-label="help link with suggested entries for why no georeference was added"></i>
									</label>
									<cfset disabled = "">
									<cfif getCurrentGeoreference.recordcount GT 0>
										<!--- If there is a georeference then NoGeorefBecause should not be editable if it has no value --->
										<cfif len(getLoc.NoGeorefBecause) is 0>
											<cfset disabled = "disabled">
										</cfif>
									</cfif>
									<input type="text" name="NoGeorefBecause" id="NoGeorefBecause" class="data-entry-input" value="#encodeForHTML(getLoc.NoGeorefBecause)#" #disabled#>
									<cfif len(getLoc.orig_lat_long_units) gt 0 AND len(getLoc.NoGeorefBecause) gt 0>
										<div class="text-danger small mt-1">NotGeorefBecause should be NULL for localities with georeferences. Please review this locality and update accordingly.</div>
									<cfelseif len(getLoc.orig_lat_long_units) is 0 AND len(getLoc.NoGeorefBecause) is 0>
										<div class="text-danger small mt-1">Please georeference this locality or enter a value for NoGeorefBecause.</div>
									</cfif>
								</div>
							
								<div class="col-12 col-md-2 py-1 mt-0">
									<label class="data-entry-label" for="minimum_elevation"><span class="font-weight-lessbold">Elevation:</span> Minimum</label>
									<input type="text" name="minimum_elevation" id="minimum_elevation" class="data-entry-input" value="#encodeForHTML(getLoc.minimum_elevation)#">
								</div>
								
								<div class="col-12 col-md-2 py-1 mt-0">
									<label class="data-entry-label" for="maximum_elevation">Maximum Elevation</label>
									<input type="text" name="maximum_elevation" id="maximum_elevation" class="data-entry-input" value="#encodeForHTML(getLoc.maximum_elevation)#">
								</div>
								
								<div class="col-12 col-md-2 py-1 mt-0">
									<label class="data-entry-label" for="orig_elev_units">Elevation Units</label>
									<select name="orig_elev_units" id="orig_elev_units" size="1" class="data-entry-select">
										<option value=""></option>
										<cfloop query="ctElevUnit">
											<cfif ctElevUnit.orig_elev_units is getLoc.orig_elev_units>
												<cfset selected="selected">
											<cfelse>
												<cfset selected="">
											</cfif>
											<option #selected# value="#ctElevUnit.orig_elev_units#">#ctElevUnit.orig_elev_units#</option>
										</cfloop>
									</select>
								</div>
								
								<div class="col-12 col-md-2 py-1 mt-0">
									<label class="data-entry-label" for="min_depth"><span class="font-weight-lessbold">Depth:</span> Minimum</label>
									<input type="text" name="min_depth" id="min_depth" class="data-entry-input" value="#encodeForHTML(getLoc.min_depth)#">
								</div>
								
								<div class="col-12 col-md-2 py-1 mt-0">
									<label class="data-entry-label" for="max_depth">Maximum Depth</label>
									<input type="text" name="max_depth" id="max_depth" class="data-entry-input" value="#encodeForHTML(getLoc.max_depth)#">
								</div>
								
								<div class="col-12 col-md-2 py-1 mt-0">
									<label class="data-entry-label" for="depth_units">Depth Units</label>
									<select name="depth_units" id="depth_units" size="1" class="data-entry-select">
										<option value=""></option>
										<cfloop query="ctDepthUnit">
											<cfif ctDepthUnit.depth_units is getLoc.depth_units>
												<cfset selected="selected">
											<cfelse>
												<cfset selected="">
											</cfif>
											<option #selected# value="#ctDepthUnit.depth_units#">#ctDepthUnit.depth_units#</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 form-row border rounded m-1 p-1">
									<!--- PLSS coordinates --->
									<div class="col-12 col-md-2 py-1">
										<label class="data-entry-label" for="section_part"><span class="font-weight-lessbold">PLSS: </span> Section Part</label>
										<input type="text" name="section_part" id="section_part" class="data-entry-input" value="#encodeForHTML(getLoc.section_part)#" placeholder="NE 1/4" >
									</div>
									<div class="col-12 col-md-2 py-1">
										<label class="data-entry-label" for="section">Section</label>
										<input type="text" name="section" id="section" class="data-entry-input" value="#encodeForHTML(getLoc.section)#" pattern="[0-3]{0,1}[0-9]{0,1}" >
									</div>
									<div class="col-12 col-md-2 py-1">
										<label class="data-entry-label" for="township">Township</label>
										<input type="text" name="township" id="township" class="data-entry-input" value="#encodeForHTML(getLoc.township)#" pattern="[0-9]+" >
									</div>
									<div class="col-12 col-md-2 py-1">
										<label class="data-entry-label" for="township_direction">Township Direction</label>
										<input type="text" name="township_direction" id="township_direction" class="data-entry-input" value="#encodeForHTML(getLoc.township_direction)#" >
									</div>
									<div class="col-12 col-md-2 py-1">
										<label class="data-entry-label" for="range">Range</label>
										<input type="text" name="range" id="range" class="data-entry-input" value="#encodeForHTML(getLoc.range)#" pattern="[0-9]+">
									</div>
									<div class="col-12 col-md-2 py-1">
										<label class="data-entry-label" for="range_direction">Range Direction</label>
										<input type="text" name="range_direction" id="range_direction" class="data-entry-input" value="#encodeForHTML(getLoc.range_direction)#" >
									</div>
								</div>
								<div class="col-12 py-1">
									<label class="data-entry-label" for="locality_remarks">
										Locality Remarks 
										(<span id="length_locality_remarks"></span>)
									</label>
									<textarea name="locality_remarks" id="locality_remarks" 
										onkeyup="countCharsLeft('locality_remarks', 4000, 'length_locality_remarks');"
										class="form-control form-control-sm w-100 autogrow mb-1" rows="2">#encodeForHtml(getLoc.locality_remarks)#</textarea>
									<script>
										// Bind input to autogrow function on key up, and trigger autogrow to fit text
										$(document).ready(function() { 
											$("##locality_remarks").keyup(autogrow);  
											$('##locality_remarks').keyup();
										});
									</script>
								</div>
							</div>
						</div>
	
						<!--- collecting event --->
						<div class="col-12 px-0">
							<h2 class="h3 mt-3">
								Collecting Event
								<span class="pl-2">
										<cfif cecount.ct eq 1>
											<cfset shared= "">
											<cfset followText = "(unique to this specimen)">
										<cfelse>
											<cfset shared= "Shared">
											<cfset followText = "(shared with #cecount.ct# specimens)">
										</cfif>
										<a class="btn btn-xs btn-info" href="/localities/viewCollectingEvent.cfm?collecting_event_id=#getLoc.collecting_event_id#" target="_blank">View #shared# Collecting Event</a>
										<button type="button" class="btn btn-xs btn-warning" id="launchCollEventPickerButtonFromFormButton"
											onclick=" closeLocalityInPage();  launchCollectingEventDialog(); ">Pick Different Collecting Event</button>
										<a class="btn btn-xs btn-warning" href="/localities/CollectingEvent.cfm?collecting_event_id=#getLoc.collecting_event_id#" target="_blank">Edit #shared# Collecting Event</a>
										#followText#
								</span>
							</h2>
							<div class="form-row mx-0 mb-0 border-bottom p-2">
								<div class="col-12 mb-2 mt-0">
									<label class="data-entry-label" for="verbatim_locality">
										Verbatim Locality
									</label>
									<input type="text" name="verbatim_locality" id="verbatim_locality" class="data-entry-input reqdClr" value="#encodeForHTML(getLoc.verbatim_locality)#" required>
								</div>
								
								<div class="col-12 col-md-3 mb-2 mt-0">
									<label class="data-entry-label" for="verbatim_date">Verbatim Date</label>
									<input type="text" name="verbatim_date" id="verbatim_date" class="data-entry-input reqdClr" value="#encodeForHTML(getLoc.verbatim_date)#" required>
								</div>
								
								<div class="col-12 col-md-3 mb-2 mt-0">
									<label class="data-entry-label" for="began_date">Began Date/Time</label>
									<input type="text" name="began_date" id="began_date" class="data-entry-input reqdClr" value="#encodeForHTML(getLoc.began_date)#" required>
								</div>
								
								<div class="col-12 col-md-3 mb-2 mt-0">
									<label class="data-entry-label" for="ended_date">Ended Date/Time</label>
									<input type="text" name="ended_date" id="ended_date" class="data-entry-input reqdClr" value="#encodeForHTML(getLoc.ended_date)#" required>
								</div>
								
								<div class="col-12 col-md-3 mb-2 mt-0">
									<label class="data-entry-label" for="collecting_time">Collecting Time</label>
									<input type="text" name="collecting_time" id="collecting_time" class="data-entry-input" value="#encodeForHTML(getLoc.collecting_time)#">
								</div>
							
								<div class="col-12 col-md-2 py-1 mt-0">
									<label class="data-entry-label" for="startDayofYear">Start Day of Year</label>
									<input type="text" name="startDayofYear" id="startDayofYear" class="data-entry-input" value="#encodeForHTML(getLoc.startdayofyear)#">
								</div>
								
								<div class="col-12 col-md-2 py-1 mt-0">
									<label class="data-entry-label" for="endDayofYear">End Day of Year</label>
									<input type="text" name="endDayofYear" id="endDayofYear" class="data-entry-input" value="#encodeForHTML(getLoc.enddayofyear)#">
								</div>
								
								<div class="col-12 col-md-2 py-1 mt-0">
									<label for="date_determined_by_agent_id" class="data-entry-label">Event Date Determined By</label>
									<cfif not isDefined("getLoc.date_determined_by_agent_id") OR len(getLoc.date_determined_by_agent_id) EQ 0>
										<cfset date_determined_by_agent_id = "">
										<cfset agent = "">
									<cfelse>
										<cfset agent = "">
										<cfquery name="determiner" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
											SELECT
												agent_name
											FROM
												preferred_agent_name
											WHERE
												agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getLoc.date_determined_by_agent_id#">
										</cfquery>
										<cfloop query="determiner">
											<cfset agent = "#determiner.agent_name#">
										</cfloop>
									</cfif>
									<input type="hidden" name="date_determined_by_agent_id" id="date_determined_by_agent_id" value="#encodeForHtml(getLoc.date_determined_by_agent_id)#">
									<input type="text" name="date_determined_by_agent" id="date_determined_by_agent" class="data-entry-input" value="#agent#">
									<script>
										$(document).ready(function() { 
											makeAgentAutocompleteMeta("date_determined_by_agent", "date_determined_by_agent_id");
										});
									</script>
								</div>
								
								<div class="col-12 col-md-3 py-1 mt-0">
									<label class="data-entry-label" for="collecting_source">Collecting Source</label>
									<select name="collecting_source" id="collecting_source" size="1" class="data-entry-select reqdClr">
										<option value=""></option>
										<cfloop query="ctcollecting_source">
											<cfif ctcollecting_source.collecting_source is getLoc.collecting_source>
												<cfset selected="selected">
											<cfelse>
												<cfset selected="">
											</cfif>
											<option #selected# value="#ctcollecting_source.collecting_source#">#ctcollecting_source.collecting_source#</option>
										</cfloop>
									</select>
								</div>
	
								<div class="col-12 col-md-3 py-1 mt-0">
									<label class="data-entry-label" for="fish_field_number">Fish Field Number (Ich only)</label>
									<input type="text" name="fish_field_number" id="fish_field_number" class="data-entry-input" value="#encodeForHTML(getLoc.fish_field_number)#">
								</div>
								
								<div class="col-12 py-1 mt-0">
									<label class="data-entry-label" for="collecting_method">Collecting Method</label>
									<input type="text" name="collecting_method" id="collecting_method" class="data-entry-input" value="#encodeForHTML(getLoc.collecting_method)#">
								</div>
							
								<div class="col-12 py-1">
									<label class="data-entry-label" for="habitat_desc">Habitat</label>
									<input type="text" name="habitat_desc" id="habitat_desc" class="data-entry-input" value="#encodeForHTML(getLoc.habitat_desc)#">
								</div>
								
	
								<div class="col-12 col-md-3 py-1 px-0">
									<label class="data-entry-label px-2 " for="verbatimdepth">Verbatim Depth</label>
									<input type="text" name="verbatimdepth" id="verbatimdepth" value="#getLoc.verbatimdepth#" class="data-entry-input">
								</div>
								<div class="col-12 col-md-3 py-1 px-0">
									<label class="data-entry-label px-2 " for="verbatimelevation">Verbatim Elevation</label>
									<input type="text" name="verbatimelevation" id="verbatimelevation" value="#getLoc.verbatimelevation#" class="data-entry-input">
								</div>
								<div class="col-12 col-md-3 py-1 px-0">
									<label class="data-entry-label px-2 " for="verbatimLatitude">Verbatim Latitude</label>
									<input type="text" name="verbatimLatitude" id="verbatimLatitude" value="#getLoc.verbatimLatitude#" class="data-entry-input">
								</div>
								<div class="col-12 col-md-3 py-1 px-0">
									<label class="data-entry-label px-2 " for="verbatimLongitude">Verbatim Longitude</label>
									<input type="text" name="verbatimLongitude" id="verbatimLongitude" value="#getLoc.verbatimLongitude#" class="data-entry-input">
								</div>
								<div class="col-12 col-md-3 py-1 px-0">
									<label class="data-entry-label px-2 " for="verbatimCoordinates">Verbatim Coordinates</label>
									<input type="text" name="verbatimCoordinates" id="verbatimCoordinates" value="#getLoc.verbatimCoordinates#" class="data-entry-input">
								</div>
								<div class="col-12 col-md-3 py-1 px-0">
									<label class="data-entry-label px-2 " for="verbatimCoordinateSystem">Verbatim Coordinate System</label>
									<input type="text" name="verbatimCoordinateSystem" id="verbatimCoordinateSystem" value="#getLoc.verbatimCoordinateSystem#" class="data-entry-input">
								</div>
								<div class="col-12 col-md-3 py-1 px-0">
									<label class="data-entry-label px-2 " for="verbatimSRS"">Verbatim SRS (ellipsoid model/datum)</label>
									<input type="text" name="verbatimSRS" id="verbatimSRS" value="#getLoc.verbatimSRS#" class="data-entry-input">
								</div>
								<!--- Additional verbatim fields --->
								<div class="col-12 col-md-3 py-1 px-0">
									<label class="data-entry-label px-2 " for="verbatim_habitat"">Verbatim Habitat</label>
									<input type="text" name="verbatim_habitat" id="verbatim_habitat" value="#getLoc.verbatim_habitat#" class="data-entry-input">
								</div>
								<div class="col-12 col-md-3 py-1 px-0">
									<label class="data-entry-label px-2 " for="verbatim_collectors"">Verbatim Collectors</label>
									<input type="text" name="verbatim_collectors" id="verbatim_collectors" value="#getLoc.verbatim_collectors#" class="data-entry-input">
								</div>
								<div class="col-12 col-md-3 py-1 px-0">
									<label class="data-entry-label px-2 " for="verbatim_field_numbers"">Verbatim Field Numbers</label>
									<input type="text" name="verbatim_field_numbers" id="verbatim_field_numbers" value="#getLoc.verbatim_field_numbers#" class="data-entry-input">
								</div>
								<div class="col-12 col-md-6 mb-2">
									<label for="valid_distribution_fg" class="data-entry-label">Valid Distribution</label>
									<cfif not isDefined("variables.valid_distribution_fg")>
										<cfset variables.valid_distribution_fg = "1">
									</cfif>
									<select name="valid_distribution_fg" id="valid_distribution_fg" class="data-entry-select reqdClr" required>
										<cfif variables.valid_distribution_fg EQ "1"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="1" #selected#>Yes, material from this event represents distribution in the wild</option>
										<cfif variables.valid_distribution_fg EQ "0"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="0" #selected#>No, material from this event does not represent distribution in the wild</option>
									</select>
								</div>
								<div class="col-12 py-1">
									<label class="data-entry-label" for="coll_event_remarks">
										Collecting Event Remarks
										(<span id="length_coll_event_remarks"></span>)
									</label>
									<textarea name="coll_event_remarks" id="coll_event_remarks" 
										onkeyup="countCharsLeft('coll_event_remarks', 4000, 'length_coll_event_remarks');"
										class="form-control form-control-sm w-100 autogrow mb-1" rows="2">#encodeForHtml(getLoc.coll_event_remarks)#</textarea>
									<script>
										// Bind input to autogrow function on key up, and trigger autogrow to fit text
										$(document).ready(function() { 
											$("##coll_event_remarks").keyup(autogrow);  
											$('##coll_event_remarks').keyup();
										});
									</script>
								</div>
	
							</div>
						</div>
						
						<!--- Collecting event numbers --->
						<div class="col-12 px-0 mt-2">
							<!--- Query for available number series --->
							<cfquery name="collEventNumberSeries" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								SELECT coll_event_num_series_id, number_series, pattern, remarks, collector_agent_id,
									CASE collector_agent_id WHEN null THEN '[No Agent]' ELSE mczbase.get_agentnameoftype(collector_agent_id) END as collector_agent
								FROM coll_event_num_series
								ORDER BY number_series, mczbase.get_agentnameoftype(collector_agent_id)
							</cfquery>
							
							<h3 class="h4">
								Collecting Event Numbers
								Collector/Field Numbers (identifying collecting events)
								<button type="button" class="btn btn-xs btn-secondary" id="buttonOpenEditCollectingEventNumbers">Edit</button>
							</h3>
						
							<!--- Display existing collecting event numbers --->
							<div class="form-row mx-0 mb-2">
								<div class="col-12">
									<cfquery name="colEventNumbers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										SELECT number_series,
											MCZBASE.get_agentnameoftype(collector_agent_id) as collector_agent,
											coll_event_number,
											coll_event_number_id,
											coll_event_number.coll_event_num_series_id
										FROM
											coll_event_number
											left join coll_event_num_series on coll_event_number.coll_event_num_series_id = coll_event_num_series.coll_event_num_series_id
										WHERE
											coll_event_number.collecting_event_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getLoc.collecting_event_id#">
									</cfquery>
									<ul class="mb-1">
										<cfloop query="colEventNumbers">
											<li><span id="collEventNumber_#coll_event_number_id#">#coll_event_number# (#number_series#, #collector_agent#)</span></li>
										</cfloop>
										<cfif colEventNumbers.recordcount EQ 0>
											<li class="text-muted">None.</li>
										</cfif>
									</ul>
								</div>
							</div>
						
							<script>
								$(document).ready(function() {
									$('##buttonOpenEditCollectingEventNumbers').on('click', function() {
										$('##collectingEventNumbersTableSection').show();
										$('##buttonOpenEditCollectingEventNumbers').hide();
									});
								});
							</script>
						
							<div id="collectingEventNumbersTableSection" class="col-12" style="display: none;">
								<!--- Editable Table --->
								<div class="table-responsive">
									<table class="table table-sm table-striped" id="collectingEventNumbersTable">
										<thead>
											<tr>
												<th>Number Series</th>
												<th>Collector/Agent</th>
												<th>Number</th>
												<th>Pattern</th>
												<th>Actions</th>
											</tr>
										</thead>
										<tbody id="collectingEventNumbersTableBody">
											<!--- Existing collecting event numbers --->
											<cfset rowIndex = 0>
											<cfif colEventNumbers.recordcount GT 0>
												<cfloop query="colEventNumbers">
													<cfset rowIndex = rowIndex + 1>
													<tr data-row-index="#rowIndex#">
														<td>
															<select name="coll_event_num_series_id_#rowIndex#" id="coll_event_num_series_id_#rowIndex#" class="data-entry-select reqdClr" onchange="changeCollEventNumberSeries(#rowIndex#)">
																<option value=""></option>
																<cfloop query="collEventNumberSeries">
																	<cfif collEventNumberSeries.coll_event_num_series_id EQ colEventNumbers.coll_event_num_series_id>
																		<cfset selected="selected">
																	<cfelse>
																		<cfset selected="">
																	</cfif>
																	<option value="#collEventNumberSeries.coll_event_num_series_id#" #selected#>#collEventNumberSeries.number_series#</option>
																</cfloop>
															</select>
															<input type="hidden" name="coll_event_number_id_#rowIndex#" id="coll_event_number_id_#rowIndex#" value="#colEventNumbers.coll_event_number_id#">
														</td>
														<td>
															<span id="collector_agent_#rowIndex#">#encodeForHTML(colEventNumbers.collector_agent)#</span>
														</td>
														<td>
															<input type="text" id="coll_event_number_#rowIndex#" name="coll_event_number_#rowIndex#" 
																class="data-entry-input reqdClr"
																value="#encodeForHTML(colEventNumbers.coll_event_number)#">
														</td>
														<td>
															<span id="pattern_#rowIndex#" class="text-muted small"></span>
														</td>
														<td>
															<button type="button" class="btn btn-xs btn-danger" onclick="removeCollEventNumberRow(this)" title="Remove this collecting event number">
																<i class="fas fa-times"></i>
															</button>
														</td>
													</tr>
												</cfloop>
											</cfif>
											<tr id="addCollEventNumberRow">
												<td colspan="5" class="text-center">
													<!--- Add new collecting event number button --->
													<button type="button" class="btn btn-xs btn-primary" onclick="addCollEventNumberRow()">
														<i class="fas fa-plus"></i> Add Collecting Event Number
													</button>
												</td>
											</tr>
										</tbody>
									</table>
								</div>
								<!--- Hidden field to track the number of collecting event number rows --->
								<input type="hidden" name="coll_event_number_row_count" id="coll_event_number_row_count" value="#rowIndex#">
								<!--- hidden field to accumulate collecting event numbers to delete --->
								<input type="hidden" name="coll_event_numbers_to_delete" id="coll_event_numbers_to_delete" value="">
						
								<script>
									$(document).ready(function() {
										const initialRowCount = parseInt($('##coll_event_number_row_count').val());
										for (let i = 1; i <= initialRowCount; i++) {
											updateCollEventNumberSeriesInfo(i);
										}
									});
						
									function addCollEventNumberRow() {
										$('##noCollEventNumberRow').remove();
										let currentRowCount = parseInt($('##coll_event_number_row_count').val());
										currentRowCount++;
										$('##coll_event_number_row_count').val(currentRowCount);
										const newRow = `
											<tr data-row-index="${currentRowCount}">
												<td>
													<select name="coll_event_num_series_id_${currentRowCount}" id="coll_event_num_series_id_${currentRowCount}" class="data-entry-select reqdClr" onchange="changeCollEventNumberSeries(${currentRowCount})">
														<option value=""></option>
														<cfloop query="collEventNumberSeries">
															<option value="#collEventNumberSeries.coll_event_num_series_id#">#collEventNumberSeries.number_series#</option>
														</cfloop>
													</select>
													<input type="hidden" name="coll_event_number_id_${currentRowCount}" id="coll_event_number_id_${currentRowCount}" value="">
												</td>
												<td>
													<span id="collector_agent_${currentRowCount}"></span>
												</td>
												<td>
													<input type="text" id="coll_event_number_${currentRowCount}" name="coll_event_number_${currentRowCount}" class="data-entry-input reqdClr">
												</td>
												<td>
													<span id="pattern_${currentRowCount}" class="text-muted small"></span>
												</td>
												<td>
													<button type="button" class="btn btn-xs btn-danger" onclick="removeCollEventNumberRow(this)" title="Remove this collecting event number">
														<i class="fas fa-times"></i>
													</button>
												</td>
											</tr>
										`;
										<!--- " --->
										$('##collectingEventNumbersTableBody').append(newRow);
									}
						
									function removeCollEventNumberRow(button) {
										const row = $(button).closest('tr');
										const rowIndex = row.data('row-index');
										<!--- check if the row has a coll_event_number_id, if so, add it to the delete list --->
										const collEventNumberId = $(`##coll_event_number_id_${rowIndex}`).val();
										if (collEventNumberId) {
											let deleteList = $(`##coll_event_numbers_to_delete`).val();
											if (deleteList) {
												deleteList += ",";
											}
											deleteList += collEventNumberId;
											$(`##coll_event_numbers_to_delete`).val(deleteList);
										}
										row.hide();
										if ($('##collectingEventNumbersTableBody tr:visible').length === 0) {
											$('##collectingEventNumbersTableBody').append(`
												<tr id="noCollEventNumberRow">
													<td colspan="5" class="text-muted text-center">No collecting event numbers for this collecting event.</td>
												</tr>
											`);
										}
									}
						
									function changeCollEventNumberSeries(rowIndex) {
										updateCollEventNumberSeriesInfo(rowIndex);
									}
						
									function updateCollEventNumberSeriesInfo(rowIndex) {
										const selectedSeriesId = $(`##coll_event_num_series_id_${rowIndex}`).val();
										let collectorAgent = '';
										let pattern = '';
										
										<cfloop query="collEventNumberSeries">
											if (selectedSeriesId == '#collEventNumberSeries.coll_event_num_series_id#') {
												collectorAgent = '#encodeForJavaScript(collEventNumberSeries.collector_agent)#';
												pattern = '#encodeForJavaScript(collEventNumberSeries.pattern)#';
											}
										</cfloop>
										
										$(`##collector_agent_${rowIndex}`).text(collectorAgent);
										$(`##pattern_${rowIndex}`).text(pattern);
									}
						
									function aggregateCollectingEventNumbersTable() {
										var collectingEventNumbersData = [];
										$('##collectingEventNumbersTableBody tr:visible').each(function() {
											var row = $(this);
											var rowIndex = row.data('row-index');
											var collEventNumber = row.find('input[name="coll_event_number_' + rowIndex + '"]').val();
											var seriesId = row.find('select[name="coll_event_num_series_id_' + rowIndex + '"]').val();
											if (collEventNumber && seriesId) {
												collectingEventNumbersData.push({
													coll_event_num_series_id: seriesId,
													coll_event_number: collEventNumber,
													coll_event_number_id: row.find('input[name="coll_event_number_id_' + rowIndex + '"]').val()
												});
											}
										});
										return collectingEventNumbersData;
									}
						
								</script>
							</div><!--- end collecting event numbers table section --->
						</div><!--- end collecting event numbers section --->
	
						<!--- geology attributes (on locality) --->
						<div class="col-12 px-0">
							<!--- Geological Attributes Query --->
							<cfquery name="getGeologicalAttributes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
								SELECT
									geology_attribute_id,
									ctgeology_attribute.type,
									geology_attributes.geology_attribute,
									geology_attributes.geo_att_value,
									geology_attributes.geo_att_determiner_id,
									agent_name determined_by,
									to_char(geology_attributes.geo_att_determined_date,'yyyy-mm-dd') determined_date,
									geology_attributes.geo_att_determined_method determined_method,
									geology_attributes.geo_att_remark,
									geology_attributes.previous_values,
									geology_attribute_hierarchy.usable_value_fg,
									geology_attribute_hierarchy.geology_attribute_hierarchy_id
								FROM
									geology_attributes
									JOIN ctgeology_attribute ON geology_attributes.geology_attribute = ctgeology_attribute.geology_attribute
									LEFT JOIN preferred_agent_name ON geo_att_determiner_id = agent_id
									LEFT JOIN geology_attribute_hierarchy 
										ON geology_attributes.geo_att_value = geology_attribute_hierarchy.attribute_value 
										AND geology_attributes.geology_attribute = geology_attribute_hierarchy.attribute
								WHERE 
									geology_attributes.locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getLoc.locality_id#">
								ORDER BY
									ctgeology_attribute.ordinal
							</cfquery>
							<cfquery name="ctGeologyTypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								SELECT DISTINCT type FROM ctgeology_attribute ORDER BY type
							</cfquery>
							<cfquery name="ctgeology_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								SELECT geology_attribute, type FROM ctgeology_attribute ORDER BY ordinal
							</cfquery>
							<h2 class="h3 mt-3">
								Geological Attributes
								<button type="button" class="btn btn-xs btn-secondary" id="buttonOpenEditGeologyTable">Edit</button>
							</h2>
							<!--- Display current attributes --->
							<ul>
								<cfif getGeologicalAttributes.recordcount EQ 0>
									<li id="noAttributesLI"> No geological attributes for this locality.</li>
								</cfif>
								<cfset valList = "">
								<cfset shownParentsList = "">
								<cfset separator = "">
								<cfset separator2 = "">
								<cfloop query="getGeologicalAttributes">
									<cfset valList = "#valList##separator##getGeologicalAttributes.geo_att_value#">
									<cfset separator = "|">
								</cfloop>
								<cfloop query="getGeologicalAttributes">
									<cfquery name="getParentage" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
										SELECT DISTINCT
										  connect_by_root geology_attribute_hierarchy.attribute parent_attribute,
										  connect_by_root attribute_value parent_attribute_value,
										  connect_by_root usable_value_fg
										FROM geology_attribute_hierarchy
											LEFT JOIN geology_attributes ON
												geology_attribute_hierarchy.attribute = geology_attributes.geology_attribute
												AND geology_attribute_hierarchy.attribute_value = geology_attributes.geo_att_value
										WHERE geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getGeologicalAttributes.geology_attribute_hierarchy_id#">
										CONNECT BY nocycle PRIOR geology_attribute_hierarchy_id = parent_id
									</cfquery>
									<cfset parentage="">
									<cfloop query="getParentage">
										<cfif ListContains(valList,getParentage.parent_attribute_value,"|") EQ 0 AND  ListContains(shownParentsList,getParentage.parent_attribute_value,"|") EQ 0 >
											<cfset parentage="#parentage#<li><span class='text-secondary'>#getParentage.parent_attribute#:#getParentage.parent_attribute_value#</span></li>" >
											<cfset shownParentsList = "#shownParentsList##separator2##getParentage.parent_attribute_value#">
											<cfset separator2 = "|">
										</cfif>
									</cfloop>
									#parentage#
									<li>
										<cfif len(getGeologicalAttributes.determined_method) GT 0>
											<cfset method = " Method: #getGeologicalAttributes.determined_method#">
										<cfelse>
											<cfset method = "">
										</cfif>
										<cfif len(getGeologicalAttributes.geo_att_remark) GT 0>
											<cfset remarks = " <span class='smaller-text'>Remarks: #getGeologicalAttributes.geo_att_remark#</span>">
										<cfelse>
											<cfset remarks="">
										</cfif>
										<cfif usable_value_fg EQ 1>
											<cfset marker = "*">
											<cfset spanClass = "">
										<cfelse>
											<cfset marker = "">
											<cfset spanClass = "text-danger">
										</cfif>
										<span class="#spanClass#">#geo_att_value# #marker#</span> (#geology_attribute#) #determined_by# #determined_date##method##remarks#
									</li>
								</cfloop>
							</ul>
						
							<script>
								$(document).ready(function() {
									$('##buttonOpenEditGeologyTable').on('click', function() {
										$('##geologyTableSection').show();
										$('##buttonOpenEditGeologyTable').hide();
									});
								});
							</script>
						
							<div id="geologyTableSection" class="col-12" style="display: none;">
								<!--- Editable Table --->
								<div class="table-responsive">
									<table class="table table-sm table-striped" id="geologyTable">
										<thead>
											<tr>
												<th>Type</th>
												<th>Geology Attribute</th>
												<th>Value</th>
												<th>Parents</th>
												<th>Determiner</th>
												<th>Date Determined</th>
												<th>Method</th>
												<th>Remarks<br><span class="smaller-text">(<span id="table_remark_limit">4000 max)</span></span></th>
												<th>Actions</th>
											</tr>
										</thead>
										<tbody id="geologyTableBody">
											<!--- Existing geological attributes --->
											<cfset rowIndex = 0>
											<cfif getGeologicalAttributes.recordcount GT 0>
												<cfloop query="getGeologicalAttributes">
													<cfset rowIndex = rowIndex + 1>
													<tr data-row-index="#rowIndex#">
														<td>
															<select name="attribute_type_#rowIndex#" id="attribute_type_#rowIndex#" class="data-entry-select reqdClr" onchange="changeGeoAttType(#rowIndex#)">
																<cfloop query="ctGeologyTypes">
																	<cfif ctGeologyTypes.type EQ getGeologicalAttributes.type>
																		<cfset selected="selected">
																	<cfelse>
																		<cfset selected="">
																	</cfif>
																	<option value="#ctGeologyTypes.type#" #selected#>#ctGeologyTypes.type#</option>
																</cfloop>
															</select>
															<input type="hidden" name="geology_attribute_id_#rowIndex#" id="geology_attribute_id_#rowIndex#" value="#getGeologicalAttributes.geology_attribute_id#">
															<input type="hidden" name="geology_attribute_hierarchy_id_#rowIndex#" id="geology_attribute_hierarchy_id_#rowIndex#" value="#getGeologicalAttributes.geology_attribute_hierarchy_id#">
														</td>
														<td>
															<input type="text" name="geology_attribute_#rowIndex#" id="geology_attribute_#rowIndex#" 
																class="data-entry-input" readonly
																value="#getGeologicalAttributes.geology_attribute#">
														</td>
														<td>
															<input type="text" id="geo_att_value_#rowIndex#" name="geo_att_value_#rowIndex#" 
																class="data-entry-input reqdClr"
																value="#encodeForHTML(getGeologicalAttributes.geo_att_value)#">
														</td>
														<td>
															<select id="add_parents_#rowIndex#" name="add_parents_#rowIndex#" class="data-entry-select" onchange="addParentsChange(#rowIndex#);">
																<option value="no" selected>No</option>
																<option value="yes">Yes</option>
															</select>
															<div id="parentsDiv_#rowIndex#"></div>
														</td>
														<td>
															<input type="text" id="geo_att_determiner_#rowIndex#" name="geo_att_determiner_#rowIndex#" value="#encodeForHTML(getGeologicalAttributes.determined_by)#" class="data-entry-input">
															<input type="hidden" name="geo_att_determiner_id_#rowIndex#" id="geo_att_determiner_id_#rowIndex#" value="#getGeologicalAttributes.geo_att_determiner_id#">
														</td>
														<td>
															<input type="text" id="geo_att_determined_date_#rowIndex#" name="geo_att_determined_date_#rowIndex#" value="#dateformat(getGeologicalAttributes.determined_date,'yyyy-mm-dd')#" class="data-entry-input geology-date">
														</td>
														<td>
															<input type="text" id="geo_att_determined_method_#rowIndex#" name="geo_att_determined_method_#rowIndex#" value="#encodeForHTML(getGeologicalAttributes.determined_method)#" class="data-entry-input">
														</td>
														<td>
															<textarea name="geo_att_remark_#rowIndex#" id="geo_att_remark_#rowIndex#" class="form-control form-control-sm autogrow" rows="2" onkeyup="countCharsLeft('geo_att_remark_#rowIndex#', 4000, 'length_geo_att_remark_#rowIndex#');">#encodeForHTML(getGeologicalAttributes.geo_att_remark)#</textarea>
															<br><span id="length_geo_att_remark_#rowIndex#" class="smaller-text">0 characters, 4000 left</span>
														</td>
														<td>
															<button type="button" class="btn btn-xs btn-danger" onclick="removeGeologyRow(this)" title="Remove this geological attribute">
																<i class="fas fa-times"></i>
															</button>
														</td>
													</tr>
												</cfloop>
											</cfif>
											<tr id="addGeologyRow">
												<td colspan="9" class="text-center">
													<!--- Add new geology attribute button --->
													<button type="button" class="btn btn-xs btn-primary" onclick="addGeologyRow()">
														<i class="fas fa-plus"></i> Add Geological Attribute
													</button>
												</td>
											</tr>
										</tbody>
									</table>
								</div>
								<!--- Hidden field to track the number of geology rows --->
								<input type="hidden" name="geology_row_count" id="geology_row_count" value="#rowIndex#">
								<!--- hidden field to accumulate geology attributes to delete --->
								<input type="hidden" name="geology_attributes_to_delete" id="geology_attributes_to_delete" value="">
						
								<script>
									$(document).ready(function() {
										const initialRowCount = parseInt($('##geology_row_count').val());
										for (let i = 1; i <= initialRowCount; i++) {
											makeAgentAutocompleteMeta('geo_att_determiner_' + i, 'geo_att_determiner_id_' + i, true);
											$("##geo_att_determined_date_" + i).datepicker({ dateFormat: 'yy-mm-dd'});
											$("##geo_att_remark_" + i).keyup(autogrow);
											countCharsLeft('geo_att_remark_' + i, 4000, 'length_geo_att_remark_' + i);
											makeGeologyAutocompleteMeta('geology_attribute_' + i, 'geo_att_value_' + i, 'geology_attribute_hierarchy_id' + i, 'entry', $("##attribute_type_" + i).val());
											addParentsChange(i); // initialize parent display
										}
									});
						
									function addGeologyRow() {
										$('##noGeologyRow').remove();
										let currentRowCount = parseInt($('##geology_row_count').val());
										currentRowCount++;
										$('##geology_row_count').val(currentRowCount);
										const newRow = `
											<tr data-row-index="${currentRowCount}">
												<td>
													<select name="attribute_type_${currentRowCount}" id="attribute_type_${currentRowCount}" class="data-entry-select reqdClr" onchange="changeGeoAttType(${currentRowCount})">
														<cfloop query="ctGeologyTypes">
															<option value="#ctGeologyTypes.type#">#ctGeologyTypes.type#</option>
														</cfloop>
													</select>
													<input type="hidden" name="geology_attribute_id_${currentRowCount}" id="geology_attribute_id_${currentRowCount}" value="">
													<input type="hidden" name="geology_attribute_hierarchy_id_${currentRowCount}" id="geology_attribute_hierarchy_id_${currentRowCount}" value="">
												</td>
												<td>
													<input type="text" name="geology_attribute_${currentRowCount}" id="geology_attribute_${currentRowCount}" class="data-entry-input" value="" readonly>
												</td>
												<td>
													<input type="text" id="geo_att_value_${currentRowCount}" name="geo_att_value_${currentRowCount}" class="data-entry-input reqdClr">
												</td>
												<td>
													<select id="add_parents_${currentRowCount}" name="add_parents_${currentRowCount}" class="data-entry-select" onchange="addParentsChange(${currentRowCount});">
														<option value="no" selected>No</option>
														<option value="yes">Yes</option>
													</select>
													<div id="parentsDiv_${currentRowCount}"></div>
												</td>
												<td>
													<input type="text" id="geo_att_determiner_${currentRowCount}" name="geo_att_determiner_${currentRowCount}" class="data-entry-input">
													<input type="hidden" name="geo_att_determiner_id_${currentRowCount}" id="geo_att_determiner_id_${currentRowCount}">
												</td>
												<td>
													<input type="text" id="geo_att_determined_date_${currentRowCount}" name="geo_att_determined_date_${currentRowCount}" class="data-entry-input geology-date">
												</td>
												<td>
													<input type="text" id="geo_att_determined_method_${currentRowCount}" name="geo_att_determined_method_${currentRowCount}" class="data-entry-input">
												</td>
												<td>
													<textarea name="geo_att_remark_${currentRowCount}" id="geo_att_remark_${currentRowCount}" class="form-control form-control-sm autogrow" rows="2" onkeyup="countCharsLeft('geo_att_remark_${currentRowCount}', 4000, 'length_geo_att_remark_${currentRowCount}');"></textarea>
													<br><span id="length_geo_att_remark_${currentRowCount}" class="smaller-text">0 characters, 4000 left</span>
												</td>
												<td>
													<button type="button" class="btn btn-xs btn-danger" onclick="removeGeologyRow(this)" title="Remove this geological attribute">
														<i class="fas fa-times"></i>
													</button>
												</td>
											</tr>
										`;
										<!--- " --->
										$('##geologyTableBody').append(newRow);
										makeAgentAutocompleteMeta('geo_att_determiner_' + currentRowCount, 'geo_att_determiner_id_' + currentRowCount, true);
										$("##geo_att_determined_date_" + currentRowCount).datepicker({ dateFormat: 'yy-mm-dd'});
										$("##geo_att_remark_" + currentRowCount).keyup(autogrow);
										countCharsLeft('geo_att_remark_' + currentRowCount, 4000, 'length_geo_att_remark_' + currentRowCount);
										makeGeologyAutocompleteMeta('geology_attribute_' + currentRowCount, 'geo_att_value_' + currentRowCount, null, 'entry', $("##attribute_type_" + currentRowCount).val());
										addParentsChange(currentRowCount);
									}
						
									function removeGeologyRow(button) {
										const row = $(button).closest('tr');
										const rowIndex = row.data('row-index');
										<!--- check if the row has a geology_attribute_id, if so, add it to the delete list --->
										const geologyAttributeId = $(`##geology_attribute_id_${rowIndex}`).val();
										if (geologyAttributeId) {
											let deleteList = $(`##geology_attributes_to_delete`).val();
											if (deleteList) {
												deleteList += ",";
											}
											deleteList += geologyAttributeId;
											$(`##geology_attributes_to_delete`).val(deleteList);
										}
										$(`##geology_attribute_${rowIndex}`).val('');
										row.hide();
										if ($('##geologyTableBody tr:visible').length === 0) {
											$('##geologyTableBody').append(`
												<tr id="noGeologyRow">
													<td colspan="9" class="text-muted text-center">No geological attributes for this locality.</td>
												</tr>
											`);
										}
									}
						
									function changeGeoAttType(rowIndex) {
										$(`##geology_attribute_${rowIndex}`).val("");
										$(`##geo_att_value_${rowIndex}`).val("");
										makeGeologyAutocompleteMeta('geology_attribute_' + rowIndex, 'geo_att_value_' + rowIndex, 'geology_attribute_hierarchy_id_' + rowIndex, 'entry', $(`##attribute_type_${rowIndex}`).val());
									}
						
									function addParentsChange(rowIndex) {
										var selection = $(`##add_parents_${rowIndex}`).val();
										if (selection === "yes") {
											lookupGeoAttParents($(`##geology_attribute_${rowIndex}`).val(), `parentsDiv_${rowIndex}`);
										} else {
											$(`##parentsDiv_${rowIndex}`).html("");
										}
									}
						
									function aggregateGeologyTable() {
										var geologyData = [];
										$('##geologyTableBody tr:visible').each(function() {
											var row = $(this);
											var rowIndex = row.data('row-index');
											var geologyAttribute = row.find('input[name="geology_attribute_' + rowIndex + '"]').val();
											if (geologyAttribute) {
												geologyData.push({
													attribute_type: row.find('select[name="attribute_type_' + rowIndex + '"]').val(),
													geology_attribute: geologyAttribute,
													geo_att_value: row.find('input[name="geo_att_value_' + rowIndex + '"]').val(),
													add_parents: row.find('select[name="add_parents_' + rowIndex + '"]').val(),
													geo_att_determiner: row.find('input[name="geo_att_determiner_' + rowIndex + '"]').val(),
													geo_att_determiner_id: row.find('input[name="geo_att_determiner_id_' + rowIndex + '"]').val(),
													geo_att_determined_date: row.find('input[name="geo_att_determined_date_' + rowIndex + '"]').val(),
													geo_att_determined_method: row.find('input[name="geo_att_determined_method_' + rowIndex + '"]').val(),
													geo_att_remark: row.find('textarea[name="geo_att_remark_' + rowIndex + '"]').val(),
													geology_attribute_id: row.find('input[name="geology_attribute_id_' + rowIndex + '"]').val()
												});
											}
										});
										return geologyData;
									}
						
								</script>
							</div><!--- end geology table section --->
						</div><!--- end geology attributes section --->
	
						<!--- current georeference (on locality) --->
						<cfquery name="ctunits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT ORIG_LAT_LONG_UNITS 
							FROM ctlat_long_units
							ORDER BY ORIG_LAT_LONG_UNITS
						</cfquery>
						<cfquery name="ctGeorefMethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT georefmethod 
							FROM ctgeorefmethod
							ORDER BY georefmethod
						</cfquery>
						<cfquery name="ctVerificationStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT verificationStatus 
							FROM ctVerificationStatus 
							ORDER BY verificationStatus
						</cfquery>
						<cfquery name="lookupForGeolocate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT 
								country, state_prov, county,
								spec_locality
							FROM locality
								join geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
							WHERE
								locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getLoc.locality_id#">
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
						
						<div class="col-12 form-row mx-1 px-0">
							<div class="col-12 px-0">
								<h2 class="h3 mt-3">
									Georeference and Georeference Metadata
									<cfquery name="getCurrentGeoreference" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										SELECT
											lat_long_id,
											accepted_lat_long_fg,
											decode(accepted_lat_long_fg,1,'Accepted','') accepted_lat_long,
											orig_lat_long_units,
											lat_deg, dec_lat_min, lat_min, lat_sec, lat_dir,
											long_deg, dec_long_min, long_min, long_sec, long_dir,
											utm_zone, utm_ew, utm_ns,
											georefmethod,
											coordinate_precision,
											nvl2(coordinate_precision, round(dec_lat,coordinate_precision), round(dec_lat,5)) dec_lat,
											dec_lat raw_dec_lat,
											nvl2(coordinate_precision, round(dec_long,coordinate_precision), round(dec_long,5)) dec_long,
											dec_long raw_dec_long,
											max_error_distance,
											max_error_units,
											round(to_meters(lat_long.max_error_distance, lat_long.max_error_units)) coordinateUncertaintyInMeters,
											spatialfit,
											error_polygon,
											footprint_spatialfit,
											datum,
											extent,
											extent_units,
											determined_by_agent_id,
											det_agent.agent_name determined_by,
											to_char(determined_date,'yyyy-mm-dd') determined_date,
											gpsaccuracy,
											lat_long_ref_source,
											nearest_named_place,
											lat_long_for_nnp_fg,
											verificationstatus,
											field_verified_fg,
											verified_by_agent_id,
											ver_agent.agent_name verified_by,
											CASE orig_lat_long_units
												WHEN 'decimal degrees' THEN dec_lat || '&##176;'
												WHEN 'deg. min. sec.' THEN lat_deg || '&##176; ' || lat_min || '&apos; ' || lat_sec || '&quot; ' || lat_dir
												WHEN 'degrees dec. minutes' THEN lat_deg || '&##176; ' || dec_lat_min || '&apos; ' || lat_dir
											END as LatitudeString,
											CASE orig_lat_long_units
												WHEN 'decimal degrees' THEN dec_long || '&##176;'
												WHEN'degrees dec. minutes' THEN long_deg || '&##176; ' || dec_long_min || '&apos; ' || long_dir
												WHEN 'deg. min. sec.' THEN long_deg || '&##176; ' || long_min || '&apos; ' || long_sec || '&quot ' || long_dir
											END as LongitudeString,
											geolocate_uncertaintypolygon,
											geolocate_score,
											geolocate_precision,
											geolocate_numresults,
											geolocate_parsepattern,
											lat_long_remarks
										FROM
											lat_long
											left join preferred_agent_name det_agent on lat_long.determined_by_agent_id = det_agent.agent_id
											left join preferred_agent_name ver_agent on lat_long.verified_by_agent_id = ver_agent.agent_id
										WHERE 
											lat_long.locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getLoc.locality_id#">
											AND accepted_lat_long_fg = 1
									</cfquery>
									<cfif getCurrentGeoreference.recordcount GT 0>
										<cfloop query="getCurrentGeoreference">
											<cfif len(datum) EQ 0 OR len(max_error_distance) EQ 0 OR len(max_error_units) EQ 0 OR len(coordinate_precision) EQ 0 OR len(lat_long_for_nnp_fg) EQ 0 OR len(lat_long_ref_source) EQ 0 OR len(georefmethod) EQ 0 OR (len(extent) GT 0 AND len(extent_units) EQ 0) >
												<cfset missingFields = true>
											<cfelse>
												<cfset missingFields = false>
											</cfif>
										</cfloop>
										<cfif NOT missingFields>
											<button type="button" class="btn btn-xs btn-secondary" id="buttonOpenEditGeoreference">Edit Current Here</button>
										</cfif>
									</cfif>
									<a class="btn btn-xs btn-warning" href="/localities/Locality.cfm?locality_id=#getLoc.locality_id#" target="_blank">Edit from the #shared_loc# Locality</a>.
								</h2>
								
								<div class="form-row">
									<cfquery name="getGeoreferences" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										SELECT
											lat_long_id,
											georefmethod,
											to_char(dec_lat, '99' || rpad('.',nvl(coordinate_precision,5) + 1, '0')) dec_lat,
											dec_lat raw_dec_lat,
											to_char(dec_long, '999' || rpad('.',nvl(coordinate_precision,5) + 1, '0')) dec_long,
											dec_long raw_dec_long,
											coordinate_precision,
											max_error_distance,
											max_error_units,
											round(to_meters(lat_long.max_error_distance, lat_long.max_error_units)) coordinateUncertaintyInMeters,
											error_polygon,
											datum,
											extent,
											spatialfit,
											determined_by_agent_id,
											det_agent.agent_name determined_by,
											determined_date,
											gpsaccuracy,
											lat_long_ref_source,
											nearest_named_place,
											lat_long_for_nnp_fg,
											verificationstatus,
											field_verified_fg,
											verified_by_agent_id,
											ver_agent.agent_name verified_by,
											orig_lat_long_units,
											lat_deg, dec_lat_min, lat_min, lat_sec, lat_dir,
											long_deg, dec_long_min, long_min, long_sec, long_dir,
											utm_zone, utm_ew, utm_ns,
											CASE orig_lat_long_units
												WHEN 'decimal degrees' THEN dec_lat || '&##176;'
												WHEN 'deg. min. sec.' THEN lat_deg || '&##176; ' || lat_min || '&apos; ' || lat_sec || '&quot; ' || lat_dir
												WHEN 'degrees dec. minutes' THEN lat_deg || '&##176; ' || dec_lat_min || '&apos; ' || lat_dir
											END as LatitudeString,
											CASE orig_lat_long_units
												WHEN 'decimal degrees' THEN dec_long || '&##176;'
												WHEN'degrees dec. minutes' THEN long_deg || '&##176; ' || dec_long_min || '&apos; ' || long_dir
												WHEN 'deg. min. sec.' THEN long_deg || '&##176; ' || long_min || '&apos; ' || long_sec || '&quot ' || long_dir
											END as LongitudeString,
											accepted_lat_long_fg,
											decode(accepted_lat_long_fg,1,'Accepted','') accepted_lat_long,
											geolocate_uncertaintypolygon,
											geolocate_score,
											geolocate_precision,
											geolocate_numresults,
											geolocate_parsepattern,
											lat_long_remarks
										FROM
											lat_long
											left join preferred_agent_name det_agent on lat_long.determined_by_agent_id = det_agent.agent_id
											left join preferred_agent_name ver_agent on lat_long.verified_by_agent_id = ver_agent.agent_id
										WHERE 
											lat_long.locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getLoc.locality_id#">
										ORDER BY
											accepted_lat_long_fg desc
									</cfquery>
									<cfloop query="getGeoreferences">
										<cfset original="">
										<cfset det = "">
										<cfset ver = "">
										<cfif len(determined_by) GT 0>
											<cfset det = " Determiner: #determined_by#. ">
										</cfif>
										<cfif len(verified_by) GT 0>
											<cfset ver = " Verified by: #verified_by#. ">
										</cfif>
										<cfif len(utm_zone) GT 0>
											<cfset original = "(as: #utm_zone# #utm_ew# #utm_ns#)">
										<cfelse>
											<cfset original = "(as: #LatitudeString#,#LongitudeString#)">
										</cfif>
										<cfset divClass="small90 my-1 w-100">
										<cfif accepted_lat_long EQ "Accepted">
											<cfset divClass="small90 font-weight-lessbold my-1 w-100">
										</cfif>
										<div class="#divClass# px-2">
											#dec_lat#, #dec_long# &nbsp; #datum# ±#coordinateUncertaintyInMeters#m
										</div>
										<ul class="mb-2 pl-2 pl-xl-4 ml-xl-1 small95">
											<li>
												#original# <span class="#divClass#">#accepted_lat_long#</span>
											</li>
											<li>
												Method: #georefmethod# #det# Verification: #verificationstatus# #ver#
											</li>
											<cfif len(geolocate_score) GT 0>
												<li>
													GeoLocate: score=#geolocate_score# precision=#geolocate_precision# results=#geolocate_numresults# pattern=#geolocate_parsepattern#
												</li>
											</cfif>
											<cfif len(coordinate_precision) EQ 0>
												<li>
													Coordinate Precision is not set.  
													<cfif cecount.ct EQ 1 AND loccount.ct EQ 1>
														Set an appropriate value of coordinate precision to fix this.
													<cfelse>
														Edit the georeference from the #shared_loc# Locality to 
														<a class="btn btn-xs btn-warning" href="/localities/Locality.cfm?locality_id=#getLoc.locality_id#&launchEditCurrentGeorefDialog=true" target="_blank">Fix This</a>.
													</cfif>
												</li>
											</cfif>
										</ul>
									</cfloop>
								</div>
							</div>
						
							<script>
								$(document).ready(function() {
									$('##buttonOpenEditGeoreference').on('click', function() {
										$('##georeferenceEditSection').show();
										$('##buttonOpenEditGeoreference').hide();
										changeLatLongUnits();
									});
								});
							</script>
						
							<!--- Edit georeference form section --->
							<cfif getCurrentGeoreference.recordcount GT 0>
								<cfloop query="getCurrentGeoreference">
									<cfset georefSectionStyleValue="style='display: none;'"><!--- this part of form is hidden by default --->
									<cfset georefSectionWarningMessage=false>
									<cfif len(datum) EQ 0 OR len(max_error_distance) EQ 0 OR len(max_error_units) EQ 0 OR len(coordinate_precision) EQ 0 OR len(lat_long_for_nnp_fg) EQ 0 OR len(lat_long_ref_source) EQ 0 OR len(georefmethod) EQ 0 OR (len(extent) GT 0 AND len(extent_units) EQ 0) >
										<cfset georefSectionStyleValue=""><!--- but if a required element is missing, show this part of the form and display a warning message --->
										<cfset georefSectionWarningMessage=true>
									</cfif>
									<div id="georeferenceEditSection" class="col-12" #georefSectionStyleValue#>
										<h3 class="h4 mt-3">
											Edit Current Georeference
											<cfif splitToSave>
												(editing here will split off the collecting event and locality)
											</cfif>
											<i class="fas fa-info-circle" onClick="getMCZDocs('Georeferencing')" aria-label="georeferencing help link"></i>
										</h3>
										<cfif georefSectionWarningMessage>
											<div class='text-danger fw-bold'>
												One or More required elements of the current georeference are missing, you probably want to edit this from the locality record to fix this condition.
											</div>
										</cfif>
										
										<!--- Hidden fields for georeference --->
										<input type="hidden" name="lat_long_id" value="#lat_long_id#">
										<input type="hidden" name="field_mapping" value="generic"><!--- dec_lat reused for degrees in degrees minutes seconds and degrees decimal minutes --->
										
										<div class="form-row">
											<div class="col-12 col-md-3 mb-2">
												<label for="orig_lat_long_units" class="data-entry-label">Coordinate Format</label>
												<select id="orig_lat_long_units" name="orig_lat_long_units" class="data-entry-select reqdClr" onChange="changeLatLongUnits();">
													<cfif orig_lat_long_units EQ "decimal degrees"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
													<option value="decimal degrees" #selected#>decimal degrees</option>
													<cfif orig_lat_long_units EQ "degrees dec. minutes"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
													<option value="degrees dec. minutes" #selected#>degrees decimal minutes</option>
													<cfif orig_lat_long_units EQ "deg. min. sec."><cfset selected="selected"><cfelse><cfset selected=""></cfif>
													<option value="deg. min. sec." #selected#>deg. min. sec.</option>
													<cfif orig_lat_long_units EQ "UTM"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
													<option value="UTM" #selected#>UTM (Universal Transverse Mercator)</option>
												</select>
											</div>
											<div class="col-12 col-md-3 mb-2">
												<label for="accepted_lat_long_fg" class="data-entry-label">Accepted</label>
												<select name="accepted_lat_long_fg" size="1" id="accepted_lat_long_fg" class="data-entry-select reqdClr">
													<cfif accepted_lat_long_fg EQ "1"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
													<option value="1" #selected#>Yes</option>
													<cfif accepted_lat_long_fg EQ "0"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
													<option value="0" #selected#>No</option>
												</select>
											</div>
											<div class="col-12 col-md-3 mb-2">
												<label for="determined_by_agent" class="data-entry-label">Determiner</label>
												<input type="hidden" name="determined_by_agent_id" id="determined_by_agent_id" value="#determined_by_agent_id#">
												<input type="text" name="determined_by_agent" id="determined_by_agent" class="data-entry-input reqdClr" value="#encodeForHtml(determined_by)#">
											</div>
											<div class="col-12 col-md-3">
												<label for="determined_date" class="data-entry-label">Date Determined</label>
												<input type="text" name="determined_date" id="determined_date" class="data-entry-input reqdClr" placeholder="yyyy-mm-dd" value="#determined_date#">
											</div>
											
											<!--- Latitude fields --->
											<div class="col-12 col-md-3 mb-2">
												<cfif orig_lat_long_units EQ "decimal degrees"><cfset deg="#dec_lat#"><cfelse><cfset deg="#lat_deg#"></cfif>
												<label for="lat_deg" class="data-entry-label">Latitude Degrees &##176;</label>
												<input type="text" name="lat_deg" id="lat_deg" class="data-entry-input latlong" value="#deg#">
											</div>
											<div class="col-12 col-md-3 mb-2">
												<label for="lat_min" class="data-entry-label">Minutes &apos;</label>
												<cfif orig_lat_long_units EQ "degrees dec. minutes"><cfset min="#dec_lat_min#"><cfelse><cfset min="#lat_min#"></cfif>
												<input type="text" name="lat_min" id="lat_min" class="data-entry-input latlong" value="#min#">
											</div>
											<div class="col-12 col-md-3 mb-2">
												<label for="lat_sec" class="data-entry-label">Seconds &quot;</label>
												<input type="text" name="lat_sec" id="lat_sec" class="data-entry-input latlong" value="#lat_sec#">
											</div>
											<div class="col-12 col-md-3 mb-2">
												<label for="lat_dir" class="data-entry-label">Direction</label>
												<select name="lat_dir" size="1" id="lat_dir" class="data-entry-select latlong">
													<cfif lat_dir EQ ""><cfset selected="selected"><cfelse><cfset selected=""></cfif>
													<option value="" #selected#></option>
													<cfif lat_dir EQ "N"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
													<option value="N" #selected#>N</option>
													<cfif lat_dir EQ "S"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
													<option value="S" #selected#>S</option>
												</select>
											</div>
											
											<!--- Longitude fields --->
											<div class="col-12 col-md-3 mb-2">
												<cfif orig_lat_long_units EQ "decimal degrees"><cfset deg="#dec_long#"><cfelse><cfset deg="#long_deg#"></cfif>
												<label for="long_deg" class="data-entry-label">Longitude Degrees &##176;</label>
												<input type="text" name="long_deg" size="4" id="long_deg" class="data-entry-input latlong" value="#deg#">
											</div>
											<div class="col-12 col-md-3 mb-2">
												<cfif orig_lat_long_units EQ "degrees dec. minutes"><cfset min="#dec_long_min#"><cfelse><cfset min="#long_min#"></cfif>
												<label for="long_min" class="data-entry-label">Minutes &apos;</label>
												<input type="text" name="long_min" size="4" id="long_min" class="data-entry-input latlong" value="#min#">
											</div>
											<div class="col-12 col-md-3 mb-2">
												<label for="long_sec" class="data-entry-label">Seconds &quot;</label>
												<input type="text" name="long_sec" size="4" id="long_sec" class="data-entry-input latlong" value="#long_sec#">
											</div>
											<div class="col-12 col-md-3 mb-2">
												<label for="long_dir" class="data-entry-label">Direction</label>
												<select name="long_dir" size="1" id="long_dir" class="data-entry-select latlong">
													<cfif long_dir EQ ""><cfset selected="selected"><cfelse><cfset selected=""></cfif>
													<option value="" #selected#></option>
													<cfif long_dir EQ "E"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
													<option value="E" #selected#>E</option>
													<cfif long_dir EQ "W"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
													<option value="W" #selected#>W</option>
												</select>
											</div>
											
											<!--- UTM fields --->
											<div class="col-12 col-md-4 mb-2">
												<label for="utm_zone" class="data-entry-label">UTM Zone/Letter</label>
												<input type="text" name="utm_zone" size="4" id="utm_zone" class="data-entry-input utm" value="#encodeForHtml(utm_zone)#">
											</div>
											<div class="col-12 col-md-4 mb-2">
												<label for="utm_ew" class="data-entry-label">Easting</label>
												<input type="text" name="utm_ew" size="4" id="utm_ew" class="data-entry-input utm" value="#encodeForHtml(utm_ew)#">
											</div>
											<div class="col-12 col-md-4 mb-2">
												<label for="utm_ns" class="data-entry-label">Northing</label>
												<input type="text" name="utm_ns" size="4" id="utm_ns" class="data-entry-input utm" value="#encodeForHtml(utm_ns)#">
											</div>
											
											<!--- Datum and error fields --->
											<div class="col-12 col-md-3 mb-2">
												<label for="datum" class="data-entry-label">
													Geodetic Datum
													<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('##datum').autocomplete('search','%%%'); return false;" > (&##8595;) <span class="sr-only">open geodetic datum pick list</span></a>
												</label>
												<input type="text" name="datum" id="datum" class="data-entry-input reqdClr" value="#encodeForHtml(datum)#" required>
											</div>
											<div class="col-12 col-md-2 mb-2">
												<label for="max_error_distance" class="data-entry-label">Error Radius</label>
												<input type="text" name="max_error_distance" id="max_error_distance" class="data-entry-input reqdClr" value="#max_error_distance#" required>
											</div>
											<div class="col-12 col-md-1 mb-2">
												<label for="max_error_units" class="data-entry-label">
													Units
													<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('##max_error_units').autocomplete('search','%%%'); return false;" > (&##8595;) <span class="sr-only">open pick list for error radius units</span></a>
												</label>
												<input type="text" name="max_error_units" id="max_error_units" class="data-entry-input reqdClr" value="#encodeForHtml(max_error_units)#" required>
											</div>
											<div class="col-12 col-md-3 mb-2">
												<label for="spatialfit" class="data-entry-label">Point Radius Spatial Fit</label>
												<input type="text" name="spatialfit" id="spatialfit" class="data-entry-input" value="#spatialfit#" pattern="^(0|1(\.[0-9]+)|[1-9][0-9.]{0,5}){0,1}$" >
											</div>
											<div class="col-12 col-md-2 mb-2">
												<label for="extent" class="data-entry-label">Radial of Feature [Extent]</label>
												<input type="text" name="extent" id="extent" class="data-entry-input" value="#extent#" pattern="^[0-9.]*$" >
											</div>
											<div class="col-12 col-md-1 mb-2">
												<cfif len(extent) GT 0 AND len(extent_units) EQ 0>
													<cfset reqExtentUnits="required">
													<cfset reqdClrEU="reqdClr">
												<cfelse>
													<cfset reqExtentUnits="">
													<cfset reqdClrEU="">
												</cfif>
												<label for="extent_units" class="data-entry-label">
													Units
													<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('##extent_units').autocomplete('search','%%%'); return false;" > (&##8595;) <span class="sr-only">open pick list for radial of feature (extent) units</span></a>
												</label>
												<input type="text" name="extent_units" id="extent_units" class="data-entry-input #reqdClrEU#" value="#encodeForHtml(extent_units)#" #reqExtentUnits#>
											</div>
											
											<!--- Precision and other fields --->
											<div class="col-12 col-md-3 mb-2">
												<label for="coordinate_precision" class="data-entry-label">Precision</label>
												<select name="coordinate_precision" id="coordinate_precision" class="data-entry-select reqdClr" required>
													<cfif len(coordinate_precision) EQ 0><cfset selected="selected"><cfelse><cfset selected=""></cfif>
													<option value="" #selected#></option>
													<cfif coordinate_precision EQ "0"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
													<option value="0" #selected#>Specified to 1&##176;</option>
													<cfif coordinate_precision EQ "1"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
													<option value="1" #selected#>Specified to 0.1&##176;. latitude known to 11 km.</option>
													<cfif coordinate_precision EQ "2"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
													<option value="2" #selected#>Specified to 0.01&##176;, use if known to 1&apos;, latitude known to 1,111 meters.</option>
													<cfif coordinate_precision EQ "3"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
													<option value="3" #selected#>Specified to 0.001&##176;, latitude known to 111 meters.</option>
													<cfif coordinate_precision EQ "4"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
													<option value="4" #selected#>Specified to 0.0001&##176;, use if known to 1&quot;, latitude known to 11 meters.</option>
													<cfif coordinate_precision EQ "5"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
													<option value="5" #selected#>Specified to 0.00001&##176;, latitude known to 1 meter.</option>
													<cfif coordinate_precision EQ "6"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
													<option value="6" #selected#>Specified to 0.000001&##176;, latitude known to 11 cm.</option>
												</select>
											</div>
											<div class="col-12 col-md-3 mb-2">
												<label for="gpsaccuracy" class="data-entry-label">GPS Accuracy</label>
												<input type="text" name="gpsaccuracy" id="gpsaccuracy" class="data-entry-input" value="#encodeForHtml(gpsaccuracy)#" pattern="^$|^[0-9.]+$" >
											</div>
											<div class="col-12 col-md-3 mb-2">
												<label for="nearest_named_place" class="data-entry-label">Nearest Named Place</label>
												<input type="text" name="nearest_named_place" id="nearest_named_place" class="data-entry-input" value="#encodeForHtml(nearest_named_place)#">
											</div>
											<div class="col-12 col-md-3 mb-2">
												<label for="lat_long_for_nnp_fg" class="data-entry-label">Georeference is of Nearest Named Place</label>
												<select name="lat_long_for_nnp_fg" id="lat_long_for_nnp_fg" class="data-entry-select reqdClr" required>
													<cfif lat_long_for_nnp_fg EQ "0"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
													<option value="0" #selected#>No</option>
													<cfif lat_long_for_nnp_fg EQ "1"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
													<option value="1" #selected#>Yes</option>
												</select>
											</div>
											<div class="col-12 col-md-3">
												<label for="lat_long_ref_source" class="data-entry-label">Reference</label>
												<input type="text" name="lat_long_ref_source" id="lat_long_ref_source" class="data-entry-input reqdClr" value="#encodeForHtml(lat_long_ref_source)#" required>
											</div>
											<div class="col-12 col-md-3 mb-2">
												<label for="georefmethod" class="data-entry-label">
													Method
													<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('##georefmethod').autocomplete('search','%%%'); return false;" > (&##8595;) <span class="sr-only">open georeference method pick list</span></a>
												</label>
												<input type="text" name="georefmethod" id="georefmethod" class="data-entry-input reqdClr" value="#encodeForHtml(georefmethod)#" required>
											</div>
											<div class="col-12 col-md-3 mb-2">
												<label for="verificationstatus" class="data-entry-label">
													Verification Status
													<cfif verificationstatus NEQ "unverified">
														<span id="oldverifstatus" class="text-danger" onClick="setVerificationStatus('#verificationstatus#');">Was: #encodeForHtml(verificationstatus)# (&##8595;)<span/>
													</cfif>
												</label>
												<select name="verificationstatus" size="1" id="verificationstatus" class="data-entry-select reqdClr" onChange="changeVerificationStatus();">
													<cfloop query="ctVerificationStatus">
														<!--- user needs to explicitly address the verification status or it reverts to unverified --->
														<cfif ctVerificationStatus.verificationstatus EQ "unverified"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
														<option value="#ctVerificationStatus.verificationStatus#" #selected#>#ctVerificationStatus.verificationStatus#</option>
													</cfloop>
												</select>
											</div>
											<div class="col-12 col-md-3 mb-2">
												<label for="verified_by_agent" class="data-entry-label" id="verified_by_agent_label" >
													Verified by
													<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('##verified_by_agent_id').val('#getCurrentUser.agent_id#');  $('##verified_by_agent').val('#encodeForHtml(getCurrentUser.agent_name)#'); return false;" > (me) <span class="sr-only">Fill in verified by with #encodeForHtml(getCurrentUser.agent_name)#</span></a>
												</label>
												<input type="hidden" name="verified_by_agent_id" id="verified_by_agent_id" value="#verified_by_agent_id#">
												<input type="text" name="verified_by_agent" id="verified_by_agent" class="data-entry-input reqdClr" value="#verified_by#">
											</div>
											<div class="col-12 mb-2">
												<label class="data-entry-label" for="lat_long_remarks">Georeference Remarks (<span id="length_lat_long_remarks">0 of 4000 characters</span>)</label>
												<textarea name="lat_long_remarks" id="lat_long_remarks" 
													onkeyup="countCharsLeft('lat_long_remarks', 4000, 'length_lat_long_remarks');"
													class="form-control form-control-sm w-100 autogrow mb-1" style="min-height: 30px;" rows="2">#encodeForHtml(lat_long_remarks)#</textarea>
											</div>
											<div class="col-12 col-md-9 mb-2">
												<label for="error_polygon" class="data-entry-label" id="error_polygon_label">Footprint Polygon (WKT)</label>
												<input type="text" name="error_polygon" id="error_polygon" class="data-entry-input" value="#encodeForHtml(error_polygon)#">
											</div>
											<div class="col-12 col-md-3 mb-2">
												<label for="footprint_spatialfit" class="data-entry-label">Footprint Spatial Fit</label>
												<input type="text" name="footprint_spatialfit" id="footprint_spatialfit" class="data-entry-input" value="#footprint_spatialfit#" pattern="^(0|1(\.[0-9]+)|[1-9][0-9.]{0,5}){0,1}$" >
											</div>
											<div class="col-12 col-md-6 col-xl-3 mb-2">
												<label for="wktFile" class="data-entry-label">Load Footprint Polygon from WKT file</label>
												<input type="file" id="wktFile" name="wktFile" accept=".wkt" class="w-100 p-0">
											</div>
											<div class="col-12 col-md-6 col-xl-2 mt-3 text-danger mb-2">
												<output id="wktReplaceFeedback"></output>
											</div>
											<div class="col-12 col-md-6 col-xl-3 mb-2">
												<label for="copyFootprintFrom" class="data-entry-label" >Copy Polygon from locality_id</label>
												<input type="hidden" name="copyFootprintFrom_id" id="copyFootprintFrom_id" value="">
												<input type="text" name="copyFootprintFrom" id="copyFootprintFrom" value="" class="data-entry-input">
											</div>
											<div class="col-2 col-md-2 col-xl-1 mb-2">
												<label class="data-entry-label">&nbsp;</label>
												<input type="button" value="Copy" class="btn btn-xs btn-secondary" onClick=" confirmCopyWKTFromLocality(); ">
											</div>
											<div class="col-12 col-md-4 col-xl-3 mb-2">
												<output id="wktLocReplaceFeedback"></output>
											</div>
											
											<cfif len(geolocate_score) GT 0>
												<div class="geolocateMetadata col-12 mb-1">
													<h3 class="h4 my-1 px-1">Batch GeoLocate Georeference Metadata</h3>
												</div>
												<div class="geolocateMetadata col-12 col-md-3 mb-0">
													<label for="geolocate_uncertaintypolygon" class="data-entry-label" id="geolocate_uncertaintypolygon_label">GeoLocate Uncertainty Polygon</label>
													<input type="text" name="geolocate_uncertaintypolygon" id="geolocate_uncertaintypolygon" class="data-entry-input bg-lt-gray" value="#encodeForHtml(geolocate_uncertaintypolygon)#"  readonly>
												</div>
												<div class="geolocateMetadata col-12 col-md-2 mb-0">
													<label for="geolocate_score" class="data-entry-label" id="geolocate_score_label">GeoLocate Score</label>
													<input type="text" name="geolocate_score" id="geolocate_score" class="data-entry-input bg-lt-gray" value="#encodeForHtml(geolocate_score)#" readonly>
												</div>
												<div class="geolocateMetadata col-12 col-md-2 mb-0">
													<label for="geolocate_precision" class="data-entry-label" id="geolocate_precision_label">GeoLocate Precision</label>
													<input type="text" name="geolocate_precision" id="geolocate_precision" class="data-entry-input bg-lt-gray" value="#encodeForHtml(geolocate_precision)#" readonly>
												</div>
												<div class="geolocateMetadata col-12 col-md-2 mb-0">
													<label for="geolocate_numresults" class="data-entry-label" id="geolocate_numresults_label">Number of Matches</label>
													<input type="text" name="geolocate_numresults" id="geolocate_numresults" class="data-entry-input bg-lt-gray" value="#encodeForHtml(geolocate_numresults)#" readonly>
												</div>
												<div class="geolocateMetadata col-12 col-md-3 mb-0">
													<label for="geolocate_parsepattern" class="data-entry-label" id="geolocate_parsepattern_label">Parse Pattern</label>
													<input type="text" name="geolocate_parsepattern" id="geolocate_parsepattern" class="data-entry-input bg-lt-gray" value="#encodeForHtml(geolocate_parsepattern)#" readonly>
												</div>
											</cfif>
										</div>
										
										<script>
											$(document).ready(function() {
												makeAgentAutocompleteMeta("determined_by_agent", "determined_by_agent_id");
												$("##determined_date").datepicker({ dateFormat: 'yy-mm-dd'});
												makeAgentAutocompleteMeta("verified_by_agent", "verified_by_agent_id");
												makeCTAutocomplete('datum','datum');
												makeCTAutocomplete('max_error_units','lat_long_error_units');
												makeCTAutocomplete('extent_units','lat_long_error_units');
												makeCTAutocomplete('georefmethod','georefmethod');
												makeLocalityAutocompleteMetaLimited("copyFootprintFrom", "copyFootprintFrom_id","has_footprint");
												$("##wktFile").change(confirmLoadWKTFromFile);
												$("##lat_long_remarks").keyup(autogrow);
												$('##lat_long_remarks').keyup();
												countCharsLeft('lat_long_remarks', 4000, 'length_lat_long_remarks');
												
												<cfif verificationstatus EQ "unverified" OR verificationstatus EQ "migration" OR verificationstatus EQ "unknown" >
													$('##verified_by_agent').hide();
													$('##verified_by_agent_label').hide();
												</cfif>
												<cfif verificationstatus NEQ "unverified">
													<!--- setup appearance when user needs to explicitly address the verification status or it reverts to unverified --->
													$('##verificationstatus').addClass("bg-verylightred");
													$('##verified_by_agent').addClass("bg-verylightred");
													$('##verificationstatus').removeClass("reqdClr");
													$('##verified_by_agent').removeClass("reqdClr");
												</cfif>
											});
						
											function changeLatLongUnits(){ 
												$(".latlong").prop('disabled', true);
												$(".latlong").prop('required', false);
												$(".latlong").removeClass('reqdClr');
												$(".latlong").addClass('bg-lt-gray');
												$(".utm").removeClass('reqdClr');
												$(".utm").addClass('bg-lt-gray');
												$(".utm").prop('disabled', true);
												$(".utm").prop('required', false);
												var units = $("##orig_lat_long_units").val();
												if (!units) { 
													$(".latlong").prop('disabled', true);
													$(".utm").prop('disabled', true);
												} else if (units == 'decimal degrees') {
													$("##lat_deg").prop('disabled', false);
													$("##lat_deg").prop('required', true);
													$("##lat_deg").addClass('reqdClr');
													$("##lat_deg").removeClass('bg-lt-grey');
													$("##long_deg").prop('disabled', false);
													$("##long_deg").prop('required', true);
													$("##long_deg").addClass('reqdClr');
													$("##long_deg").removeClass('bg-lt-grey');
												} else if (units == 'degrees dec. minutes') {
													$("##lat_deg").prop('disabled', false);
													$("##lat_deg").prop('required', true);
													$("##lat_deg").addClass('reqdClr');
													$("##lat_deg").removeClass('bg-lt-grey');
													$("##lat_min").prop('disabled', false);
													$("##lat_min").prop('required', true);
													$("##lat_min").addClass('reqdClr');
													$("##lat_min").removeClass('bg-lt-grey');
													$("##lat_dir").prop('disabled', false);
													$("##lat_dir").prop('required', true);
													$("##lat_dir").addClass('reqdClr');
													$("##long_deg").prop('disabled', false);
													$("##long_deg").prop('required', true);
													$("##long_deg").addClass('reqdClr');
													$("##long_deg").removeClass('bg-lt-grey');
													$("##long_min").prop('disabled', false);
													$("##long_min").prop('required', true);
													$("##long_min").addClass('reqdClr');
													$("##long_min").removeClass('bg-lt-grey');
													$("##long_dir").prop('disabled', false);
													$("##long_dir").prop('required', true);
													$("##long_dir").addClass('reqdClr');
													$("##long_dir").removeClass('bg-lt-grey');
												} else if (units == 'deg. min. sec.') {
													$(".latlong").prop('disabled', false);
													$(".latlong").addClass('reqdClr');
													$(".latlong").removeClass('bg-lt-grey');
													$(".latlong").prop('required', true);
												} else if (units == 'UTM') {
													$(".utm").prop('disabled', false);
													$(".utm").prop('required', true);
													$(".utm").addClass('reqdClr');
													$(".utm").removeClass('bg-lt-grey');
												}
											} 
						
											/* show/hide verified by agent controls depending on verification status */
											function changeVerificationStatus() { 
												var status = $('##verificationstatus').val();
												if (status=='verified by MCZ collection' || status=='rejected by MCZ collection' || status=='verified by collector') {
													$('##verified_by_agent').show();
													$('##verified_by_agent_label').show();
												} else { 
													$('##verified_by_agent').hide();
													$('##verified_by_agent_label').hide();
													$('##verified_by_agent').val("");
													$('##verified_by_agent_id').val("");
												}
												$('##verificationstatus').removeClass("bg-verylightred");
												$('##verified_by_agent').removeClass("bg-verylightred");
												$('##verificationstatus').addClass("reqdClr");
												$('##verified_by_agent').addClass("reqdClr");
											};
											
											function setVerificationStatus(value) { 
												$('##verificationstatus').val(value);
												changeVerificationStatus();
												$('##oldverifstatus').removeClass("text-danger");
											} 
						
											function confirmLoadWKTFromFile(){
												if ($("##error_polygon").val().length > 1) {
													confirmDialog('This Georeference has a Footprint Polygon, do you wish to overwrite it?','Confirm overwrite Footprint WKT', loadWKTFromFile);
												} else {
													loadWKTFromFile();
												}
											}
											
											function loadWKTFromFile() { 
												loadPolygonWKTFromFile('wktFile', 'error_polygon', 'wktReplaceFeedback');
											}
						
											function copyWKTFromLocality() { 
												var lookup_locality_id = $("##copyFootprintFrom_id").val();
												if (lookup_locality_id=="") {
													$("##wktLocReplaceFeedback").html("No locality selected to look up.");
												} else {  
													$("##wktLocReplaceFeedback").html("Loading...");
													jQuery.ajax({
														url: "/localities/component/georefUtilities.cfc",
														type: "get",
														data: {
															method: "getGeoreferenceErrorWKT",
															returnformat: "plain",
															locality_id: lookup_locality_id
														}, 
														success: function (data) { 
															$("##error_polygon").val(data);
															$("##wktLocReplaceFeedback").html("Loaded.");
														}, 
														error: function (jqXHR, textStatus, error) {
															$("##wktLocReplaceFeedback").html("Error looking up polygon WKT.");
															handleFail(jqXHR,textStatus,error,"looking up wkt for accepted lat_long for locality");
														}
													});
												} 
											} 
											
											function confirmCopyWKTFromLocality(){
												if ($("##error_polygon").val().length > 1) {
													confirmDialog('This Georeference has a Footprint Polygon, do you wish to overwrite it?','Confirm overwrite Footprint WKT', copyWKTFromLocality);
												} else {
													copyWKTFromLocality();
												}
											}
										</script>
									</div><!--- end georeference edit section --->
								</cfloop>
							</cfif>
						</div><!--- end georeference section --->	
	
						<div class="col-12 row px-0">
							<div class="col-12">
								<div class="mt-3 float-left">
									<cfif splitToSave>	
										<input id="splitAndSaveButton" type="submit" value="Split and Save Changes" class="btn btn-xs btn-primary" disabled>
										<output id="locFormOutput"></output>
										<span class="ml-3">A new locality and collecting event will be created with these values and changes will apply to this record only. </span> 
									<cfelse>
										<input id="saveButton" type="submit" value="Save Changes" class="btn btn-xs btn-primary float-left">
										<output id="locFormOutput"></output>
									</cfif>
								</div>
								<div class="mt-3 float-right">
									<button id="backToSpecimen2" class="btn btn-xs btn-secondary mb-3" onclick="closeLocalityInPage();">Back to Specimen</button>
								</div>
							</div>
						</div>
					</form>
					<script>
						$(document).ready(function() {
							// Initialize datepicker for determined_date
							$("##determined_date").datepicker({
								dateFormat: "yy-mm-dd",
								changeMonth: true,
								changeYear: true
							});
							$('##locForm').on('input change', 'input, select, textarea', function(event) {
								// 'this' is the changed element
								var changedId = $(this).attr('id');
								var newValue = $(this).val();
								console.log('locForm field changed:', changedId, 'New value:', newValue);
								// Indicate that there are unsaved changes
								changeMadeInLocForm();
							});
							if ($("##georeferenceEditSection").is(":visible")) {
								// Initialize the georeference units based on the original units
								changeLatLongUnits();
							};
						});
						function closeLocalityInPage() { 
							// Close the in-page modal editor, and invoke the reloadLocality function
							closeInPage(reloadLocality);
						}
					</script>
				</div>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
					<cfdump var="#cfcatch#">
				</cfif>
			</cfcatch>
			</cftry>
		</cfoutput> 
	</cfthread>
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


<!--- getEditPartAttributesHTML 
 Threaded method to obtain a dialog for editing part attributes of a specimen part
 @param partID the collection_object_id for the specimen part to edit attributes for
 @return HTML for editing part attributes with separate forms for creating new and editing existing attributes
--->
<cffunction name="getEditPartAttributesHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="partID" type="string" required="yes">
	
	<cfthread name="getEditPartAttributesThread" partID="#arguments.partID#">
		<cfoutput>
			<cftry>
				
				<!--- lookup the guid and part info given the part ID --->
				<cfquery name="getPartInfo" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT 
						specimen_part.part_name,
						specimen_part.preserve_method,
						collection.collection_cde,
						cataloged_item.cat_num,
						collection.institution_acronym
					FROM specimen_part
						join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id 
						join collection on cataloged_item.collection_id = collection.collection_id
					WHERE specimen_part.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#attributes.partID#">
				</cfquery>

				<!--- Load controlled vocabulary for attribute types --->
				<cfquery name="ctspecpart_attribute_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT attribute_type 
					FROM ctspecpart_attribute_type 
					ORDER BY attribute_type
				</cfquery>

				<!--- Get current user for default determiner --->
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
				
				<cfset partLabel = "#getPartInfo.part_name#">
				<cfif len(getPartInfo.preserve_method)>
					<cfset partLabel = "#partLabel# (#getPartInfo.preserve_method#)">
				</cfif>
				<cfset guid = "#getPartInfo.institution_acronym#:#getPartInfo.collection_cde#:#getPartInfo.cat_num#">

				<!--- add new part attribute form --->
				<div class="col-12 mt-4 px-1">
					<div class="container-fluid">
						<div class="row">
							<div class="col-12">
								<div class="add-form">
									<div class="add-form-header pt-1 px-2" id="headingPartAttribute">
										<h2 class="h3 my-0 px-1 bp-1">Add New Part Attribute for #guid# #partLabel#</h2>
									</div>
									<div class="card-body">
										<form name="newPartAttribute" id="newPartAttribute" class="mb-1">
											<input type="hidden" name="collection_object_id" value="#attributes.partID#">
											<input type="hidden" name="method" value="createPartAttribute">
											<div class="row mx-0 pb-2">
												<div class=" col-12 col-md-3 px-1">
													<label for="attribute_type" class="data-entry-label">Attribute Type</label>
													<select name="attribute_type" id="attribute_type" class="data-entry-select reqdClr" required>
														<option value=""></option>
														<cfloop query="ctspecpart_attribute_type">
															<option value="#attribute_type#">#attribute_type#</option>
														</cfloop>
													</select>
												</div>
												<div class=" col-12 col-md-3 px-1">
													<label for="attribute_value" class="data-entry-label">Value</label>
													<input type="text" class="data-entry-input" id="attribute_value" name="attribute_value" value="">
												</div>
												<div class=" col-12 col-md-2 px-1">
													<label for="attribute_units" class="data-entry-label">Units</label>
													<input type="text" class="data-entry-input" id="attribute_units" name="attribute_units" value="">
												</div>
												<div class=" col-12 col-md-2 px-1">
													<label for="determined_by_agent" class="data-entry-label">Determiner</label>
													<input type="text" class="data-entry-input" id="determined_by_agent" name="determined_by_agent" value="#getCurrentUser.agent_name#">
													<input type="hidden" name="determined_by_agent_id" id="determined_by_agent_id" value="#getCurrentUser.agent_id#">
												</div>
												<div class=" col-12 col-md-2 px-1">
													<label for="determined_date" class="data-entry-label">Determined Date</label>
													<input type="text" class="data-entry-input" id="determined_date" name="determined_date" 
														placeholder="yyyy-mm-dd" value="#dateformat(now(),"yyyy-mm-dd")#">
												</div>
												<div class=" col-12 col-md-10 px-1 mt-1">
													<label for="attribute_remark" class="data-entry-label">Remarks (<span id="length_remark"></span>)</label>
													<textarea id="attribute_remark" name="attribute_remark" 
														onkeyup="countCharsLeft('attribute_remark', 4000, 'length_remark');"
														class="data-entry-textarea autogrow mb-1" maxlength="4000"></textarea>
												</div>
												<div class="col-12 col-md-2 px-1 pt-3 mt-1">
													<button id="newPartAttribute_submit" value="Create" class="btn btn-xs btn-primary" title="Create Part Attribute">Create Attribute</button>
													<output id="newPartAttribute_output"></output>
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
									// Add change listener to the attribute type select
									$('##attribute_type').on('change', function() {
										handlePartAttributeTypeChange("","#attributes.partID#");
									});
									// Add event listener to the save button
									$('##newPartAttribute_submit').on('click', function(event) {
										event.preventDefault();
										// Validate the form
										if ($('##newPartAttribute')[0].checkValidity() === false) {
											// If the form is invalid, show validation messages
											$('##newPartAttribute')[0].reportValidity();
											return false; // Prevent form submission if validation fails
										}
										setFeedbackControlState("newPartAttribute_output","saving");
										$.ajax({
											url: '/specimens/component/functions.cfc',
											type: 'POST',
											responseType: 'json',
											data: $('##newPartAttribute').serialize(),
											success: function(response) {
												console.log(response);
												setFeedbackControlState("newPartAttribute_output","saved");
												reloadEditExistingPartAttributes();
												// Clear form
												$('##newPartAttribute')[0].reset();
												// Reset value and units fields to text inputs and disable
												$('##attribute_value').replaceWith('<input type="text" class="data-entry-input" id="attribute_value" name="attribute_value" value="">');
												$('##attribute_units').replaceWith('<input type="text" class="data-entry-input" id="attribute_units" name="attribute_units" value="">');
												$('##attribute_value').prop('disabled', true);
												$('##attribute_units').prop('disabled', true);
											},
											error: function(xhr, status, error) {
												setFeedbackControlState("newPartAttribute_output","error");
												handleFail(xhr,status,error,"saving part attribute.");
											}
										});
									});
									function reloadEditExistingPartAttributes() {
										// reload the edit existing part attributes section
										$.ajax({
											url: '/specimens/component/functions.cfc',
											type: 'POST',
											dataType: 'html',
											data: {
												method: 'getEditExistingPartAttributesUnthreaded',
												partID: '#attributes.partID#'
											},
											success: function(response) {
												$('##editExistingPartAttributesDiv').html(response);
											},
											error: function(xhr, status, error) {
												handleFail(xhr,status,error,"reloading edit existing part attributes.");
											}
										});
									}
								</script>
								<!--- edit existing part attributes --->
								<div id="editExistingPartAttributesDiv">
									<!--- this div is replaced with the edit existing part attributes HTML when attributes are added --->
									#getEditExistingPartAttributesUnthreaded(partID=attributes.partID)#
								</div>
							</div>
						</div>
					</div>
				</div>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<p class="mt-2 text-danger">Error: #cfcatch.type# #error_message#</p>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
					<cfdump var="#cfcatch#">
				</cfif>
			</cfcatch>
			</cftry>
		</cfoutput> 
	</cfthread>
	<cfthread action="join" name="getEditPartAttributesThread" />
	<cfreturn getEditPartAttributesThread.output>
</cffunction>

<!--- 
 getEditExistingPartAttributesUnthreaded returns the HTML for the edit existing part attributes section, 
 intended to be used from within threaded getEditPartAttributesHTML or invoked independently to reload 
 just the edit existing part attributes section of the dialog.
 @param partID the part collection object id to obtain existing attributes for
 @return a string containing the HTML for the edit existing part attributes section
--->
<cffunction name="getEditExistingPartAttributesUnthreaded" returntype="string" access="remote" returnformat="plain">
	<cfargument name="partID" type="string" required="yes">

	<cfoutput>
		<cftry>
			<!--- Load controlled vocabulary for attribute types --->
			<cfquery name="ctspecpart_attribute_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT attribute_type 
				FROM ctspecpart_attribute_type 
				ORDER BY attribute_type
			</cfquery>
			
			<!--- lookup the collection code given the part ID --->
			<cfquery name="getCollectionCDE" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT cataloged_item.collection_cde 
				FROM specimen_part
					join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id 
				WHERE specimen_part.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.partID#">
			</cfquery>

			<!--- Get existing part attributes --->
			<cfquery name="getPartAttributes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT
					part_attribute_id,
					attribute_type,
					attribute_value,
					attribute_units,
					determined_date,
					determined_by_agent_id,
					attribute_remark,
					agent_name
				FROM
					specimen_part_attribute,
					preferred_agent_name
				WHERE
					specimen_part_attribute.determined_by_agent_id = preferred_agent_name.agent_id (+) AND
					collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.partID#">
				ORDER BY attribute_type, attribute_value
			</cfquery>
			
			<div class="row mx-0">
				<div class="bg-light p-2 col-12 row">
					<h1 class="h3">Edit Existing Part Attributes</h1>
					<div class="col-12 px-0 pb-3">
						<cfif getPartAttributes.recordCount EQ 0>
							<p>None</p>
						<cfelse>
							<cfset var i = 0>
							<cfloop query="getPartAttributes">
								<cfset i = i + 1>
								<div class="row mx-0 border py-1 mb-0">
									<form name="editPartAttribute#i#" id="editPartAttribute#i#" class="mb-1">
										<div class="col-12 row">
											<input type="hidden" name="part_attribute_id" value="#part_attribute_id#">
											<input type="hidden" name="method" value="updatePartAttribute">
											<div class="col-12 col-md-3">
												<cfset current = "<span class='small90'>(#getPartAttributes.attribute_type#)</span>"><!--- " --->
												<label for="attribute_type_#i#" class="data-entry-label">Attribute Type #current#</label>
												<select name="attribute_type" id="attribute_type_#i#" class="data-entry-select reqdClr" required
														onchange="handlePartAttributeTypeChange('_#i#', '#arguments.partID#')">
													<option value=""></option>
													<cfloop query="ctspecpart_attribute_type">
														<cfif ctspecpart_attribute_type.attribute_type EQ getPartAttributes.attribute_type>
															<cfset selected = "selected">
														<cfelse>
															<cfset selected = "">
														</cfif>
														<option value="#ctspecpart_attribute_type.attribute_type#" #selected#>#ctspecpart_attribute_type.attribute_type#</option>
													</cfloop>
												</select>
											</div>
											<div class="col-12 col-md-3" id="value_cell_#i#">
												#getPartAttrSelect('v', attribute_type, attribute_value, i)#
											</div>
											<div class="col-12 col-md-2" id="units_cell_#i#">
												#getPartAttrSelect('u', attribute_type, attribute_units, i)#
											</div>
											<div class="col-12 col-md-2">
												<label for="determined_date#i#" class="data-entry-label">Date Determined</label>
												<input type="text" class="data-entry-input" id="determined_date#i#" name="determined_date" 
													   value="#dateformat(determined_date,'yyyy-mm-dd')#" placeholder="yyyy-mm-dd">
											</div>
											<div class="col-12 col-md-2">
												<label for="determined_agent#i#" class="data-entry-label">Determined By</label>
												<input type="text" class="data-entry-input" id="determined_agent#i#" name="determined_agent" 
													   value="#agent_name#" placeholder="Pick agent">
												<input type="hidden" name="determined_by_agent_id" id="determined_by_agent_id#i#" value="#determined_by_agent_id#">
											</div>
											<div class="col-12 col-md-9 pt-1">
												<label for="attribute_remark#i#" class="data-entry-label">Remarks (<span id="length_remark_#i#"></span>)</label>
												<textarea id="attribute_remark#i#" name="attribute_remark" 
													onkeyup="countCharsLeft('attribute_remark#i#', 4000, 'length_remark_#i#');"
													class="data-entry-textarea autogrow mb-1" maxlength="4000"
												>#attribute_remark#</textarea>
											</div>
											<div class="col-12 col-md-3 pt-4">
												<button id="partAttribute_submit#i#" value="Save" class="btn btn-xs btn-primary" title="Save Part Attribute">Save</button>
												<button id="partAttribute_delete#i#" value="Delete" class="btn btn-xs btn-danger" title="Delete Part Attribute">Delete</button>
												<output id="partAttribute_output#i#"></output>
											</div>
										</div>
									</form>
								</div>

								<script>
									$(document).ready(function() {
										// make determined by agent autocomplete
										makeAgentAutocompleteMeta("determined_agent#i#", "determined_by_agent_id#i#");
										// setup date picker
										$("##determined_date#i#").datepicker({
											dateFormat: "yy-mm-dd",
											changeMonth: true,
											changeYear: true,
											showButtonPanel: true
										});
									});
								</script>
							</cfloop>
							<script>
								// Make all textareas with autogrow class be bound to the autogrow function on key up
								$(document).ready(function() { 
									$("textarea.autogrow").keyup(autogrow);
									$('textarea.autogrow').keyup();
								});
								// Add event listeners to the buttons
								document.querySelectorAll('button[id^="partAttribute_submit"]').forEach(function(button) {
									button.addEventListener('click', function(event) {
										event.preventDefault();
										// save changes to a part attribute
										var id = button.id.replace('partAttribute_submit', '');
										// check form validity
										if (!$("##editPartAttribute" + id).get(0).checkValidity()) {
											// If the form is invalid, show validation messages
											$("##editPartAttribute" + id).get(0).reportValidity();
											return false; // Prevent form submission if validation fails
										}
										var feedbackOutput = 'partAttribute_output' + id;
										setFeedbackControlState(feedbackOutput,"saving")
										$.ajax({
											url: '/specimens/component/functions.cfc',
											type: 'POST',
											dataType: 'json',
											data: $("##editPartAttribute" + id).serialize(),
											success: function(response) {
												setFeedbackControlState(feedbackOutput,"saved");
												reloadPartAttributes();
											},
											error: function(xhr, status, error) {
												setFeedbackControlState(feedbackOutput,"error")
												handleFail(xhr,status,error,"saving change to part attribute.");
											}
										});
									});
								});
								document.querySelectorAll('button[id^="partAttribute_delete"]').forEach(function(button) {
									button.addEventListener('click', function(event) {
										event.preventDefault();
										// delete a part attribute record
										var id = button.id.replace('partAttribute_delete', '');
										var feedbackOutput = 'partAttribute_output' + id;
										confirmDialog('Remove this part attribute? This action cannot be undone.', 'Confirm Delete Part Attribute', function() {
											setFeedbackControlState(feedbackOutput,"deleting")
											$.ajax({
												url: '/specimens/component/functions.cfc',
												type: 'POST',
												dataType: 'json',
												data: {
													method: 'deletePartAttribute',
													part_attribute_id: $("##editPartAttribute" + id + " input[name='part_attribute_id']").val()
												},
												success: function(response) {
													setFeedbackControlState(feedbackOutput,"deleted");
													reloadPartAttributes();
												},
												error: function(xhr, status, error) {
													setFeedbackControlState(feedbackOutput,"error")
													handleFail(xhr,status,error,"deleting part attribute.");
												}
											});
										});
									});
								});
								function reloadPartAttributes() {
									// reload the edit existing part attributes section
									$.ajax({
										url: '/specimens/component/functions.cfc',
										type: 'POST',
										dataType: 'html',
										data: {
											method: 'getEditExistingPartAttributesUnthreaded',
											partID: '#arguments.partID#'
										},
										success: function(response) {
											$('##editExistingPartAttributesDiv').html(response);
										},
										error: function(xhr, status, error) {
											handleFail(xhr,status,error,"reloading edit existing part attributes.");
										}
									});
								}
							</script>
						</cfif>
					</div>
				</div>
			</div>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<p class="mt-2 text-danger">Error: #cfcatch.type# #error_message#</p>
			<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
				<cfdump var="#cfcatch#">
			</cfif>
		</cfcatch>
		</cftry>
	</cfoutput>
</cffunction>

<!--- 
 getPartAttributeCodeTables lookup value and unit code tables for a given part attribute type.
 @param partID the part collection object id to obtain the collection by which to limit the code table values
 @param attribute_type the attribute type to obtain the code tables for
 @return a JSON object containing the attribute type, value code table, units code table, and the values for each
  with the values for each code table returned as a pipe delimited string
--->
<cffunction name="getPartAttributeCodeTables" returntype="any" access="remote" returnformat="json">
	<cfargument name="partID" type="string" required="yes">
	<cfargument name="attribute_type" type="string" required="yes">
	<cfset variables.partID = arguments.partID>
	<cfset variables.attribute_type = arguments.attribute_type>
	<cfset result = ArrayNew(1)>
	<cftry>
		<!--- Get collection info for the part --->
		<cfquery name="getPartCollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT 
				cataloged_item.collection_cde
			FROM specimen_part
				join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id 
			WHERE 
				specimen_part.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.partID#">
		</cfquery>
		
		<!--- Get the code tables for this attribute type --->
		<cfquery name="getPartAttributeCodeTables" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT
				attribute_type,
				upper(value_code_table) value_code_table,
				upper(unit_code_table) units_code_table
			FROM
				ctspec_part_att_att
			WHERE 
				attribute_type = <cfqueryparam value="#variables.attribute_type#" cfsqltype="CF_SQL_VARCHAR">
		</cfquery>
		
		<cfif getPartAttributeCodeTables.recordCount EQ 1>
			<cfset row = StructNew()>
			<cfset row["value_code_table"] = "#getPartAttributeCodeTables.value_code_table#">
			<cfset row["units_code_table"] = "#getPartAttributeCodeTables.units_code_table#">
			<cfset row["attribute_type"] = "#getPartAttributeCodeTables.attribute_type#">
			
			<!--- Handle value code table --->
			<cfif len(getPartAttributeCodeTables.value_code_table) GT 0>
				<cfset variables.table = getPartAttributeCodeTables.value_code_table>
				<!--- Default field name is the table name with CT prefix removed --->
				<cfset variables.field = replace(getPartAttributeCodeTables.value_code_table,"CT","","one")>
				
				<!--- check if the table has a collection_cde field --->
				<cfquery name="getValueFieldMetadata" datasource="uam_god">
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
					<cfif getValueFieldMetadata.ct GT 0>
					WHERE
						collection_cde = <cfqueryparam value="#getPartCollection.collection_cde#" cfsqltype="CF_SQL_VARCHAR">
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
			
			<!--- Handle units code table --->
			<cfif len(getPartAttributeCodeTables.units_code_table) GT 0>
				<cfset variables.unitsTable = getPartAttributeCodeTables.units_code_table>
				<cfset variables.unitsField = replace(getPartAttributeCodeTables.units_code_table,"CT","","one")>
				
				<!--- check if the units table has a collection_cde field --->
				<cfquery name="getUnitsFieldMetadata" datasource="uam_god">
					SELECT
						COUNT(*) as ct
					FROM
						sys.all_tab_columns
					WHERE
						table_name = <cfqueryparam value="#variables.unitsTable#" cfsqltype="CF_SQL_VARCHAR">
						AND owner = 'MCZBASE'
						AND column_name = 'COLLECTION_CDE'
				</cfquery>
				
				<cfquery name="getUnitsCodeTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT distinct
						#variables.unitsField# as value
					FROM
						#variables.unitsTable#
					<cfif getUnitsFieldMetadata.ct GT 0>
					WHERE
						collection_cde = <cfqueryparam value="#getPartCollection.collection_cde#" cfsqltype="CF_SQL_VARCHAR">
					</cfif>
					ORDER BY
						#variables.unitsField#
				</cfquery>
				<cfset units="">
				<cfloop query="getUnitsCodeTable">
					<cfset units = listAppend(units, getUnitsCodeTable.value, "|")>
				</cfloop>
				<cfset row["units_values"] = "#units#">
			</cfif>
			<cfset arrayAppend(result, row)>
		<cfelse>
			<!--- not found, therefore no code tables specified for that attribute type --->
			<cfset row = StructNew()>
			<cfset row["attribute_type"] = "#variables.attribute_type#">
			<cfset arrayAppend(result, row)>
		</cfif>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn serializeJSON(result)>
</cffunction>


<!--- createPartAttribute
 Creates a new part attribute record
 @param collection_object_id the collection_object_id for the specimen part to which the attribute applies
 @param attribute_type the type of attribute to create
 @param attribute_value the value of the attribute
 @param attribute_units the units of the attribute, optional
 @param determined_date the date the attribute was determined, optional
 @param determined_by_agent_id the agent who determined the attribute, optional
 @param attribute_remark any free text remarks about the attribute, optional
 @return JSON response with status = "saved" and the new part_attribute_id, or an http 500 response if an error occurs.
--->
<cffunction name="createPartAttribute" access="remote" returntype="any" returnformat="json">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="attribute_type" type="string" required="yes">
	<cfargument name="attribute_value" type="string" required="yes">
	<cfargument name="attribute_units" type="string" required="no" default="">
	<cfargument name="determined_date" type="string" required="no" default="">
	<cfargument name="determined_by_agent_id" type="string" required="no" default="">
	<cfargument name="attribute_remark" type="string" required="no" default="">

	<cfset var data = ArrayNew(1)>
	
	<cftransaction>
		<cftry>
			<cfquery name="insertAttr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insertAttr_result">
				INSERT INTO specimen_part_attribute (
					collection_object_id,
					attribute_type,
					attribute_value,
					attribute_units,
					determined_date,
					determined_by_agent_id,
					attribute_remark
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.attribute_type#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.attribute_value#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.attribute_units#" null="#len(arguments.attribute_units) EQ 0#">,
					<cfqueryparam cfsqltype="CF_SQL_DATE" value="#arguments.determined_date#" null="#len(arguments.determined_date) EQ 0#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.determined_by_agent_id#" null="#len(arguments.determined_by_agent_id) EQ 0#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.attribute_remark#" null="#len(arguments.attribute_remark) EQ 0#">
				)
			</cfquery>
			<!--- obtain the primary key value part_attribute_id of the newly created record using returned rowid --->
			<cfquery name="getNewPartAttributeID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getNewPartAttributeID_result">
				SELECT part_attribute_id 
				FROM specimen_part_attribute 
				WHERE
					ROWIDTOCHAR(rowid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#insertAttr_result.GENERATEDKEY#">
			</cfquery>
			<cfif getNewPartAttributeID_result.recordcount NEQ 1>
				<cfthrow message="Error retrieving new part attribute ID. Expected one row, but got #getNewPartAttributeID_result.recordcount#">
			</cfif>
			
			<cftransaction action="commit">
			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["id"] = "#getNewPartAttributeID.part_attribute_id#">
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
	
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- updatePartAttribute Updates an existing part attribute record
 @param part_attribute_id the primary key of the specimen_part_attribute to update
 @param attribute_type the new type of attribute to update
 @param attribute_value the new value of the attribute to update
 @param attribute_units the new units of the attribute, optional
 @param determined_date the new date the attribute was determined, optional
 @param determined_by_agent_id the new agent who determined the attribute, optional
 @param attribute_remark any new free text remarks about the attribute, optional
 @return JSON response with status = "saved" or an http 500 response if an error occurs.
--->
<cffunction name="updatePartAttribute" access="remote" returntype="any" returnformat="json">
	<cfargument name="part_attribute_id" type="string" required="yes">
	<cfargument name="attribute_type" type="string" required="yes">
	<cfargument name="attribute_value" type="string" required="yes">
	<cfargument name="attribute_units" type="string" required="no" default="">
	<cfargument name="determined_date" type="string" required="no" default="">
	<cfargument name="determined_by_agent_id" type="string" required="no" default="">
	<cfargument name="attribute_remark" type="string" required="no" default="">

	<cfset var data = ArrayNew(1)>
	
	<cftransaction>
		<cftry>
			<cfquery name="updateAttr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateAttr_result">
				UPDATE specimen_part_attribute 
				SET
					attribute_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.attribute_type#">,
					attribute_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.attribute_value#">,
					attribute_units = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.attribute_units#" null="#len(arguments.attribute_units) EQ 0#">,
					determined_date = <cfqueryparam cfsqltype="CF_SQL_DATE" value="#arguments.determined_date#" null="#len(arguments.determined_date) EQ 0#">,
					determined_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.determined_by_agent_id#" null="#len(arguments.determined_by_agent_id) EQ 0#">,
					attribute_remark = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.attribute_remark#" null="#len(arguments.attribute_remark) EQ 0#">
				WHERE 
					part_attribute_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.part_attribute_id#">
			</cfquery>
			<cfif updateAttr_result.recordcount NEQ 1>
				<cfthrow message="Error updating part attribute. Expected one row affected, but got #updateAttr_result.recordcount# with part_attribute_id #encodeForHtml(arguments.part_attribute_id)#">
			</cfif>
			
			<cftransaction action="commit">
			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["id"] = "#arguments.part_attribute_id#">
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
	
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- deletePartAttribute Deletes a part attribute record
 @param part_attribute_id the part_attribute_id to delete
 @return JSON response with status = "deleted" or an http 500 response if an error occurs.
--->
<cffunction name="deletePartAttribute" access="remote" returntype="any" returnformat="json">
	<cfargument name="part_attribute_id" type="string" required="yes">

	<cfset var data = ArrayNew(1)>
	
	<cftransaction>
		<cftry>
			<cfquery name="deleteAttr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="deleteAttr_result">
				DELETE FROM specimen_part_attribute 
				WHERE part_attribute_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.part_attribute_id#">
			</cfquery>
			<cfif deleteAttr_result.recordcount NEQ 1>
				<cfthrow message="Error deleting part attribute. Expected one row affected, but got #deleteAttr_result.recordcount# with part_attribute_id #encodeForHtml(arguments.part_attribute_id)#">
			</cfif>
			
			<cftransaction action="commit">
			<cfset row = StructNew()>
			<cfset row["status"] = "deleted">
			<cfset row["id"] = "#arguments.part_attribute_id#">
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
	
	<cfreturn #serializeJSON(data)#>
</cffunction>


<!--- getPartAttrSelect 
 Helper function to generate form controls for part attributes based on controlled vocabularies

 @param u_or_v string indicating whether to generate controls for units ('u') or values ('v')
 @param patype the attribute type to generate controls for
 @param val the current value to select
 @param paid the part attribute ID for naming form controls
 @return HTML string containing the appropriate form control or an http 500 response if an error occurs.
--->
<cffunction name="getPartAttrSelect" returntype="string" access="public">
	<cfargument name="u_or_v" type="string" required="yes">
	<cfargument name="patype" type="string" required="yes">
	<cfargument name="val" type="string" required="yes">
	<cfargument name="paid" type="numeric" required="yes">
	
	<cfset var retval = "">
	
	<cftry>
		<cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT * FROM ctspec_part_att_att 
			WHERE attribute_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.patype#">
		</cfquery>
		
		<cfif arguments.u_or_v EQ "v">
			<cfif len(k.VALUE_code_table) GT 0>
				<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT * FROM #k.VALUE_code_table#
				</cfquery>
				<cfloop list="#d.columnlist#" index="i">
					<cfif i NEQ "description" AND i NEQ "collection_cde">
						<cfquery name="r" dbtype="query">
							SELECT #i# AS d FROM d ORDER BY #i#
						</cfquery>
					</cfif>
				</cfloop>
				<cfsavecontent variable="retval">
					<cfset current = "<span class='small90'>(#arguments.val#)</span>"><!--- " --->
					<cfoutput>
						<label for="attribute_value_#arguments.paid#" class="data-entry-label">Value #current#</label>
						<select name="attribute_value" id="attribute_value_#arguments.paid#" class="data-entry-select reqdClr" required>
							<option value=""></option>
							<cfloop query="r">
								<cfif arguments.val EQ r.d>
									<cfset selected = "selected">
								<cfelse>
									<cfset selected = "">
								</cfif>
								<option value="#r.d#" #selected#>#r.d#</option>
							</cfloop>
						</select>
					</cfoutput>
				</cfsavecontent>
			<cfelse>
				<cfsavecontent variable="retval">
					<cfset current = "<span class='small90'>(#arguments.val#)</span>"><!--- " --->
					<cfoutput>
						<label for="attribute_value_#arguments.paid#" class="data-entry-label">Value#current#</label>
						<input type="text" name="attribute_value" id="attribute_value_#arguments.paid#" value="#arguments.val#" class="data-entry-input reqdClr" required>
					</cfoutput>
				</cfsavecontent>
			</cfif>
		<cfelseif arguments.u_or_v EQ "u">
			<cfif len(k.unit_code_table) GT 0>
				<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT * FROM #k.unit_code_table#
				</cfquery>
				<cfloop list="#d.columnlist#" index="i">
					<cfif i NEQ "description" AND i NEQ "collection_cde">
						<cfquery name="r" dbtype="query">
							SELECT #i# AS d FROM d ORDER BY #i#
						</cfquery>
					</cfif>
				</cfloop>
				<cfsavecontent variable="retval">
					<cfset current = "">
					<cfif len(arguments.val) GT 0>
						<cfset current = " <span class='small90'>(#arguments.val#)</span>"><!--- " --->
					</cfif>
					<cfoutput>
						<label for="attribute_units_#arguments.paid#" class="data-entry-label">Units#current#</label>
						<select name="attribute_units" id="attribute_units_#arguments.paid#" class="data-entry-select">
							<option value=""></option>
							<cfloop query="r">
								<cfif arguments.val EQ r.d>
									<cfset selected = "selected">
								<cfelse>
									<cfset selected = "">
								</cfif>
								<option value="#r.d#" #selected#>#r.d#</option>
							</cfloop>
						</select>
					</cfoutput>
				</cfsavecontent>
			<cfelse>
				<cfsavecontent variable="retval">
					<cfset current = "">
					<cfif len(arguments.val) GT 0>
						<cfset current = " <span class='small90'>(#arguments.val#)</span>"><!--- " --->
					</cfif>
					<cfoutput>
						<label for="attribute_units_#arguments.paid#" class="data-entry-label">Units#current#</label>
						<cfif len(arguments.val) GT 0>
							<cfset disabled="">
						<cfelse>
							<cfset disabled="disabled">
						</cfif>
						<input type="text" name="attribute_units" id="attribute_units_#arguments.paid#" value="#arguments.val#" class="data-entry-input" #disabled#>
					</cfoutput>
				</cfsavecontent>
			</cfif>
		</cfif>
		
	<cfcatch>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	
	<cfreturn retval>
</cffunction>

<!--- changeCollectingEvent backing function to change the collecting event for a cataloged item 
  @param collection_object_id the collection_object_id of the specimen part whose collecting event is to be changed
  @param collecting_event_id the new collecting_event_id to assign to the specimen part
  @return JSON object with success = true if successful, or an http 500 response if an error occurs.
--->
<cffunction name="changeCollectingEvent" access="remote" returntype="any" returnformat="json">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="collecting_event_id" type="string" required="yes">
	
	<cfset var result = StructNew()>
	
	<cftransaction>
		<cftry>
			<!--- Update the collecting_event_id for the specified cataloged item --->
			<cfquery name="updateCE" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateCE_result">
				UPDATE cataloged_item
				SET collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collecting_event_id#">
				WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">
			</cfquery>
			<cfif updateCE_result.recordcount NEQ 1>
				<cfthrow message="Error updating collecting event for cataloged item. Expected one row affected, but got #updateCE_result.recordcount# with collection_object_id #encodeForHtml(arguments.collection_object_id)#">
			</cfif>
			<cftransaction action="commit">
			<cfset result["success"] = true>
			<cfset result["message"] = "Collecting event updated successfully.">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn serializeJSON(result)>
</cffunction>

<!---getEditMaterialSampleIDsHTML obtain a block of html to populate a materialSampleID editor dialog for a specified specimen part,
 Does not allow editing of an existing internally assigned materialSampleID, only adding new ones or deleting user assigned ones.

 @param collection_object_id the collection_object_id for the specimen part for which to obtain the materialSampleId editor dialog.
 @return html for editing materialSampleIDs for the specified specimen part.
--->
<cffunction name="getEditMaterialSampleIDsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfset variables.collection_object_id = arguments.collection_object_id>
	<cfthread name="getEditMaterialSampleIDsThread">
		<cfoutput>
			<cftry>
				<cfquery name="getCatalog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT 
						collection.institution_acronym,
						cataloged_item.collection_cde,
						cataloged_item.cat_num,
						specimen_part.part_name,
						specimen_part.preserve_method,
						specimen_part.collection_object_id AS part_id
					FROM 
						specimen_part
						join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
						join collection on cataloged_item.collection_id = collection.collection_id
					WHERE 
						specimen_part.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">
				</cfquery>
				<cfquery name="getGuids" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT 
						GUID_OUR_THING_ID,
						TIMESTAMP_CREATED,
						TARGET_TABLE,
						CO_COLLECTION_OBJECT_ID,
						SP_COLLECTION_OBJECT_ID,
						TAXON_NAME_ID,
						RESOLVER_PREFIX,
						SCHEME,
						TYPE,
						AUTHORITY,
						LOCAL_IDENTIFIER,
						ASSEMBLED_IDENTIFIER,
						ASSEMBLED_RESOLVABLE,
						assigning_agent.agent_name ASSIGNED_BY,
						assigned_by_agent_id,
						creating_agent.agent_name CREATED_BY,
						LAST_MODIFIED,
						internal_fg,
						DISPOSITION,
						GUID_IS_A  
					FROM guid_our_thing
						left join preferred_agent_name assigning_agent on guid_our_thing.assigned_by_agent_id = assigning_agent.agent_id
						left join preferred_agent_name creating_agent on guid_our_thing.created_by_agent_id = creating_agent.agent_id
					WHERE
						sp_collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
				</cfquery>
				<div class="container-fluid">
					<div class="row">
						<div class="col-12">

							<!--- Add form --->
							<div class="add-form">
								<div class="add-form-header pt-1 px-2 col-12 float-left">
									<h2 class="h3 my-0 px-1 pb-1">Add dwc:materialSampleID for #getCatalog.institution_acronym#:#getCatalog.collection_cde#:#getCatalog.cat_num# #getCatalog.part_name# (#getCatalog.preserve_method#)</h2>
								</div>
								<div class="card-body mt-2">
									<form name="addMaterialSampleIDForm" id="addMaterialSampleIDForm" class="row mb-0 pt-1">
										<input type="hidden" name="sp_collection_object_id" value="#getCatalog.part_id#">
										<input type="hidden" name="method" value="addMaterialSampleID">
										<input type="hidden" name="returnformat" value="json">
										<input type="hidden" name="queryformat" value="column">
										<div class="form-row ml-3 mr-4 w-100">
											<div class="col-12 col-md-9 pl-0 pr-2">
												<label class="data-entry-label" for="input_text">dwc:materialSampleID assigned externally to this part</label>
												<input type="text" name="input_text" id="input_text" class="reqdClr data-entry-input">
												<!--- on entry of a value, parse it into the guid fields with parseGuid() --->
												<script>
													$(document).ready(function() {
														$("##input_text").on('change', function() { 
															$(".guidparsefield").show(); // show the parsed fields when a value is entered
															var bits = parseGuid($(this).val());
															console.log(bits);
															if (bits !== null) { 
																$("input[name='resolver_prefix']").val(bits.RESOLVER_PREFIX);
																$("input[name='scheme']").val(bits.SCHEME);
																$("input[name='type']").val(bits.TYPE);
																$("input[name='authority']").val(bits.AUTHORITY);
																$("input[name='local_identifier']").val(bits.LOCAL_IDENTIFIER);
																$("input[name='assembled_identifier']").val(bits.ASSEMBLED_IDENTIFIER);
																$("input[name='assembled_resolvable']").val(bits.ASSEMBLED_RESOLVABLE);
															} else {
																// clear all fields if parse failed
																$("input[name='resolver_prefix']").val("");
																$("input[name='scheme']").val("");
																$("input[name='type']").val("");
																$("input[name='authority']").val("");
																$("input[name='local_identifier']").val("");
																$("input[name='assembled_identifier']").val("");
																$("input[name='assembled_resolvable']").val("");
															}
														});
													});
													$(".guidparsefield").hide(); // hide the parsed fields by default
												</script>
											</div>
											<div class="col-12 col-md-3 px-1 guidparsefield">
												<label class="data-entry-label" for="resolver_prefix">Resolver Prefix</label>
												<input type="text" class="data-entry-input" name="resolver_prefix" id="resolver_prefix">
											</div>
											<div class="col-12 col-md-3 px-1 guidparsefield">
												<label class="data-entry-label" for="scheme">Scheme</label>
												<input type="text" class="data-entry-input" name="scheme" id="scheme">
											</div>
											<div class="col-12 col-md-3 px-1 guidparsefield">
												<label class="data-entry-label" for="type">Type</label>
												<input type="text" class="data-entry-input" name="type" id="type">
											</div>
											<div class="col-12 col-md-3 px-1 guidparsefield">
												<label class="data-entry-label" for="authority">Authority</label>
												<input type="text" class="data-entry-input" name="authority" id="authority">
											</div>
											<div class="col-12 col-md-3 px-1 guidparsefield">
												<label class="data-entry-label" for="local_identifier">Local Identifier</label>
												<input type="text" class="data-entry-input" name="local_identifier" id="local_identifier">
											</div>
											<div class="col-12 col-md-6 px-1 guidparsefield">
												<label class="data-entry-label" for="assembled_identifier">Full Identifier</label>
												<input type="text" class="data-entry-input" name="assembled_identifier" id="assembled_identifier">
											</div>
											<div class="col-12 col-md-6 px-1 guidparsefield">
												<label class="data-entry-label" for="assembled_resolvable">Resolvable Identifier</label>
												<input type="text" class="data-entry-input" name="assembled_resolvable" id="assembled_resolvable">
											</div>
											<div class="col-12 col-md-6 px-1 guidparsefield">
												<label class="data-entry-label" for="assigned_by">Assigned By</label>
												<input type="hidden" name="assigned_by_agent_id" value="">
												<input type="text" class="data-entry-input" name="assigned_by" id="assigned_by">
												<script>
													$(document).ready(function() {
														makeAgentAutocompleteMeta("assigned_by","assigned_by_agent_id",true);
													});
												</script>
											</div>
											<div class="col-12 col-md-6 px-1 guidparsefield">
												<button type="button" class="btn btn-primary mt-2" onclick="addOtherIDSubmit();">Add materialSampleID</button>
												<output id="addMaterialSampleIDResultDiv"></output>
											</div>
										</div>
									</form>
									<script>
										function addOtherIDSubmit() { 
											setFeedbackControlState("addMaterialSampleIDResultDiv","saving")
											$.ajax({
												url : "/specimens/component/functions.cfc",
												type : "post",
												dataType : "json",
												data: $("##addMaterialSampleIDForm").serialize(),
												success: function (result) {
													console.log(result);
													if (result && result[0] && result[0].status == "saved") {
														setFeedbackControlState("addMaterialSampleIDResultDiv","saved")
														reloadPartsAndSection();
													} else {
														// we shouldn't be able to reach this block, backing error should return an http 500 status
														setFeedbackControlState("addMaterialSampleIDResultDiv","error")
														messageDialog('Error adding materialSamleID ', 'Error saving materialSampleID.');
													}
												},
												error: function(jqXHR,textStatus,error){
													setFeedbackControlState("addMaterialSampleIDResultDiv","error")
													handleFail(jqXHR,textStatus,error,"adding new materialSampleID");
												}
											});
										};
									</script>
								</div>
							</div>

							<!--- List/Edit existing --->
							<cfset description="#getCatalog.institution_acronym#:#getCatalog.collection_cde#:#getCatalog.cat_num# #getCatalog.part_name# (#getCatalog.preserve_method#)">
							<div class="container-fluid">
								<div class="row">
									<div class="col-12 mt-0 bg-light border rounded pt-1 pb-0 px-3">
										<h1 class="h3">Existing dwc:MaterialSampleIDs</h1>
										<cfset i=1>
										<ul>
											<cfloop query="getGuids">
												<cfif resolver_prefix EQ "https://mczbase.mcz.harvard.edu/uuid/" AND scheme EQ "urn" AND type EQ "uuid">
													<cfif getGuids.internal_fg EQ 1>
														<!--- this is an internally assigned MCZbase UUID, not editable --->
														<cfset internal = true>
													<cfelse>
														<!--- this is an externally assigned UUID (which we can resolve), editable --->
														<cfset internal = false>
													</cfif>
												<cfelse>
													<cfset internal = false>
												</cfif>
												<li>
													<cfif internal>
														<strong>Internally assigned:</strong> #getGuids.assembled_identifier# 
														<span class="small90">(created #dateFormat(getGuids.timestamp_created,"mm/dd/yyyy")# by #getGuids.created_by#)</span>
													<cfelse>
														<strong>Externally assigned:</strong> #getGuids.assembled_identifier# 
														<span class="small90">(created #dateFormat(getGuids.timestamp_created,"mm/dd/yyyy")# by #getGuids.created_by#)</span>
														<!--- allow deletion of user assigned materialSampleIDs --->
														<button type="button" class="btn btn-sm btn-warning ml-2" title="Delete this materialSampleID" onclick="deleteGuidOurThing('#getGuids.guid_our_thing_id#','editMaterialSampleIDstatus_#getGuids.guid_our_thing_id#',reloadPartsAndSection);">Delete</button>
														<!--- allow edit of user assigned materialSampleIDs --->
														<button type="button" class="btn btn-sm btn-secondary ml-2" title="Edit this materialSampleID" onclick=" doOpenEdit_#getGuids.guid_our_thing_id#(); "
> Edit</button>
														<output id="editMaterialSampleIDstatus_#getGuids.guid_our_thing_id#"></output>
													</cfif>
													<script>
														function doOpenEdit_#getGuids.guid_our_thing_id#() { 
															openEditAMaterialSampleIDDialog('#getGuids.guid_our_thing_id#','materialSampleIDEditDialog1','#description#',reloadPartsAndSection);
															$("##materialSampleIDEditDialog").dialog("close"); 
														};
													</script>
											</cfloop>
										</ul>
									</div>
								</div>
							</div><!--- End of List/Edit existing --->

						</div>
					</div>
				</div>
			<cfcatch>
				<cfset function_called = "#GetFunctionCalledName()#">
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getEditMaterialSampleIDsThread"/>
	<cfreturn getEditMaterialSampleIDsThread.output>
</cffunction>

<!---
 * addMaterialSampleID insert a guid_our_thing record for a new materialSampleID, assumes this is an externally assigned ID.
 *
 * @param sp_collection_object_id the collection_object_id of the specimen part to which the new materialSampleID applies.
 * @param resolver_prefix the resolver prefix for the new guid
 * @param scheme the scheme for the new guid, e.g. urn
 * @param type the type for the new guid, e.g. uuuid
 * @param authority the authority part of the new guid
 * @param local_identifier the local identifier part of the new guid
 * @param assembled_identifier the full assembled identifier 
 * @param assembled_resolvable the resolvable uri form of the new guid
 * @param assigned_by source who assigned the materialSampleID
 * @param assigned_by_agent_id the agent_id of the source who assigned the materialSampleID
 *
 * @return a json structure with status=saved, or an http 500 response.
--->
<cffunction name="addMaterialSampleID" returntype="any" access="remote" returnformat="json">
	<cfargument name="sp_collection_object_id" type="string" required="yes">
	<cfargument name="resolver_prefix" type="string" required="no" default=''>
	<cfargument name="scheme" type="string" required="no" default="">
	<cfargument name="type" type="string" required="no" default="">
	<cfargument name="authority" type="string" required="no" default="">
	<cfargument name="local_identifier" type="string" required="no" default="">
	<cfargument name="assembled_identifier" type="string" required="no" default="">
	<cfargument name="assembled_resolvable" type="string" required="no" default="">
	<cfargument name="assigned_by" type="string" required="no" default="">
	<cfargument name="assigned_by_agent_id" type="string" required="no" default="">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="addMatSample" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="addMatSample_result">
				INSERT INTO guid_our_thing
				(
						GUID_IS_A,
						TARGET_TABLE,
						CO_COLLECTION_OBJECT_ID,
						SP_COLLECTION_OBJECT_ID,
						TAXON_NAME_ID,
						RESOLVER_PREFIX,
						SCHEME,
						TYPE,
						AUTHORITY,
						LOCAL_IDENTIFIER,
						ASSEMBLED_IDENTIFIER,
						ASSEMBLED_RESOLVABLE,
						assigned_by_agent_id,
						disposition,
						internal_fg,
						created_by_agent_id
				) VALUES (
					'materialSampleID',
					'SPECIMEN_PART',
					null,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.sp_collection_object_id#">,
					null,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.resolver_prefix#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.scheme#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.type#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.authority#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.local_identifier#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.assembled_identifier#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.assembled_resolvable#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.assigned_by_agent_id#">,
					'exists',
					0,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.myAgentID#">
				) 
			</cfquery>
			<cfif addMatSample_result.recordcount EQ 1>
				<!--- get new guid pk value --->
				<cfquery name="getPK" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getPK_result">
					SELECT guid_our_thing_id
					FROM guid_our_thing
					WHERE ROWIDTOCHAR(rowid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#addMatSample_result.GENERATEDKEY#">
				</cfquery>
				<cftransaction action="commit"/>
				<cfset row = StructNew()>
				<cfset row["status"] = "saved">
				<cfset row["id"] = "#getPK.guid_our_thing_id#">
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

<!---getEditAMaterialSampleIDHTML obtain a block of html to populate a materialSampleID editor dialog for a specified specimen part,
 Does not allow editing of an existing internally assigned materialSampleID, only adding new ones or deleting user assigned ones.

 @param collection_object_id the collection_object_id for the specimen part for which to obtain the materialSampleId editor dialog.
 @return html for editing materialSampleIDs for the specified specimen part.
--->
<cffunction name="getEditAMaterialSampleIDHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="guid_our_thing_id" type="string" required="yes">

	<cfset variables.guid_our_thing_id = arguments.guid_our_thing_id>
	<cfthread name="getEditMaterialSampleIDThread">
		<cfoutput>
			<cftry>
				<cfquery name="getCatalog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT 
						collection.institution_acronym,
						cataloged_item.collection_cde,
						cataloged_item.cat_num,
						specimen_part.part_name,
						specimen_part.preserve_method,
						specimen_part.collection_object_id AS part_id
					FROM 
						specimen_part
						join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
						join collection on cataloged_item.collection_id = collection.collection_id
						join guid_our_thing on guid_our_thing.sp_collection_object_id = specimen_part.collection_object_id
					WHERE 
						guid_our_thing.guid_our_thing_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.guid_our_thing_id#">
				</cfquery>
				<cfif getCatalog.recordcount EQ 0>
					<cfthrow message="No guid_our_thing record found with guid_our_thing_id #encodeForHtml(arguments.guid_our_thing_id)#">
				</cfif>
				<cfquery name="getGuid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT 
						GUID_OUR_THING_ID,
						TIMESTAMP_CREATED,
						TARGET_TABLE,
						CO_COLLECTION_OBJECT_ID,
						SP_COLLECTION_OBJECT_ID,
						TAXON_NAME_ID,
						RESOLVER_PREFIX,
						SCHEME,
						TYPE,
						AUTHORITY,
						LOCAL_IDENTIFIER,
						ASSEMBLED_IDENTIFIER,
						ASSEMBLED_RESOLVABLE,
						assigning_agent.agent_name ASSIGNED_BY,
						assigned_by_agent_id,
						creating_agent.agent_name CREATED_BY,
						LAST_MODIFIED,
						internal_fg,
						DISPOSITION,
						GUID_IS_A  
					FROM guid_our_thing
						left join preferred_agent_name assigning_agent on guid_our_thing.assigned_by_agent_id = assigning_agent.agent_id
						left join preferred_agent_name creating_agent on guid_our_thing.created_by_agent_id = creating_agent.agent_id
					WHERE
						guid_our_thing_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#guid_our_thing_id#">
				</cfquery>
				<!--- Edit existing --->
				<div class="container-fluid">
					<div class="row">
						<div class="pt-1 px-2 col-12 float-left">
							<div class="col-12 mt-0 bg-light border rounded pt-1 pb-0 px-3">
								<h2 classs="h3">Existing dwc:MaterialSampleID</h2>
								<ul>
									<li>
										For: #getCatalog.institution_acronym#:#getCatalog.collection_cde#:#getCatalog.cat_num# #getCatalog.part_name# (#getCatalog.preserve_method#)
									</li>
									<li>
										#getGuid.guid_is_a#: #getGuid.assembled_identifier#
									</li>
									<li>
										Created: #getGuid.timestamp_created# by #getGuid.created_by#
									</li>
									<cfif len(getGuid.last_modified) GT 0>
										<li>
											Last Modified: #getGuid.last_modified# 
										</li>
									</cfif>
								</ul>
								<cfloop query="getGuid">
									<form name="editMaterialSampleIDForm" id="editMaterialSampleIDForm" class="row mb-0 pt-1">
										<input type="hidden" name="sp_collection_object_id" value="#getCatalog.part_id#">
										<input type="hidden" name="guid_our_thing_id" value="#getGuid.guid_our_thing_id#">
										<input type="hidden" name="method" value="updateMaterialSampleID">
										<input type="hidden" name="returnformat" value="json">
										<input type="hidden" name="queryformat" value="column">
										<div class="form-row ml-3 mr-4 w-100">
											<div class="col-12 col-md-3 px-1">
												<label class="data-entry-label" for="resolver_prefix">Resolver Prefix</label>
												<input type="text" class="data-entry-input" name="resolver_prefix" id="resolver_prefix_edit" value="#getGuid.resolver_prefix#">
											</div>
											<div class="col-12 col-md-3 px-1">
												<label class="data-entry-label" for="scheme">Scheme</label>
												<input type="text" class="data-entry-input" name="scheme" id="scheme_edit" value="#getGuid.scheme#">
											</div>
											<div class="col-12 col-md-3 px-1">
												<label class="data-entry-label" for="type">Type</label>
												<input type="text" class="data-entry-input" name="type" id="type_edit" value="#getGuid.type#">
											</div>
											<div class="col-12 col-md-3 px-1">
												<label class="data-entry-label" for="authority">Authority</label>
												<input type="text" class="data-entry-input" name="authority" id="authority_edit" value="#getGuid.authority#">
											</div>
											<div class="col-12 col-md-3 px-1">
												<label class="data-entry-label" for="local_identifier">Local Identifier</label>
												<input type="text" class="data-entry-input" name="local_identifier" id="local_identifier_edit" value="#getGuid.local_identifier#">
											</div>
											<div class="col-12 col-md-6 px-1">
												<label class="data-entry-label" for="assembled_identifier">Full Identifier</label>
												<input type="text" class="data-entry-input" name="assembled_identifier" id="assembled_identifier_edit" value="#getGuid.assembled_identifier#">
											</div>
											<div class="col-12 col-md-6 px-1">
												<label class="data-entry-label" for="assembled_resolvable">Resolvable Identifier</label>
												<input type="text" class="data-entry-input" name="assembled_resolvable" id="assembled_resolvable_edit" value="#getGuid.assembled_resolvable#">
											</div>
											<div class="col-12 col-md-6 px-1">
												<label class="data-entry-label" for="assigned_by">Assigned By</label>
												<input type="hidden" name="assigned_by_agent_id" value="#getGuid.assigned_by_agent_id#" id="assigned_by_agent_id_edit">
												<input type="text" class="data-entry-input" name="assigned_by" id="assigned_by_edit" value="#getGuid.assigned_by#">
												<script>
													$(document).ready(function() {
														makeAgentAutocompleteMeta("assigned_by_edit","assigned_by_agent_id_edit",true);
													});
												</script>
											</div>
											<div class="col-12 col-md-6 px-1">
												<button type="button" class="btn btn-primary mt-2" onclick="editOtherIDSubmit();">Save</button>
												<output id="editMaterialSampleIDResultDiv"></output>
											</div>
										</div>
									</form>
									<script>
										function editOtherIDSubmit() { 
											setFeedbackControlState("editMaterialSampleIDResultDiv","saving")
											$.ajax({
												url : "/specimens/component/functions.cfc",
												type : "post",
												dataType : "json",
												data: $("##editMaterialSampleIDForm").serialize(),
												success: function (result) {
													console.log(result);
													if (result && result[0] && result[0].status == "saved") {
														setFeedbackControlState("editMaterialSampleIDResultDiv","saved");
														reloadPartsAndSection();
													} else {
														// we shouldn't be able to reach this block, backing error should return an http 500 status
														setFeedbackControlState("editMaterialSampleIDResultDiv","error");
														messageDialog('Error saving materialSamleID', 'Error saving materialSampleID.');
													}
												},
												error: function(jqXHR,textStatus,error){
													setFeedbackControlState("editMaterialSampleIDResultDiv","error")
													handleFail(jqXHR,textStatus,error,"saving materialSampleID");
												}
											});
										};
									</script>
								</cfloop>
							</div>
						</div>
					</div>
				</div>
			<cfcatch>
				<cfset function_called = "#GetFunctionCalledName()#">
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getEditMaterialSampleIDThread"/>
	<cfreturn getEditMaterialSampleIDThread.output>
</cffunction>

<!---
 * updateMaterialSampleID update a guid_our_thing record for a materialSampleID
 *
 * @param sp_collection_object_id the collection_object_id of the specimen part to which the materialSampleID applies.
 * @param guid_our_thing_id the primary key value of the record to update
 * @param resolver_prefix new the resolver prefix for the guid
 * @param scheme the new scheme for the guid, e.g. urn
 * @param type the new type for the guid, e.g. uuuid
 * @param authority the new authority part of the guid
 * @param local_identifier the new local identifier part of the guid
 * @param assembled_identifier the new full assembled identifier 
 * @param assembled_resolvable the new resolvable uri form of the guid
 * @param assigned_by source who assigned the materialSampleID
 * @param assigned_by_agent_id the agent_id of the source who assigned the materialSampleID
 *
 * @return a json structure with status=saved, or an http 500 response.
--->
<cffunction name="updateMaterialSampleID" returntype="any" access="remote" returnformat="json">
	<cfargument name="sp_collection_object_id" type="string" required="yes">
	<cfargument name="guid_our_thing_id" type="string" required="yes">
	<cfargument name="resolver_prefix" type="string" required="no" default=''>
	<cfargument name="scheme" type="string" required="no" default="">
	<cfargument name="type" type="string" required="no" default="">
	<cfargument name="authority" type="string" required="no" default="">
	<cfargument name="local_identifier" type="string" required="no" default="">
	<cfargument name="assembled_identifier" type="string" required="no" default="">
	<cfargument name="assembled_resolvable" type="string" required="no" default="">
	<cfargument name="assigned_by" type="string" required="no" default="">
	<cfargument name="assigned_by_agent_id" type="string" required="no" default="">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="updateMatSample" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateMatSample_result">
				UPDATE guid_our_thing
				SET
					GUID_IS_A = 'materialSampleID',
					TARGET_TABLE = 'SPECIMEN_PART',
					TAXON_NAME_ID = null,
					SP_COLLECTION_OBJECT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.sp_collection_object_id#">,
					CO_COLLECTION_OBJECT_ID = null,
					resolver_prefix = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.resolver_prefix#">,
					scheme = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.scheme#">,
					type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.type#">,
					authority = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.authority#">,
					local_identifier = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.local_identifier#">,
					assembled_identifier = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.assembled_identifier#">,
					assembled_resolvable = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.assembled_resolvable#">,
					assigned_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.assigned_by_agent_id#">,
					last_modified = CURRENT_DATE
				WHERE 
					guid_our_thing_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.guid_our_thing_id#">
			</cfquery>
			<cfif updateMatSample_result.recordcount EQ 1>
				<cftransaction action="commit"/>
				<cfset row = StructNew()>
				<cfset row["status"] = "saved">
				<cfset row["id"] = "#guid_our_thing_id#">
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

<!--- 
 * deleteGuidOurThing delete a guid_our_thing record.
 *
 * @param guid_our_thing_id the primary key value of the record to remove.
 *
 * @return a json structure with status=deleted, or an http 500 response.
--->
<cffunction name="deleteGuidOurThing" returntype="any" access="remote" returnformat="json">
	<cfargument name="guid_our_thing_id" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>	
			<cfquery name="deleteGuid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="deleteGuid_result">
				DELETE FROM guid_our_thing
				WHERE guid_our_thing_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.guid_our_thing_id#">
			</cfquery>
			<cfif deleteGuid_result.recordcount EQ 1>
				<cftransaction action="commit"/>
				<cfset row = StructNew()>
				<cfset row["status"] = "deleted">
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

<!---
 * addGuidOurThing insert a guid_our_thing record for any supported guid type, assumes this is an externally assigned ID.
 *
 * @param co_collection_object_id the collection_object_id of the specimen part to which the guid applies as an occurrenceID.
 * @param sp_collection_object_id the collection_object_id of the specimen part to which the guid applies as a materialSampleID.
 * @param taxon_name_id the taxon_name_id of the taxon to which the guid applies as a taxonID.
 * @param guid_is_a the type of guid, e.g. occurrenceID, materialSampleID, taxonID
 * @param target_table the target table for the guid, e.g. SPECIMEN_PART, TAXON_NAME	
 * @param resolver_prefix the resolver prefix for the new guid
 * @param scheme the scheme for the new guid, e.g. urn
 * @param type the type for the new guid, e.g. uuuid
 * @param authority the authority part of the new guid
 * @param local_identifier the local identifier part of the new guid
 * @param assembled_identifier the full assembled identifier 
 * @param assembled_resolvable the resolvable uri form of the new guid
 * @param assigned_by source who assigned the materialSampleID
 * @param assigned_by_agent_id the agent_id of the source who assigned the materialSampleID
 *
 * @return a json structure with status=saved, or an http 500 response.
--->
<cffunction name="addGuidOurThing" returntype="any" access="remote" returnformat="json">
	<cfargument name="co_collection_object_id" type="string" required="no">
	<cfargument name="sp_collection_object_id" type="string" required="no">
	<cfargument name="taxon_name_id" type="string" required="no">
   <cfargument name="guid_is_a" type="string" required="yes">
   <cfargument name="target_table" type="string" required="yes">
	<cfargument name="resolver_prefix" type="string" required="no" default=''>
	<cfargument name="scheme" type="string" required="no" default="">
	<cfargument name="type" type="string" required="no" default="">
	<cfargument name="authority" type="string" required="no" default="">
	<cfargument name="local_identifier" type="string" required="no" default="">
	<cfargument name="assembled_identifier" type="string" required="no" default="">
	<cfargument name="assembled_resolvable" type="string" required="no" default="">
	<cfargument name="assigned_by" type="string" required="no" default="">
	<cfargument name="assigned_by_agent_id" type="string" required="no" default="">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfset validParams = false>
			<!--- check that guid_is_a and target_table are a supported combination and have expected key --->
			<cfif (arguments.guid_is_a EQ "materialSampleID" AND arguments.target_table EQ "SPECIMEN_PART" AND StructKeyExists(arguments,"sp_collection_object_id") AND IsNumeric(arguments.sp_collection_object_id))>
				<cfset validParams = true>
				<cfif len(co_collection_object_id) GT 0>
					<cfthrow message="co_collection_object_id should not be provided when guid_is_a is materialSampleID">
				</cfif>
				<cfif len(taxon_name_id) GT 0>
					<cfthrow message="taxon_name_id should not be provided when guid_is_a is materialSampleID">
				</cfif>
			<cfelseif (arguments.guid_is_a EQ "occurrenceID" AND arguments.target_table EQ "SPECIMEN_PART" AND StructKeyExists(arguments,"co_collection_object_id") AND IsNumeric(arguments.co_collection_object_id))>
				<cfset validParams = true>
				<cfif len(sp_collection_object_id) GT 0>
					<cfthrow message="sp_collection_object_id should not be provided when guid_is_a is occurrenceID">
				</cfif>
				<cfif len(taxon_name_id) GT 0>
					<cfthrow message="taxon_name_id should not be provided when guid_is_a is occurrenceID">
				</cfif>
			<cfelseif (arguments.guid_is_a EQ "taxonID" AND arguments.target_table EQ "TAXONOMY" AND StructKeyExists(arguments,"taxon_name_id") AND IsNumeric(arguments.taxon_name_id))>
				<cfset validParams = true>
				<cfif len(sp_collection_object_id) GT 0>
					<cfthrow message="sp_collection_object_id should not be provided when guid_is_a is taxonID">
				</cfif>
				<cfif len(co_collection_object_id) GT 0>
					<cfthrow message="co_collection_object_id should not be provided when guid_is_a is taxonID">
				</cfif>
			</cfif>
			<cfif NOT validParams>
				<cfthrow message="Invalid combination or missing parameters for the specified guid_is_a and target_table combination.">
			</cfif>
			<cfquery name="addGuid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="addMatSampe_result">
				INSERT INTO guid_our_thing
				(
						GUID_IS_A,
						TARGET_TABLE,
						CO_COLLECTION_OBJECT_ID,
						SP_COLLECTION_OBJECT_ID,
						TAXON_NAME_ID,
						RESOLVER_PREFIX,
						SCHEME,
						TYPE,
						AUTHORITY,
						LOCAL_IDENTIFIER,
						ASSEMBLED_IDENTIFIER,
						ASSEMBLED_RESOLVABLE,
						ASSIGNED_BY_agent_id,
						disposition,
						CREATED_BY_agent_id,
						internal_fg
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.guid_is_a#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.target_table#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.co_collection_object_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.sp_collection_object_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.taxon_name_id#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.resolver_prefix#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.scheme#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.type#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.authority#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.local_identifier#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.assembled_identifier#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.assembled_resolvable#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.assigned_by_agent_id#">,
					'exists',
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.myAgentID#">,
					0
				) 
			</cfquery>
			<cfif addGuid_result.recordcount EQ 1>
				<!--- get new guid pk value --->
				<cfquery name="getPK" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getPK_result">
					SELECT guid_our_thing_id
					FROM guid_our_thing
					WHERE ROWIDTOCHAR(rowid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#addGuid_result.GENERATEDKEY#">
				</cfquery>
				<cftransaction action="commit"/>
				<cfset row = StructNew()>
				<cfset row["status"] = "saved">
				<cfset row["id"] = "#getPK.guid_our_thing_id#">
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

<!---
 * updateGuidOurThing update a guid_our_thing record.
 * @param co_collection_object_id the collection_object_id of the specimen part to which the guid applies as an occurrenceID.
 * @param sp_collection_object_id the collection_object_id of the specimen part to which the guid applies as a materialSampleID.
 * @param taxon_name_id the taxon_name_id of the taxon to which the guid applies as a taxonID.
 * @param guid_is_a the type of guid, e.g. occurrenceID, materialSampleID, taxonID
 * @param target_table the target table for the guid, e.g. SPECIMEN_PART, TAXON_NAME
 * @param guid_our_thing_id the primary key value of the record to update
 * @param resolver_prefix new the resolver prefix for the guid
 * @param scheme the new scheme for the guid, e.g. urn
 * @param type the new type for the guid, e.g. uuuid
 * @param authority the new authority part of the guid
 * @param local_identifier the new local identifier part of the guid
 * @param assembled_identifier the new full assembled identifier 
 * @param assembled_resolvable the new resolvable uri form of the guid
 * @param assigned_by source who assigned the materialSampleID
 * @param assigned_by_agent_id the agent_id of the source who assigned the materialSampleID
 *
 * @return a json structure with status=saved, or an http 500 response.
--->
<cffunction name="updateGuidOurThing" returntype="any" access="remote" returnformat="json">
	<cfargument name="sp_collection_object_id" type="string" required="no">
	<cfargument name="co_collection_object_id" type="string" required="no">
   <cfargument name="taxon_name_id" type="string" required="no">
   <cfargument name="guid_is_a" type="string" required="yes">
   <cfargument name="target_table" type="string" required="yes">
	<cfargument name="guid_our_thing_id" type="string" required="yes">
	<cfargument name="resolver_prefix" type="string" required="no" default=''>
	<cfargument name="scheme" type="string" required="no" default="">
	<cfargument name="type" type="string" required="no" default="">
	<cfargument name="authority" type="string" required="no" default="">
	<cfargument name="local_identifier" type="string" required="no" default="">
	<cfargument name="assembled_identifier" type="string" required="no" default="">
	<cfargument name="assembled_resolvable" type="string" required="no" default="">
	<cfargument name="assigned_by" type="string" required="no" default="">
	<cfargument name="assigned_by_agent_id" type="string" required="no" default="">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="updateGuid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateMatSampe_result">
				UPDATE guid_our_thing
				SET
					GUID_IS_A = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.guid_is_a#">,
					TARGET_TABLE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.target_table#">,
					TAXON_NAME_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.taxon_name_id#">,
					SP_COLLECTION_OBJECT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.sp_collection_object_id#">,
					CO_COLLECTION_OBJECT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.co_collection_object_id#">,
					resolver_prefix = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.resolver_prefix#">,
					scheme = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.scheme#">,
					type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.type#">,
					authority = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.authority#">,
					local_identifier = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.local_identifier#">,
					assembled_identifier = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.assembled_identifier#">,
					assembled_resolvable = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.assembled_resolvable#">,
					assigned_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.assigned_by_agent_id#">,
					last_modified = CURRENT_DATE
				WHERE 
					guid_our_thing_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.guid_our_thing_id#">
			</cfquery>
			<cfif updateGuid_result.recordcount EQ 1>
				<cftransaction action="commit"/>
				<cfset row = StructNew()>
				<cfset row["status"] = "saved">
				<cfset row["id"] = "#guid_our_thing_id#">
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
