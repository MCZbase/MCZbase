<!---
specimens/component/functions.cfc
Copyright 2019 President and Fellows of Harvard College
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
<!--- updateCondition update the condition on a part identified by the part's collection object id 
 @param part_id the collection_object_id for the part to update
 @param condition the new condition to update the part to 
 @return a json structure containing the part_id and a message, with "success" as the value of the message on a successful update.
--->
<cffunction name="updateCondition" access="remote" returntype="query">
	<cfargument name="part_id" type="numeric" required="yes">
	<cfargument name="condition" type="string" required="yes">
	<cftry>
		<cftransaction>
			<cfquery name="upIns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update coll_object 
				set
					condition = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#condition#">
				where
					COLLECTION_OBJECT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
			</cfquery>
		</cftransaction>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "success", 1)>
		<cfcatch>
			<cfset result = querynew("PART_ID,MESSAGE")>
			<cfset temp = queryaddrow(result,1)>
			<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
			<cfset temp = QuerySetCell(result, "message", "A query error occured: #cfcatch.Message# #cfcatch.Detail#", 1)>
		</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>

<!---getEditImagesHTML obtain a block of html to populate an images editor dialog for a specimen.
 @param collection_object_id the collection_object_id for the cataloged item for which to obtain the identification
	editor dialog.
 @return html for editing identifications for the specified cataloged item. 
--->
<cffunction name="getEditMediaHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
		<cfthread name="getEditMediaThread"> 
			<cfoutput>
			<cftry>
				<div class="container-fluid">
					<div class="row">
						<div class="col-12">
							<h1 class="h3 px-1"> Edit Media <a href="javascript:void(0);" onClick="getMCZDocs('media')"><i class="fa fa-info-circle"></i></a> </h1>
							<form name="editMediaForm" id="editMediaForm">
								<input type="hidden" name="method" value="updateMedia">
								<input type="hidden" name="returnformat" value="json">
								<input type="hidden" name="queryformat" value="column">
								<input type="hidden" name="media_id" value="column">
								<input type="hidden" name="collection_object_id" value="#collection_object_id#">
								<div class="col-12 col-lg-12 float-left mb-4 px-0">
								<div id="accordionImages1">
									<div class="card bg-light">
										<div class="card-header p-0" id="headingImg1">
											<h2 class="my-0 py-1 text-dark">
												<button type="button" class="headerLnk px-3 w-100 border-0 text-left collapsed" data-toggle="collapse" data-target="##collapseImg1" aria-expanded="false" aria-controls="collapseImg1">
													<span class="h3 px-2">Delete links to media</span> 
												</button>
											</h2>
										</div>
										<div id="collapseImg1" class="collapse" aria-labelledby="headingImg1" data-parent="##accordionImages1">
											<div class="card-body" id="mediaCardBody"> 
												<div class="row mx-0">
													<div class="col-12 px-0">
														<cfquery name="images" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
															SELECT
																media.media_id,
																media.media_uri,
																media.preview_uri,
																media.mime_type
															FROM
																media
																left join media_relations on media_relations.media_id = media.media_id
															WHERE
																media_relations.related_primary_key = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
														</cfquery>
													<cfset i = 1>
													<cfloop query="images">
														<div id="Media_#i#">
															<cfif len(images.media_uri) gt 0>
																<cfquery name="getImages" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
																	SELECT distinct
																		media.media_id,
																		media.auto_host,
																		media.auto_path,
																		media.auto_filename,
																		media.media_uri,
																		media.preview_uri as preview_uri,
																		media.mime_type as mime_type,
																		media.media_type,
																		mczbase.get_media_descriptor(media.media_id) as media_descriptor
																	FROM 
																		media,
																		media_relations
																	WHERE 
																		media_relations.media_id = media.media_id
																	AND
																		media.media_id = <cfqueryparam value="#images.media_id#" cfsqltype="CF_SQL_DECIMAL">
																</cfquery>
																<div class="col-6 float-left p-2">
																	<div class="col-12 px-1 col-md-6 mb-1 py-1 float-left">
																		<cfset mediaBlock= getMediaBlockHtml(media_id="#images.media_id#",displayAs="thumb")>
																		<div id="mediaBlock#images.media_id#">
																			#mediaBlock#
																		</div>
																	</div>
																</div>
																<script>
																	function editMediaSubmit(){
																		$('##deleteMediaResultDiv').html('Deleting....');
																		$('##deleteMediaResultDiv').addClass('text-warning');
																		$('##deleteMediaResultDiv').removeClass('text-success');
																		$('##deleteMediaResultDiv').removeClass('text-danger');
																		$.ajax({
																			url : "/specimens/component/functions.cfc",
																			type : "post",
																			dataType : "json",
																			data: $("##editMediaForm").serialize(),
																			success: function (result) {
																				if (typeof result.DATA !== 'undefined' && typeof result.DATA.STATUS !== 'undefined' && result.DATA.STATUS[0]=='1') { 
																					$('##deleteMediaResultDiv').html('Deleted');
																					$('##deleteMediaResultDiv').addClass('text-success');
																					$('##deleteMediaResultDiv').removeClass('text-warning');
																					$('##deleteMediaResultDiv').removeClass('text-danger');
																				} else {
																					// we shouldn't be able to reach this block, backing error should return an http 500 status
																					$('##deleteMediaResultDiv').html('Error');
																					$('##deleteMediaResultDiv').addClass('text-danger');
																					$('##deleteMediaResultDiv').removeClass('text-warning');
																					$('##deleteMediaResultDiv').removeClass('text-success');
																					messageDialog('Error updating images: '+result.DATA.MESSAGE[0], 'Error saving images.');
																				}
																			},
																			error: function(jqXHR,textStatus,error){
																				$('##deleteMediaResultDiv').html('Error');
																				$('##deleteMediaResultDiv').addClass('text-danger');
																				$('##deleteMediaResultDiv').removeClass('text-warning');
																				$('##deleteMediaResultDiv').removeClass('text-success');
																				handleFail(jqXHR,textStatus,error,"deleting relationship between image and cataloged item");
																			}
																		});
																	};
																</script> 
															<cfelse>
																	None
															</cfif>
														</div>
														<cfset i= i+1>
													</cfloop>
													</div>
												</div>
											</div>
										</div>
									</div>
								</div>
							</form>
						</div>
							<div class="col-12 col-lg-7 float-left px-0">
								<div id="accordionImg">
									<div class="card bg-light">
										<div class="card-header p-0" id="headingImg">
											<h2 class="my-0 py-1 text-dark">
												<button type="button" class="headerLnk px-3 w-100 border-0 text-left collapsed" data-toggle="collapse" data-target="##collapseImg" aria-expanded="false" aria-controls="collapseImg">
													<span class="h3 px-2">Add new media and link to this cataloged item</span> 
												</button>
											</h2>
										</div>
										<div id="collapseImg" class="collapse" aria-labelledby="heading1Im" data-parent="##accordionImg">
											<div class="card-body"> 
												<form name="newImgForm" id="newImgForm">
													<input type="hidden" name="Action" value="createNew">
													<input type="hidden" name="collection_object_id" value="#collection_object_id#" >
													<div class="row mx-0 mt-0 pt-2 pb-1">
														<div class="col-12 col-md-12 px-1">
															<label for="media_uri" class="data-entry-label" >Media URI</label>
															<input type="text" name="media_uri" id="media_uri" class="data-entry-input">
														</div>
													</div>
													<div class="row mx-0 mt-0 pt-2 pb-1">
														<div class="col-12 col-md-12 px-1">
															<label for="media_uri" class="data-entry-label" >Media URI</label>
															<input type="text" name="media_uri" id="media_uri" class="data-entry-input">
														</div>
													</div>
													<div class="row mx-0 mt-0 py-1">
														<div class="col-12 col-md-4 px-1">
															<label for="media_type" class="data-entry-label" >Media Type</label>
															<input type="text" name="media_type" id="media_type" class="data-entry-input">
														</div>
														<div class="col-12 col-md-4 px-1">
															<label for="mime_type" class="data-entry-label" >Mime Type</label>
															<input type="text" name="mime_type" id="mime_type" class="data-entry-input">
														</div>
														<div class="col-12 col-md-4 px-1">
															<label for="mask_media_fg" class="data-entry-label" >Visibility</label>
															<input type="text" name="mask_media_fg" id="mask_media_fg" class="data-entry-input">
														</div>
													</div>
													<div class="row mx-0 mt-0 py-1">
														<div class="col-12 col-md-12 px-1">
															<label for="media_license_id" class="data-entry-label mt-0" >License</label>
															<input type="text" name="media_license_id" id="media_license_id" class="data-entry-input">
														</div>
													</div>
													<div class="row mx-0 mt-0 pt-2 pb-1">
														<div class="col-12 col-md-4 px-1">
 															Form inputs to add relationship
														</div>
													</div>
													<div class="row mx-0 mt-0 py-1">
														<div class="col-12 px-0">
															Form inputs to add labels
														</div>
													</div>
													<div class="row mx-0 mt-0 py-1">
														<div class="col-12 col-md-12 px-1">
															<input type="button" value="Save" aria-label="Save Changes" class="btn btn-xs btn-primary"
															onClick=" editImagesSubmit(); ">
															<output id="saveImagesResultDiv" class="text-danger">&nbsp;</output>
														</div>
													</div>
													<script>
														function editImagesSubmit(){
															$('##saveImagesResultDiv').html('Saving....');
															$('##saveImagessResultDiv').addClass('text-warning');
															$('##saveImagesResultDiv').removeClass('text-success');
															$('##saveImagesResultDiv').removeClass('text-danger');
															$.ajax({
																url : "/specimens/component/functions.cfc",
																type : "post",
																dataType : "json",
																data: $("##editImagesForm").serialize(),
																success: function (result) {
																	if (typeof result.DATA !== 'undefined' && typeof result.DATA.STATUS !== 'undefined' && result.DATA.STATUS[0]=='1') { 
																		$('##saveImagesResultDiv').html('Saved');
																		$('##saveImagesResultDiv').addClass('text-success');
																		$('##saveImagesResultDiv').removeClass('text-warning');
																		$('##saveImagesResultDiv').removeClass('text-danger');
																	} else {
																		// we shouldn't be able to reach this block, backing error should return an http 500 status
																		$('##saveImagesResultDiv').html('Error');
																		$('##saveImagesResultDiv').addClass('text-danger');
																		$('##saveImagesResultDiv').removeClass('text-warning');
																		$('##saveImagesResultDiv').removeClass('text-success');
																		messageDialog('Error updating images history: '+result.DATA.MESSAGE[0], 'Error saving images history.');
																	}
																},
																error: function(jqXHR,textStatus,error){
																	$('##saveImagesResultDiv').html('Error');
																	$('##saveImagesResultDiv').addClass('text-danger');
																	$('##saveImagesResultDiv').removeClass('text-warning');
																	$('##saveImagesResultDiv').removeClass('text-success');
																	handleFail(jqXHR,textStatus,error,"saving changes to images history");
																}
															});
														};
													</script> 
												</form>
											</div>
										</div>
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

<!---getEditIdentificationsHTML obtain a block of html to populate an identification editor dialog for a specimen.
 @param collection_object_id the collection_object_id for the cataloged item for which to obtain the identification
	editor dialog.
 @return html for editing identifications for the specified cataloged item. 
--->
<cffunction name="getEditIdentificationsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
		<cfthread name="getEditIdentsThread"> 
			<cfoutput>
			<cftry>
				<cfquery name="ctnature" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select nature_of_id from ctnature_of_id
				</cfquery>
				<cfquery name="ctFormula" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select taxa_formula from cttaxa_formula order by taxa_formula
				</cfquery>
				<cfquery name="getIDs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT distinct
						identification.identification_id,
						institution_acronym,
						identification.scientific_name,
						cat_num,
						cataloged_item.collection_id,
						cataloged_item.collection_cde,
						made_date,
						nature_of_id,
						accepted_id_fg,
						identification_remarks,
						MCZBASE.GETSHORTCITATION(identification.publication_id) as formatted_publication,
						identification.publication_id,
						identification.sort_order,
						identification.stored_as_fg
					FROM
						cataloged_item
						left join identification on identification.collection_object_id = cataloged_item.collection_object_id
						left join collection on cataloged_item.collection_id=collection.collection_id
					WHERE
						cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
					ORDER BY 
						accepted_id_fg DESC, sort_order ASC
				</cfquery>
				<cfquery name="determiners" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT distinct
						agent_name, identifier_order, identification_agent.agent_id, identification_agent_id
					FROM
						identification_agent
						left join preferred_agent_name on identification_agent.agent_id = preferred_agent_name.agent_id
					WHERE
						identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getIDs.identification_id#">
					ORDER BY
						identifier_order
				</cfquery>
				<div class="container-fluid">
					<div class="row">
						<div class="col-12 float-left">
							<div class="col-12 float-left px-0">
								<div class="add-form float-left">
									<div class="add-form-header pt-1 px-2 col-12 float-left">
										<h2 class="h3 text-white my-0 px-1 pb-1">
											Add New Determination
										</h2>
									</div>
									<div class="card-body"> 
										<script>
											function idFormulaChanged(newFormula,baseId) { 
												if(newFormula.includes("B")) {
													$('##' + baseId).show();
													$('##'+baseId+'_label').show();
												} else { 
													$('##' + baseId).hide();
													$('##'+baseId+'_label').hide();
													$('##' + baseId).val("");
													$('##'+baseID+'_id').val("");
												}
											}
										</script>
										<form name="addForm" id="addForm">
											<input type="hidden" name="Action" value="createNew">
											<input type="hidden" name="collection_object_id" value="#collection_object_id#" >
											<div class="row float-left mx-1 mt-0 pt-2 pb-1">
												<div class="col-12 col-md-6 float-left px-0">
													<div class="col-12 col-md-3 px-1 float-left">
														<label for="taxa_formula" class="data-entry-label">ID Formula</label>
														<cfif not isdefined("taxa_formula")>
															<cfset taxa_formula='A'>
														</cfif>
														<select name="taxa_formula" id="taxa_formula" size="1" class="reqdClr w-100" required onchange="idFormulaChanged(this.value,'taxonb');">
															<cfset selected_value = "#taxa_formula#">
															<cfloop query="ctFormula">
																<cfif selected_value EQ ctFormula.taxa_formula>
																	<cfset selected = "selected='selected'">
																	<cfelse>
																	<cfset selected ="">
																</cfif>
																<option #selected# value="#ctFormula.taxa_formula#">#ctFormula.taxa_formula#</option>
															</cfloop>
														</select>
													</div>
													<div class="col-12 col-md-9 px-1 float-left">
														<label for="taxona" class="data-entry-label reqdClr" required>Taxon A</label>
														<input type="text" name="taxona" id="taxona" class="reqdClr data-entry-input">
														<input type="hidden" name="taxona_id" id="taxona_id">
													</div>
													<div class="col-12 col-md-8 px-1 d-none float-left">
														<label id="taxonb_label" for="taxonb" class="data-entry-label" style="display:none;">Taxon B</label>
														<input type="text" name="taxonb" id="taxonb" class="reqdClr w-100" size="50" style="display:none">
														<input type="hidden" name="taxonb_id" id="taxonb_id">
													</div>
												</div>
												<div class="col-12 col-md-6 px-1 float-left">	
													<div class="col-12 col-md-6 px-1 float-left">
														<label for="made_date" class="data-entry-label" >Date Identified</label>
														<input type="text" name="made_date" id="made_date" class="data-entry-input">
													</div>
													<div class="col-12 col-md-6 px-1 float-left">
														<label for="nature_of_id" class="data-entry-label mt-0" >Nature of ID <span class="infoLink" onClick="getCtDoc('ctnature_of_id',newID.nature_of_id.value)">Define</span></label>
														<select name="nature_of_id" id="nature_of_id" size="1" class="reqdClr w-100">
															<cfloop query="ctnature">
																<option <cfif #ctnature.nature_of_id# EQ "expert id">selected</cfif> value="#ctnature.nature_of_id#">#ctnature.nature_of_id#</option>
															</cfloop>
														</select>
													</div>
												</div>
								<div class="row col-12 mt-2 px-0 mx-0">
									<div class="col-12 col-md-6 px-1 float-left">
										<label for="identification_publication" class="data-entry-label" >Sensu</label>
										<input type="hidden" name="new_publication_id" id="new_publication_id">
										<input type="text" id="newPub" class="data-entry-input mb-1">
									</div>
									<div class="col-12 col-md-6 px-1 float-left">
										<label for="identification_remarks" class="data-entry-label mt-0" >Remarks</label>
										<input type="text" name="identification_remarks" id="identification_remarks" class="data-entry-input">
									</div>
								</div>
												<div class="col-12 col-md-12 px-0 float-left">
													<cfset idnum=1>
													<cfset i=1>
													<div class="col-12 col-md-6 px-0 my-1 float-left">
													<cfloop query="determiners">
														<div id="IdTr_#i#_#idnum#">
															<label for="IdBy_#i#_#idnum#" class="data-entry-label col-6 float-left">
															Identified By
															<h5 id="IdBy_#i#_#idnum#_view" class="d-inline infoLink">&nbsp;&nbsp;&nbsp;&nbsp;</h5>
															</label>
															<div class="col-12 col-md-12 px-1 float-left">
																<div class="input-group col-9 px-0 float-left">
																	<div class="input-group-prepend"> <span class="input-group-text smaller bg-lightgreen" id="IdBy_#i#_#idnum#_icon"><i class="fa fa-user" aria-hidden="true"></i></span> </div>
																	<input type="text" name="IdBy_#i#_#idnum#" id="IdBy_#i#_#idnum#" value="#encodeForHTML(agent_name)#" class="reqdClr data-entry-input form-control" >
																</div>
																<input type="hidden" name="IdBy_#i#_#idnum#_id" id="IdBy_#i#_#idnum#_id" value="#agent_id#" >
																<input type="hidden" name="identification_agent_id_#i#_#idnum#" id="identification_agent_id_#i#_#idnum#" value="#identification_agent_id#">
																<a aria-label="Add another Identifier" class="float-left btn btn-xs btn-primary addNewIDName col-3 px-0 rounded" onclick="addIdentAgentToForm(IdBy_#i#_#idnum#, IdBy_#i#_#idnum#_id,#agent_id#)" target="_self" href="javascript:void(0);">Add Name</a> 
															</div>
														</div>
														<script>
															makeRichAgentPicker("IdBy_#i#_#idnum#", "IdBy_#i#_#idnum#_id", "IdBy_#i#_#idnum#_icon", "IdBy_#i#_#idnum#_view", #agent_id#);
														</script> 
												
													<cfset idnum=idnum+1>
													</cfloop>
												</div>
												</div>
													
													
							
											<div id="addNewID" class="row mx-0"></div>
											<script>
												function addIdentAgentToForm(agent_id,agent_name) { 
													// add trans_agent record
													getIdent_agent(IdBy_#i#_#idnum#,IdBy_#i#_#idnum#_id,'##newID');
													// trigger save needed
													handleChange();
												}
											</script>
										
												<div class="col-12 col-md-12 py-2 mt-1 px-1 float-left">
													<button id="newID_submit" value="Create" class="btn btn-xs btn-primary" title="Create Identification">Create Identification</button>
												</div>
											
											<script>
												$(document).ready(function() {
													makeScientificNameAutocompleteMeta("taxona", "taxona_id");
													makeScientificNameAutocompleteMeta("taxonb", "taxonb_id");
													makeRichAgentPicker("newIdBy", "newIdBy_id", "newIdBy_icon", "newIdBy_view", null);
													makePublicationAutocompleteMeta("newPub", "new_publication_id");
												});
											</script>
										</form>
									</div>
								</div>
							</div>
							<div class="col-12 col-lg-12 float-left mt-4 mb-4 px-0">
								<form name="editIdentificationsForm" id="editIdentificationsForm">
									<input type="hidden" name="method" value="updateIdentifications">
									<input type="hidden" name="returnformat" value="json">
									<input type="hidden" name="queryformat" value="column">
									<input type="hidden" name="collection_object_id" value="#collection_object_id#">
									<h1 class="h3 mb-1 px-1"> Edit Existing Determinations <a href="javascript:void(0);" onClick="getMCZDocs('identification')"><i class="fa fa-info-circle"></i></a> </h1>
									<div class="row mx-0">
										<div class="col-12 px-0 float-left">
										
											<cfset i = 1>
											<cfset sortCount=getIds.recordcount - 1>
											<input type="hidden" name="number_of_ids" id="number_of_ids" value="#getIds.recordcount#">
											<cfloop query="getIds">
												<cfquery name="determiners" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
													SELECT distinct
														agent_name, identifier_order, identification_agent.agent_id, identification_agent_id
													FROM
														identification_agent
														left join preferred_agent_name on identification_agent.agent_id = preferred_agent_name.agent_id
													WHERE
														identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#identification_id#">
													ORDER BY
														identifier_order
												</cfquery>
												<cfset thisIdentification_id = #identification_id#>
												<input type="hidden" name="identification_id_#i#" id="identification_id_#i#" value="#identification_id#">
												<input type="hidden" name="number_of_determiners_#i#" id="number_of_determiners_#i#" value="#determiners.recordcount#">
												<div class="col-12 border bg-light px-3 rounded mt-0 mb-2 pt-2 pb-1 float-left">
													<div class="row mt-2">
														<div class="col-12 col-md-6 pr-0"> 
															<!--- TODO: A/B pickers --->
															<label for="scientific_name_#i#" class="data-entry-label">Scientific Name</label>
															<input type="text" name="scientific_name_#i#" id="scientific_name_#i#" class="data-entry-input" readonly="true" value="#scientific_name#">
														</div>
														<!--- TODO: make flippedAccepted() js function available --->
														<div class="col-12 col-md-4">
															<label for="accepted_id_fg_#i#" class="data-entry-label">Accepted</label>
															<cfif #accepted_id_fg# is 0>
																<cfset read = "">
																<cfset selected0 = "selected">
																<cfset selected1 = "">
																<cfelse>
																<cfset read = "readonly='true'">
																<cfset selected0 = "">
																<cfset selected1 = "selected">
															</cfif>
															<select name="accepted_id_fg_#i#" id="accepted_id_fg_#i#" size="1" #read# class="reqdClr w-50" onchange="flippedAccepted('#i#')">
																<option value="1" #selected1#>yes</option>
																<option value="0" #selected0#>no</option>
																<cfif #ACCEPTED_ID_FG# is 0>
																	<option value="DELETE">DELETE</option>
																</cfif>
															</select>
															<cfif #ACCEPTED_ID_FG# is 0>
																<span class="infoLink text-danger" onclick="document.getElementById('accepted_id_fg_#i#').value='DELETE';flippedAccepted('#i#');">Delete</span>
																<cfelse>
																<span>Current Identification</span>
															</cfif>
														</div>
													</div>
													<div class="row mt-2">
														<div class="col-12 px-0">
															<cfset idnum=1>
															<cfloop query="determiners">
																<div id="IdTr_#i#_#idnum#">
																	<div class="col-12">
																		<label for="IdBy_#i#_#idnum#">
																		Identified By
																		<h5 id="IdBy_#i#_#idnum#_view" class="d-inline infoLink">&nbsp;&nbsp;&nbsp;&nbsp;</h5>
																		</label>
																		<div class="col-12 px-0">
																			<div class="input-group col-6 px-0 float-left">
																				<div class="input-group-prepend"> <span class="input-group-text smaller bg-lightgreen" id="IdBy_#i#_#idnum#_icon"><i class="fa fa-user" aria-hidden="true"></i></span> </div>
																				<input type="text" name="IdBy_#i#_#idnum#" id="IdBy_#i#_#idnum#" value="#encodeForHTML(agent_name)#" class="reqdClr data-entry-input form-control" >
																			</div>
																			<input type="hidden" name="IdBy_#i#_#idnum#_id" id="IdBy_#i#_#idnum#_id" value="#agent_id#" >
																			<input type="hidden" name="identification_agent_id_#i#_#idnum#" id="identification_agent_id_#i#_#idnum#" value="#identification_agent_id#">
																			<a aria-label="Add another Identifier" class="float-left btn btn-xs btn-primary addIDName rounded mx-1" onclick="addIdentAgentToForm(IdBy_#i#_#idnum#, IdBy_#i#_#idnum#_id,#agent_id#)" target="_self" href="javascript:void(0);">Add Name</a> </div>
																	</div>
																	<script>
																		makeRichAgentPicker("IdBy_#i#_#idnum#", "IdBy_#i#_#idnum#_id", "IdBy_#i#_#idnum#_icon","IdBy_#i#_#idnum#_view",'#agent_id#');
																	</script> 
																</div>
																<!---This needs to get the next number from the loop and look up the agent from the database when add another identifier button is clicked//; I tried to create a js function to connect to the cf function but it wasn't working so I left it like this for now. The design idea is there for adding and removing identifiers.---> 
																<script>	
																	$(document).ready(function(){
																		$(".addIDName").click(function(){$("##newID").append('<div class="col-12"><label for="IdBy_#i#_#idnum#" class="data-entry-label mt-1">Identified By this one <h5 id="IdBy_#i#_#idnum#_view" class="d-inline infoLink">&nbsp;&nbsp;&nbsp;&nbsp;</h5></label><div class="col-12 px-0"><div class="input-group col-6 px-0 float-left"><div class="input-group-prepend"> <span class="input-group-text smaller bg-lightgreen" id="IdBy_#i#_#idnum#_icon"><i class="fa fa-user" aria-hidden="true"></i></span></div><input type="text" name="IdBy_#i#_#idnum#" id="IdBy_#i#_#idnum#" value="#encodeForHTML(determiners.agent_name)#" class="reqdClr data-entry-input form-control"></div><input type="hidden" name="IdBy_#i#_#idnum#_id" id="IdBy_#i#_#idnum#_id" value="#determiners.agent_id#"><input type="hidden" name="identification_agent_id_#i#_#idnum#" id="identification_agent_id_#i#_#idnum#" value="#determiners.identification_agent_id#"></div><button href="javascript:void(0);" arial-label="remove" class="btn data-entry-button px-2 mx-0 addIDName float-left remIDName"><i class="fas fa-times"></i></button></div></div></div>');
																		});
																		$("##newID").on('click','.remIDName',function(){$(this).parent().remove()});
																	});
																</script>
																<cfset idnum=idnum+1>
															</cfloop>
														</div>
													</div>
													<div id="newID" class="row"></div>
													<script>
														function addIdentAgentToForm(agent_id,agent_name) { 
															// add trans_agent record
															getIdent_agent(IdBy_#i#_#idnum#,IdBy_#i#_#idnum#_id,'##newID');
															// trigger save needed
															handleChange();
														}
													</script>
													<div class="row mt-2">
														<div class="col-12 col-md-3">
															<label for="made_date_#i#" class="data-entry-label">ID Date</label>
															<input type="text" value="#made_date#" name="made_date_#i#" id="made_date_#i#" class="data-entry-input">
														</div>
														<div class="col-12 col-md-3 px-0">
															<label for="nature_of_id_#i#" class="data-entry-label">Nature of ID <span class="infoLink" onClick="getCtDoc('ctnature_of_id',newID.nature_of_id.value)">Define</span></label>
															<cfset thisID = #nature_of_id#>
															<select name="nature_of_id_#i#" id="nature_of_id_#i#" size="1" class="reqdClr w-100">
																<cfloop query="ctnature">
																	<cfif #ctnature.nature_of_id# is #thisID#>
																		<cfset selected="selected='selected'">
																		<cfelse>
																		<cfset selected="">
																	</cfif>
																	<option #selected# value="#ctnature.nature_of_id#">#ctnature.nature_of_id#</option>
																</cfloop>
															</select>
														</div>
														<div class="col-12 col-md-6">
															<label for="publication_#i#" class="data-entry-label">Sensu</label>
															<!--- TODO: Cause clearing publication picker to clear id --->
															<input type="hidden" name="publication_id_#i#" id="publication_id_#i#" value="#publication_id#">
															<input type="text" id="publication_#i#" value='#encodeForHTML(formatted_publication)#' class="data-entry-input">
														</div>
													</div>
													<div class="row mt-2">
														<div class="col-12 col-md-12 mb-2">
															<label for="identification_remarks_#i#" class="data-entry-label">Remarks:</label>
															<input type="text" name="identification_remarks_#i#" id="identification_remarks_#i#" class="data-entry-input" value="#encodeForHtml(identification_remarks)#" >
														</div>
														<div class="col-12 col-md-3 mb-2">
															<cfif #accepted_id_fg# is 0>
																<label for="sort_order_#i#" class="data-entry-label">Sort Order:</label>
																<select name="sort_order_#i#" id="sort_order_#i#" size="1" class="w-100">
																	<option <cfif #sort_order# is ""> selected </cfif> value=""></option>
																	<cfloop index="X" from="1" to="#sortCount#">
																		<option <cfif #sort_order# is #X#> selected </cfif> value="#X#">#X#</option>
																	</cfloop>
																</select>
																<cfelse>
																<input type="hidden" name="sort_order_#i#" id="sort_order_#i#" value="">
															</cfif>
														</div>
														<div class="col-12 col-md-3 mt-3 mb-2">
															<cfif #accepted_id_fg# is 0>
																<label for="storedas_#i#" class="d-inline-block mt-1">Stored As</label>
																<input type="checkbox" class="data-entry-checkbox" name="storedas_#i#" id="storedas_#i#" value = "1" <cfif #stored_as_fg# EQ 1>checked</cfif> />
																<cfelse>
																<input type="hidden" name="storedas_#i#" id="storedas_#i#" value="0">
															</cfif>
														</div>
													</div>
													<script>
														$(document).ready(function() {
															//makeScientificNameAutocompleteMeta("taxona", "taxona_id");
															//makeScientificNameAutocompleteMeta("taxonb", "taxonb_id");
															makePublicationAutocompleteMeta("publication_#i#", "publication_id_#i#");
														});
													</script> 
												</div>
												<cfset i = #i#+1>
											</cfloop>
											<div class="col-12 mt-2 float-left">
												<input type="button" value="Save" aria-label="Save Changes" class="btn btn-xs btn-primary"
													onClick="if (checkFormValidity($('##editIdentificationsForm')[0])) { editIdentificationsSubmit();  } ">
												<output id="saveIdentificationsResultDiv" class="text-danger">&nbsp;</output>
											</div>
											<script>
												function editIdentificationsSubmit(){
													$('##saveIdentificationsResultDiv').html('Saving....');
													$('##saveIdentificationsResultDiv').addClass('text-warning');
													$('##saveIdentificationsResultDiv').removeClass('text-success');
													$('##saveIdentificationsResultDiv').removeClass('text-danger');
													$.ajax({
														url : "/specimens/component/functions.cfc",
														type : "post",
														dataType : "json",
														data: $("##editIdentificationsForm").serialize(),
														success: function (result) {
															if (typeof result.DATA !== 'undefined' && typeof result.DATA.STATUS !== 'undefined' && result.DATA.STATUS[0]=='1') { 
																$('##saveIdentificationsResultDiv').html('Saved');
																$('##saveIdentificationsResultDiv').addClass('text-success');
																$('##saveIdentificationsResultDiv').removeClass('text-warning');
																$('##saveIdentificationsResultDiv').removeClass('text-danger');
															} else {
																// we shouldn't be able to reach this block, backing error should return an http 500 status
																$('##saveIdentificationsResultDiv').html('Error');
																$('##saveIdentificationsResultDiv').addClass('text-danger');
																$('##saveIdentificationsResultDiv').removeClass('text-warning');
																$('##saveIdentificationsResultDiv').removeClass('text-success');
																messageDialog('Error updating identification history: '+result.DATA.MESSAGE[0], 'Error saving identification history.');
															}
														},
														error: function(jqXHR,textStatus,error){
															$('##saveIdentificationsResultDiv').html('Error');
															$('##saveIdentificationsResultDiv').addClass('text-danger');
															$('##saveIdentificationsResultDiv').removeClass('text-warning');
															$('##saveIdentificationsResultDiv').removeClass('text-success');
															handleFail(jqXHR,textStatus,error,"saving changes to identification history");
														}
													});
												};
											</script> 
										</div>
									</div>
								</form>
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
	<cfthread action="join" name="getEditIdentsThread" />
	<cfreturn getEditIdentsThread.output>
</cffunction>
<!--- function updateIdentifications update the identifications for an arbitrary number of identifications in the identification history of a collection object 
	@param collection_object_id the collecton object to which the identification history pertains
	@param number_of_ids the number of determinations in the identification history
--->
<cffunction name="updateIdentifications" returntype="any" access="remote" returnformat="json">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfoutput> 
		<!--- disable trigger that enforces one and only one stored as flag, can't be done inside cftransaction as datasource is different --->
		<cftry>
			<cfquery datasource="uam_god">
				alter trigger tr_stored_as_fg disable
			</cfquery>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
				<cfabort>
			</cfcatch>
		</cftry>
		<cftransaction>
			<!--- perform the updates on the arbitary number of identifications --->
			<cftry>
				<cfloop from="1" to="#NUMBER_OF_IDS#" index="n">
					<cfset thisAcceptedIdFg = #evaluate("ACCEPTED_ID_FG_" & n)#>
					<cfset thisIdentificationId = #evaluate("IDENTIFICATION_ID_" & n)#>
					<cfset thisIdRemark = #evaluate("IDENTIFICATION_REMARKS_" & n)#>
					<cfset thisMadeDate = #evaluate("MADE_DATE_" & n)#>
					<cfset thisNature = #evaluate("NATURE_OF_ID_" & n)#>
					<cfset thisNumIds = #evaluate("NUMBER_OF_DETERMINERS_" & n)#>
					<cfset thisPubId = #evaluate("publication_id_" & n)#>
					<cfset thisSortOrder = #evaluate("sort_order_" & n)#>
					<cfif #isdefined("storedas_" & n)#>
						<cfset thisStoredAs = #evaluate("storedas_" & n)#>
						<cfelse>
						<cfset thisStoredAs = 0>
					</cfif>
					<cfif thisAcceptedIdFg is 1>
						<cfquery name="upOldID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							UPDATE identification 
							SET ACCEPTED_ID_FG=0 
							where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
						</cfquery>
						<cfquery name="newAcceptedId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							UPDATE identification 
							SET ACCEPTED_ID_FG=1, sort_order = null 
							where identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisIdentificationId#">
						</cfquery>
						<cfset thisStoredAs = 0>
					</cfif>
					<cfif thisStoredAs is 1>
						<cfquery name="upStoredASID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							UPDATE identification 
							SET STORED_AS_FG=0 
							where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
						</cfquery>
						<cfquery name="newStoredASID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							UPDATE identification 
							SET STORED_AS_FG=1 
							where identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisIdentificationId#">
						</cfquery>
						<cfelse>
						<cfquery name="newStoredASID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							UPDATE identification 
							SET STORED_AS_FG=0 
							where identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisIdentificationId#">
						</cfquery>
					</cfif>
					<cfif thisAcceptedIdFg is "DELETE">
						<cfquery name="deleteId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							DELETE FROM identification_agent
							WHERE identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisIdentificationId#">
						</cfquery>
						<cfquery name="deleteTId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							DELETE FROM identification_taxonomy 
							WHERE identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisIdentificationId#">
						</cfquery>
						<cfquery name="deleteId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							DELETE FROM identification 
							WHERE identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisIdentificationId#">
						</cfquery>
						<cfelse>
						<cfquery name="updateId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							UPDATE identification SET
								nature_of_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisNature#">,
								made_date = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisMadeDate#">,
								identification_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#(thisIdRemark)#">
								<cfif len(thisPubId) gt 0>
									,publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisPubId#">
								<cfelse>
									,publication_id = NULL
								</cfif>
								<cfif len(thisSortOrder) gt 0>
									,sort_order = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisSortOrder#">
								<cfelse>
									,sort_order = NULL
								</cfif>
							where identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisIdentificationId#">
						</cfquery>
						<cfloop from="1" to="#thisNumIds#" index="nid">
							<cftry>
								<!--- couter does not increment backwards - may be a few empty loops in here ---->
								<cfset thisIdId = evaluate("IdBy_" & n & "_" & nid & "_id")>
								<cfcatch>
									<cfset thisIdId =-1>
								</cfcatch>
							</cftry>
							<cftry>
								<cfset thisIdAgntId = evaluate("identification_agent_id_" & n & "_" & nid)>
								<cfcatch>
									<cfset thisIdAgntId=-1>
								</cfcatch>
							</cftry>
							<cfif #thisIdAgntId# is -1 and (thisIdId is not "DELETE" and thisIdId gte 0)>
								<!--- new determiner --->
								<cfquery name="updateIdA" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									INSERT INTO identification_agent
									( 
										IDENTIFICATION_ID,
										AGENT_ID,
										IDENTIFIER_ORDER 
									) VALUES (
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisIdentificationId#">,
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisIdId#">,
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#nid#">
									)
								</cfquery>
								<cfelse>
								<!--- update or delete --->
								<cfif #thisIdId# is "DELETE">
									<!--- delete --->
									<cfquery name="updateIdA" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
										DELETE FROM identification_agent
										WHERE identification_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisIdAgntId#">
									</cfquery>
									<cfelseif thisIdId gte 0>
									<!--- update --->
									<cfquery name="updateIdA" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
										UPDATE identification_agent sET
											agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisIdId#">,
											identifier_order = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#nid#">
										 WHERE
										 	identification_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisIdAgntId#">
									</cfquery>
								</cfif>
							</cfif>
						</cfloop>
					</cfif>
				</cfloop>
				<cftransaction action="commit">
				<cfset data=queryNew("status, message, id")>
				<cfset t = queryaddrow(data,1)>
				<cfset t = QuerySetCell(data, "status", "1", 1)>
				<cfset t = QuerySetCell(data, "message", "Record updated.", 1)>
				<cfset t = QuerySetCell(data, "id", "#collection_object_id#", 1)>
				<cfreturn data>
				<cfcatch>
					<cftransaction action="rollback">
					<cfset error_message = cfcatchToErrorMessage(cfcatch)>
					<cfset function_called = "#GetFunctionCalledName()#">
					<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
					<cfabort>
				</cfcatch>
			</cftry>
		</cftransaction>
		<cftry>
			<!--- re-enable trigger that enforces one and only one stored as flag, can't be done inside cftransaction as datasource is different --->
			<cfquery datasource="uam_god">
				alter trigger tr_stored_as_fg enable
			</cfquery>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
				<cfabort>
			</cfcatch>
		</cftry>
	</cfoutput>
</cffunction>

<!---function getEditIdentificationHtml obtain an html block to popluate an edit dialog for an identification 
 @param identification-id the identification.identification_id to edit.
 @return html for editing the identification 
--->
<cffunction name="getEditIdentificationHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="identification_id" type="string" required="yes">
	<cfthread name="getIdentificationThread">
		<cftry>
			<cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
										<div class="form-group w-25 mb-3 float-left">
											<label for="taxa_formula">Formula:</label>
											<select class="border custom-select form-control input-sm" id="select">
												<option value="" disabled="" selected="">#taxa_formula#</option>
												<!--- TODO: Shouldn't this be from a code table? --->
												<option value="A">A</option>
												<option value="B">B</option>
												<option value="sp.">sp.</option>
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

<cffunction name="saveID" access="remote" returntype="any" returnformat="json">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="identification_id" type="string" required="yes">
	<cfargument name="scientific_name" type="string" required="no">
	<cfargument name="accepted_ID_fg" type="string" required="yes">
	<cfargument name="identified_by" type="string" required="yes">
	<cfargument name="made_date" type="string" required="no">
	<cfargument name="nature_of_id" type="string" required="yes">
	<cfargument name="stored_as_fg" type="string" required="yes">
	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="updateIdentificationCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="newIdentificationCheck_result">
				SELECT count(*) as ct from identification
				WHERE
					IDENTIFICATION_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value='#identification_id#'>
			</cfquery>
			<cfif updateIdentificationCheck.ct NEQ 1>
				<cfthrow message = "Unable to update identification. Provided identification_id does not match a record in the ID table.">
			</cfif>
			<cfquery name="updateIdentification" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateIdentification">
				UPDATE identification SET
					identification_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#identification_id#">,
					MADE_DATE = <cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#dateformat(made_date,'yyyy-mm-dd')#">,
					NATURE_OF_ID = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#nature_of_id#">,
					STORED_AS_FG = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#STORED_AS_FG#">,
					SORT_ORDER = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#sort_order#">,
					Taxa_formula = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#taxa_formula#">
					<cfif isDefined("identification_remarks")>
						, identification_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#identification_remarks#">
					</cfif>
				where
					identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#identification_id#">
			</cfquery>
			<cfloop from="1" to="#numAgents#" index="n">
				<cfif IsDefined("identification_agent_id_" & n) >
					<cfset trans_agent_id_ = evaluate("identification_agent_id_" & n)>
					<cfset agent_id_ = evaluate("agent_id_" & n)>
					<cftry>
						<cfset del_agnt_=evaluate("del_agnt_" & n)>
						<cfcatch>
							<cfset del_agnt_=0>
						</cfcatch>
					</cftry>
					<cfif del_agnt_ is "1" and isnumeric(trans_agent_id_) and identification_agent_id_ gt 0>
						<cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							delete from identification_agent 
							where identification_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#identification_agent_id_#">
						</cfquery>
						<cfelse>
						<cfif len(agent_id_) GT 0>
							<!--- don't try to add/update a blank row --->
							<cfif identification_agent_id_ is "new" and del_agnt_ is 0>
								<cfquery name="newIdentificationAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									insert into identification_agent (
										identification_id,
										agent_id,
										identification_order,
										identification_agent_id
									) values (
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">,
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id_#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#identification_order_#">
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#identification_agent_id_#">
									)
								</cfquery>
								<cfelseif del_agnt_ is 0>
								<cfquery name="upIdentificationAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									update identification_agent set
										agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id_#">,
										identification_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#identification_id_#">
									where
										identification_agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#identification_agent_id_#">
								</cfquery>
							</cfif>
						</cfif>
					</cfif>
				</cfif>
			</cfloop>
			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["id"] = "#identification_id#">
			<cfset data[1] = row>
			<cftransaction action="commit">
			<cfcatch>
				<cftransaction action="rollback">
				<cfif isDefined("cfcatch.queryError") >
					<cfset queryError=cfcatch.queryError>
					<cfelse>
					<cfset queryError = ''>
				</cfif>
				<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfheader statusCode="500" statusText="#message#">
				<cfoutput>
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
				<cfabort>
			</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>
<!---getEditOtherIDsHTML obtain a block of html to populate an other ids editor dialog for a specimen.
 @param collection_object_id the collection_object_id for the cataloged item for which to obtain the other ids editor dialog.
 @return html for editing other ids for the specified cataloged item. 
--->
						
<!--- TODO: Metadata references updateImages and then identifications and identification history on updateMedia function --->
<!---TEST function updateImages update the test images block for an arbitrary number of identifications in the identification history of a collection object 
	@param collection_object_id the collecton object to which the identification history pertains
	@param number_of_ids the number of determinations in the identification history
--->
<cffunction name="updateMedia" returntype="any" access="remote" returnformat="json">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="mediaidnum" type="string" required="yes">
	<cfoutput> 
		<cftransaction>
			<!--- perform the updates on the arbitary number of media records --->
			<cftry>
				<cfset n = 1>
				<cfloop from="1" to="#mediaidnum#" index="n">
					<cfset thisMedia_uri = #evaluate("MEDIA_URI_" & n)#>
					<cfset thisPreview_uri = #evaluate("PREVIEW_URI_" & n)#>
					<cfset thisMedia_type = #evaluate("MEDIA_TYPE_" & n)#>
					<cfset thisMime_type = #evaluate("MIME_TYPE_" & n)#>
					<cfset thisMask_media_fg = #evaluate("MASK_MEDIA_FG_" & n)#>
					<cfset thisMedia_license_id = #evaluate("MEDIA_LICENSE_ID_" & n)#>
					<cfset thisMedia_relations_id = #evaluate("MEDIA_RELATIONS_ID_" & n)#>
					<cfset thisMedia_label_id = #evaluate("MEDIA_LABEL_ID_" & n)#>
					<cfif thisMedia_relations_id is "DELETE">
						<cfquery name="deleteId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							DELETE FROM media_relations
							WHERE media_relations_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisMedia_relations_id#">
						</cfquery>
					<cfelse>
						<cfquery name="updateId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							UPDATE media SET
								MEDIA_URI = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisMedia_uri#">,
								PREVIEW_URI = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisPreview_uri#">,
								MEDIA_TYPE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisMedia_type#">
								MIME_TYPE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisMime_type#">
								MEDIA_LICENSE_ID = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisMedia_license_id#">
								MASK_MEDIA_FG = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisMedia_license_id#">
							WHERE media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisMedia_id#">
						</cfquery>
					</cfif>
				</cfloop>
				<cftransaction action="commit">
				<cfset data=queryNew("status, message, id")>
				<cfset t = queryaddrow(data,1)>
				<cfset t = QuerySetCell(data, "status", "1", 1)>
				<cfset t = QuerySetCell(data, "message", "Record updated.", 1)>
				<cfset t = QuerySetCell(data, "id", "#collection_object_id#", 1)>
				<cfreturn data>
				<cfcatch>
					<cftransaction action="rollback">
					<cfset error_message = cfcatchToErrorMessage(cfcatch)>
					<cfset function_called = "#GetFunctionCalledName()#">
					<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
					<cfabort>
				</cfcatch>
			</cftry>
		</cftransaction>
	</cfoutput>
</cffunction>
<!--- TODO: Identify cause of duplication and remove --->
<!---TEST function getEditMediaHtml obtain an html block to popluate an edit dialog for images
 @param media_id the media.media_id to edit.
 @return html for editing the media record 
--->
<cffunction name="getEditMediaHTMLDuplicate" returntype="string" access="remote" returnformat="plain">
	<!--- TODO: This is a duplicate of getEditMediaHTML with less content --->
	<cfargument name="media_id" type="string" required="yes">
	<cfthread name="getMediaThread">
		<cftry>
			<cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 1 as status, media.media_id, media.media_uri,media.preview_uri, media.media_type, media.mime_type, media.mask_media_fg, media.media_license_id 
				FROM 
					media
					left join media_relations on  media_relations.media_id=media.media_id  
					left join media_labels on media_labels.media_id = media_relations.media_id
				WHERE 	
					media.media_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
				ORDER BY 
					media_id
			</cfquery>
			<cfoutput>
				<div id="mediaHTML">
					<cfloop query="theResult">
						<div class="mediaExistingForm">
							<form>
								<div class="container pl-1">
									<div class="row mx-0 mt-0 pt-2 pb-1">
										<div class="col-12 col-md-12 px-1">
											<label for="media_uri" class="data-entry-label" >Media URI</label>
											<input type="text" name="media_uri" id="media_uri" class="data-entry-input">
										</div>
									</div>
									<div class="row mx-0 mt-0 pt-2 pb-1">
										<div class="col-12 col-md-12 px-1">
											<label for="media_uri" class="data-entry-label" >Media URI</label>
											<input type="text" name="media_uri" id="media_uri" class="data-entry-input">
										</div>
									</div>
									<div class="row mx-0 mt-0 py-1">
										<div class="col-12 col-md-4 px-1">
											<label for="media_type" class="data-entry-label" >Media Type</label>
											<input type="text" name="media_type" id="media_type" class="data-entry-input">
										</div>
										<div class="col-12 col-md-4 px-1">
											<label for="mime_type" class="data-entry-label" >Mime Type</label>
											<input type="text" name="mime_type" id="mime_type" class="data-entry-input">
										</div>
										<div class="col-12 col-md-4 px-1">
											<label for="mask_media_fg" class="data-entry-label" >Visibility</label>
											<input type="text" name="mask_media_fg" id="mask_media_fg" class="data-entry-input">
										</div>
									</div>
									<div class="row mx-0 mt-0 py-1">
										<div class="col-12 col-md-12 px-1">
											<label for="media_license_id" class="data-entry-label mt-0" >License</label>
											<input type="text" name="media_license_id" id="media_license_id" class="data-entry-input">
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
	<cfthread action="join" name="getMediaThread" />
	<cfreturn getMediaThread.output>
</cffunction>
<cffunction name="getMediaTable" returntype="query" access="remote">
	<cfargument name="media_id" type="string" required="yes">
	<cfset r=1>
	<cftry>
		<cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<cfquery name="updateMediaCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="newMediaCheck_result">
				SELECT count(*) as ct from media
				WHERE
					MEDIA_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value='#media_id#'>
			</cfquery>
			<cfif updateMediaCheck.ct NEQ 1>
				<cfthrow message = "Unable to update images. Provided media_id does not match a record in the images ID table.">
			</cfif>
			<cfquery name="updateMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateMedia">
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
				<cfif isDefined("cfcatch.queryError") >
					<cfset queryError=cfcatch.queryError>
					<cfelse>
					<cfset queryError = ''>
				</cfif>
				<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfheader statusCode="500" statusText="#message#">
				<cfoutput>
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
				<cfabort>
			</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>
<!---getEditOtherIDsHTML obtain a block of html to populate an other ids editor dialog for a specimen.
 @param collection_object_id the collection_object_id for the cataloged item for which to obtain the other ids editor dialog.
 @return html for editing other ids for the specified cataloged item. 
--->
<cffunction name="getEditOtherIDsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getEditOtherIDsThread">
		<cfoutput>
		<cftry>
			<cfquery name="getIDs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select 
					coll_obj_other_id_num.COLL_OBJ_OTHER_ID_NUM_ID,
					cataloged_item.cat_num,
					cataloged_item.cat_num_prefix,
					cataloged_item.cat_num_integer,
					cataloged_item.cat_num_suffix,
					coll_obj_other_id_num.other_id_prefix,
					coll_obj_other_id_num.other_id_number,
					coll_obj_other_id_num.other_id_suffix,
					coll_obj_other_id_num.other_id_type, 
					collection.collection_id,
					cataloged_item.collection_cde,
					collection.institution_acronym
				from 
					cataloged_item, 
					coll_obj_other_id_num,
					collection 
				where
					cataloged_item.collection_id=collection.collection_id and
					cataloged_item.collection_object_id=coll_obj_other_id_num.collection_object_id (+) and 
					cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
			</cfquery>
			<cfquery name="ctType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select other_id_type from ctcoll_other_id_type
			</cfquery>
			<cfquery name="cataf" dbtype="query">
				select cat_num from getIDs group by cat_num
			</cfquery>
			<cfquery name="getOIDs" dbtype="query">
				select 
					COLL_OBJ_OTHER_ID_NUM_ID,
					other_id_prefix,
					other_id_number,
					other_id_suffix,
					other_id_type 
				from 
					getIDs 
				group by 
					COLL_OBJ_OTHER_ID_NUM_ID,
					other_id_prefix,
					other_id_number,
					other_id_suffix,
					other_id_type
			</cfquery>
			<cfquery name="ctcoll_cde" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select 
					institution_acronym,
					collection_cde,
					collection_id 
				from collection
			</cfquery>
			<cfoutput>
				<div class="container-fluid">
					<div class="row">
						<div class="col-12 mt-2 bg-light border rounded p-3">
							<h1 class="h3">Edit Existing Identifiers</h1>
							<form name="editCatNumOtherIDs" id="editCatNumOtherIDsForm">
									<input type="hidden" name="method" value="updateCatNumOtherID">
									<input type="hidden" name="returnformat" value="json">
									<input type="hidden" name="queryformat" value="column">
									<input type="hidden" name="collection_object_id" value="#collection_object_id#">
								<div class="mb-4">
									Catalog&nbsp;Number:
									<select name="collection_id" size="1" class="reqdClr mb-3 mb-md-0">
										<cfset thisCollId=#getIDs.collection_id#>
										<cfloop query="ctcoll_cde">
											<option 
											<cfif #thisCollId# is #collection_id#> selected </cfif>
										value="#collection_id#">#institution_acronym# #collection_cde#</option>
										</cfloop>
									</select>
									<input type="text" name="cat_num" value="#cataf.cat_num#" class="reqdClr">
										<input type="button" value="Save" aria-label="Save Changes" class="btn btn-xs btn-primary"
										onClick="if (checkFormValidity($('##editCatNumOtherIdsForm')[0])) { editOtherIDsSubmit();  } ">
										<output id="saveCatNumOtherIDsResultDiv" class="d-block text-danger">&nbsp;</output>
									<script>
												function editCatNumOtherIDsSubmit(){
													$('##saveCatNumOtherIDsResultDiv').html('Saving....');
													$('##saveCatNumOtherIDsResultDiv').addClass('text-warning');
													$('##saveCatNumOtherIDsResultDiv').removeClass('text-success');
													$('##saveCatNumOtherIDsResultDiv').removeClass('text-danger');
													$.ajax({
														url : "/specimens/component/functions.cfc",
														type : "post",
														dataType : "json",
														data: $("##editCatNumOtherIDsForm").serialize(),
														success: function (result) {
															if (typeof result.DATA !== 'undefined' && typeof result.DATA.STATUS !== 'undefined' && result.DATA.STATUS[0]=='1') { 
																$('##saveCatNumOtherIDsResultDiv').html('Saved');
																$('##saveCatNumOtherIDsResultDiv').addClass('text-success');
																$('##saveCatNumOtherIDsResultDiv').removeClass('text-warning');
																$('##saveCatNumOtherIDsResultDiv').removeClass('text-danger');
															} else {
																// we shouldn't be able to reach this block, backing error should return an http 500 status
																$('##saveCatNumOtherIDsResultDiv').html('Error');
																$('##saveCatNumOtherIDsResultDiv').addClass('text-danger');
																$('##saveCatNumOtherIDsResultDiv').removeClass('text-warning');
																$('##saveCatNumOtherIDsResultDiv').removeClass('text-success');
																messageDialog('Error updating Other IDs: '+result.DATA.MESSAGE[0], 'Error saving Cat Num Change ID.');
															}
														},
														error: function(jqXHR,textStatus,error){
															$('##saveCatNumOtherIDsResultDiv').html('Error');
															$('##saveCatNumOtherIDsResultDiv').addClass('text-danger');
															$('##saveCatNumOtherIDsResultDiv').removeClass('text-warning');
															$('##saveCatNumOtherIDsResultDiv').removeClass('text-success');
															handleFail(jqXHR,textStatus,error,"saving changes to Cat Num Other IDs");
														}
													});
												};
											</script> 
								</div>
							</form>
							<cfset i=1>
							<cfloop query="getOIDs">
								<cfif len(other_id_type) gt 0>
									<form name="getOIDs#i#" id="editOtherIDsForm">
									<input type="hidden" name="method" value="updateOtherID">
									<input type="hidden" name="returnformat" value="json">
									<input type="hidden" name="queryformat" value="column">
									<input type="hidden" name="collection_object_id" value="#collection_object_id#">
									<input type="hidden" name="coll_obj_other_id_num_id" value="#coll_obj_other_id_num_id#">
									<input type="hidden" name="number_of_ids" id="number_of_ids" value="#getOIDs.recordcount#">
										
										<div class="row mx-0">
											<div class="form-group mb-1 mb-md-3 col-12 col-md-2 pl-0 pr-1">
												<label class="data-entry-label">Other ID Type</label>
												<cfset thisType = #getOIDs.other_id_type#>
												<select name="other_id_type" class="data-entry-select" style="" size="1">
													<cfloop query="ctType">
														<option 
														<cfif #ctType.other_id_type# is #thisType#> selected </cfif>
														value="#ctType.other_id_type#">#ctType.other_id_type#</option>
													</cfloop>
												</select>
											</div>
											<div class="form-group mb-1 mb-md-3  col-12 col-md-2 px-1">
												<label for="other_id_prefix" class="data-entry-label">Other ID Prefix</label>
												<input class="data-entry-input" type="text" value="#encodeForHTML(getOIDs.other_id_prefix)#" size="12" name="other_id_prefix">
											</div>
											<div class="form-group mb-1 mb-md-3  col-12 col-md-3 px-1">
												<label for="other_id_number" class="data-entry-label">Other ID Number</label>
												<input type="text" class="data-entry-input" value="#encodeForHTML(getOIDs.other_id_number)#" size="12" name="other_id_number">
											</div>
											<div class="form-group mb-1 mb-md-3  col-12 col-md-2 px-1">
												<label for="other_id_suffix" class="data-entry-label">Other ID Suffix</label>
												<input type="text" class="data-entry-input" value="#encodeForHTML(getOIDs.other_id_suffix)#" size="12" name="other_id_suffix">
											</div>
											<div class="form-group col-12 col-md-3 px-1 mt-0 mt-md-3">
												<input type="button" value="Save" aria-label="Save Changes" class="btn btn-xs btn-primary"
													onClick="if (checkFormValidity($('##editOtherIDsForm')[0])) { editOtherIDsSubmit();  } ">
												
												<input type="button" value="Delete" class="btn btn-xs btn-danger" onclick="getOIDs#i#.Action.value='deleOID';confirmDelete('getOIDs#i#');">
												<output id="saveOtherIDsResultDiv" class="d-block text-danger">&nbsp;</output>
											</div>

											<script>
												function editOtherIDsSubmit(){
													$('##saveOtherIDsResultDiv').html('Saving....');
													$('##saveOtherIDsResultDiv').addClass('text-warning');
													$('##saveOtherIDsResultDiv').removeClass('text-success');
													$('##saveOtherIDsResultDiv').removeClass('text-danger');
													$.ajax({
														url : "/specimens/component/functions.cfc",
														type : "post",
														dataType : "json",
														data: $("##editOtherIDsForm").serialize(),
														success: function (result) {
															if (typeof result.DATA !== 'undefined' && typeof result.DATA.STATUS !== 'undefined' && result.DATA.STATUS[0]=='1') { 
																$('##saveOtherIDsResultDiv').html('Saved');
																$('##saveOtherIDsResultDiv').addClass('text-success');
																$('##saveOtherIDsResultDiv').removeClass('text-warning');
																$('##saveOtherIDsResultDiv').removeClass('text-danger');
															} else {
																// we shouldn't be able to reach this block, backing error should return an http 500 status
																$('##saveOtherIDsResultDiv').html('Error');
																$('##saveOtherIDsResultDiv').addClass('text-danger');
																$('##saveOtherIDsResultDiv').removeClass('text-warning');
																$('##saveOtherIDsResultDiv').removeClass('text-success');
																messageDialog('Error updating Other IDs: '+result.DATA.MESSAGE[0], 'Error saving Other ID.');
															}
														},
														error: function(jqXHR,textStatus,error){
															$('##saveOtherIDsResultDiv').html('Error');
															$('##saveOtherIDsResultDiv').addClass('text-danger');
															$('##saveOtherIDsResultDiv').removeClass('text-warning');
															$('##saveOtherIDsResultDiv').removeClass('text-success');
															handleFail(jqXHR,textStatus,error,"saving changes to Other IDs");
														}
													});
												};
											</script> 
										</div>
									</form>
									<cfset i=#i#+1>
								</cfif>
							</cfloop>
						</div>
						<div class="col-12 mt-4 px-0">
							<div id="accordion2">
								<div class="card">
									<div class="card-header pt-1" id="headingTwo">
										<h1 class="my-0 px-1 pb-1">
											<button class="btn btn-link text-left collapsed" data-toggle="collapse" data-target="##collapseTwo" aria-expanded="true" aria-controls="collapseTwo"> <span class="h4">Add New Identifier</span> </button>
										</h1>
									</div>
									<div id="collapseTwo" class="collapse" aria-labelledby="headingTwo" data-parent="##accordion2">
										<div class="card-body mt-2">
											<form name="newOID" method="post" action="Specimens.cfm">
												<div class="row mx-0">
													<div class="form-group col-3 pl-0 pr-2">
														<input type="hidden" name="collection_object_id" value="#collection_object_id#">
														<input type="hidden" name="Action" value="newOID">
														<label class="data-entry-label" id="other_id_type">Other ID Type</label>
														<select name="other_id_type" size="1" class="reqdClr data-entry-select">
															<cfloop query="ctType">
																<option 
															value="#ctType.other_id_type#">#ctType.other_id_type#</option>
															</cfloop>
														</select>
													</div>
													<div class="form-group col-2 px-1">
														<label class="data-entry-label" id="other_id_prefix">Other ID Prefix</label>
														<input type="text" class="reqdClr data-entry-input" name="other_id_prefix" size="6">
													</div>
													<div class="form-group col-3 px-1">
														<label class="data-entry-label" id="other_id_number">Other ID Number</label>
														<input type="text" class="reqdClr data-entry-input" name="other_id_number" size="6">
													</div>
													<div class="form-group col-2 px-1">
														<label class="data-entry-label" id="other_id_suffix">Other ID Suffix</label>
														<input type="text" class="reqdClr data-entry-input" name="other_id_suffix" size="6">
													</div>
													<div class="form-group col-2 px-1 mt-3">
														<input type="submit" value="Create Identifier" class="btn btn-xs btn-primary">
													</div>
												</div>
											</form>
										</div>
									</div>
								</div>
							</div>
						</div>
					</div>
				</div>
			</cfoutput> 
			<!-------------------------------------------------------->
			
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
	</cfoutput>
	</cfthread>
	<cfthread action="join" name="getEditOtherIDsThread" />
	<cfreturn getEditOtherIDsThread.output>
</cffunction>
<!---updateOtherID function
 @param collection_object_id
 @commit change
--->
<cffunction name="updateOtherID" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="coll_obj_other_id_num_id" type="string" required="yes">
	<cfoutput> 
			<cftry>
				<cfloop from="1" to="#NUMBER_OF_IDS#" index="n">
					<cfset thisCollObjOtherIdNumId = #evaluate("coll_obj_other_id_num_id_" & n)#>
					<cfset thisOtherIdType = #evaluate("other_id_type_" & n)#>
					<cfset thisOtherIdPrefix = #evaluate("other_id_prefix_" & n)#>
					<cfset thisOtherIdNumber = #evaluate("other_id_number_" & n)#>
					<cfset thisOtherIdSuffix = #evaluate("other_id_suffix_" & n)#>
					<cfset thisDisplayValue = #evaluate("display_value_" & n)#>
					
	
						<cfquery name="updateOtherID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							UPDATE coll_obj_other_id_num SET
								other_id_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisOtherIdType#">,
								other_id_prefix = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisOtherIdPrefix#">,
								other_id_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisOtherIdNumber#">
								other_id_suffix = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisOtherIdSuffix#">
								display_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisDisplayValue#">
							where coll_obj_other_id_num_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisCollObjOtherIdNumId#">
						</cfquery>
				</cfloop>
							

				<cftransaction action="commit">
				<cfset data=queryNew("status, message, id")>
				<cfset t = queryaddrow(data,1)>
				<cfset t = QuerySetCell(data, "status", "1", 1)>
				<cfset t = QuerySetCell(data, "message", "Record updated.", 1)>
				<cfset t = QuerySetCell(data, "id", "#collection_object_id#", 1)>
				<cfreturn data>
				<cfcatch>
					<cftransaction action="rollback">
					<cfset error_message = cfcatchToErrorMessage(cfcatch)>
					<cfset function_called = "#GetFunctionCalledName()#">
					<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
					<cfabort>
				</cfcatch>
			</cftry>
	</cfoutput>
</cffunction>
<!---getCatNumOtherIDHTML function
 @param collection_object_id
--->
<cffunction name="getCatNumOtherIDHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getOtherIDsThread">
		<cfoutput>
			<cftry>
				<cfquery name="oid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
				<cfquery name="oid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
		<cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<cfquery name="updateOtherIDCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="newOtherIDCheck_result">
				SELECT count(*) as ct from coll_obj_other_id_num
				WHERE
					coll_obj_other_id_num_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value='#coll_obj_other_id_num_id#'>
			</cfquery>
			<cfif updateOtherIDCheck.ct NEQ 1>
				<cfthrow message = "Unable to update other ID. Provided coll_obj_other_num_id does not match a record in the ID table.">
			</cfif>
			<cfquery name="updateOtherID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateOtherID">
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
						
						
<cffunction name="getEditCollectorsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="target" type="string" required="yes">

	<!--- TODO: Refactor to allow target to specify whether this dialog is used for collectors, preparators, or both --->
	<cfthread name="getEditCollectorsThread">
		<cftry>
			<cfoutput>
				<cfquery name="getColls" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					agent_name, 
					collector_role,
					coll_order,
					collector.agent_id,
					institution_acronym
				FROM
					collector, 
					preferred_agent_name,
					cataloged_item,
					collection
				WHERE
					collector.collection_object_id = cataloged_item.collection_object_id and
					cataloged_item.collection_id=collection.collection_id AND
					collector.agent_id = preferred_agent_name.agent_id AND
					collector.collection_object_id = #collection_object_id#
				ORDER BY 
					collector_role, coll_order
			</cfquery>
				<cfset i=1>
				<h3> Agent as Collector or Preparator</h3>
				<table>
					<cfloop query="getColls">
						<form name="colls#i#" method="post" action="editColls.cfm"  onSubmit="return gotAgentId(this.newagent_id.value)">
							<input type="hidden" name="collection_object_id" value="#collection_object_id#">
							<tr>
								<td><label class="px-2">Name: </label>
									<input type="text" name="Name" value="#getColls.agent_name#" class="reqdClr" 
						onchange="getAgent('newagent_id','Name','colls#i#',this.value); return false;"
						 onKeyPress="return noenter(event);">
									<input type="hidden" name="newagent_id">
									<input type="hidden" name="oldagent_id" value="#agent_id#">
									<label for="collector_role" class="px-2">Role: </label>
									<input type="hidden" name="oldRole" value="#getColls.collector_role#">
									<select name="collector_role" size="1"  class="reqdClr">
										<option <cfif #getColls.collector_role# is 'c'> selected </cfif>value="c">collector</option>
										<option <cfif #getColls.collector_role# is 'p'> selected </cfif>value="p">preparator</option>
									</select>
									<label class="px-2" for="coll_order">Order: </label>
									<input type="hidden" name="oldOrder" value="#getColls.coll_order#">
									<select name="coll_order" size="1" class="reqdClr">
										<cfset thisLoop =#getColls.recordcount# +1>
										<cfloop from="1" index="c" to="#thisLoop#">
											<option <cfif #c# is #getColls.coll_order#> selected </cfif>value="#c#">#c#</option>
										</cfloop>
									</select>
									<input type="button" value="Save" class="btn btn-xs btn-primary" onclick="colls#i#.Action.value='saveEdits';submit();">
									<input type="button" value="Delete" class="btn btn-xs btn-danger" onClick="colls#i#.Action.value='deleteColl';confirmDelete('colls#i#');"></td>
							</tr>
						</form>
						<cfset i = #i#+1>
					</cfloop>
				</table>
				<br>
				<table class="newRec mt-4">
					<thead>
						<tr>
							<th class="p-2">Add an Agent to this record:</th>
						</tr>
					</thead>
					<tbody>
						<tr>
							<td><form name="newColl" method="post" action="editColls.cfm"  onSubmit="return gotAgentId(this.newagent_id.value)">
									<input type="hidden" name="collection_object_id" value="#collection_object_id#">
									<input type="hidden" name="Action" value="newColl">
									<label class="px-2">Name: </label>
									<input type="text" name="name" class="reqdClr" onchange="getAgent('newagent_id','name','newColl',this.value); return false;"
						onKeyPress="return noenter(event);">
									<input type="hidden" name="newagent_id">
									<label class="px-2">Role: </label>
									<select name="collector_role" size="1" class="reqdClr">
										<option value="c">collector</option>
										<option value="p">preparator</option>
									</select>
									<label class="px-2">Order: </label>
									<select name="coll_order" size="1" class="reqdClr">
										<cfset thisLoop = #getColls.recordcount# +1>
										<cfloop from="1" index="c" to="#thisLoop#">
											<option <cfif #c# is #thisLoop#> selected </cfif>
										value="#c#">#c#</option>
										</cfloop>
									</select>
									<input type="submit" value="Create" class="btn btn-xs btn-primary">
								</form></td>
						</tr>
					</tbody>
				</table>
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
	<cfthread action="join" name="getEditCollectorsThread" />
	<cfreturn getEditCollectorsThread.output>
</cffunction>

<!--- TODO: Incomplete add determiner function? --->
<cffunction name="getAgentIdentifiers" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getAgentIdentsThread"> <cfoutput>
			<cftry>
				<p>Hello</p>
				<cfcatch>
					<cftransaction action="rollback">
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
					<cfabort>
				</cfcatch>
			</cftry>
		</cfoutput> </cfthread>
	<cfthread action="join" name="getAgentIdentsThread" />
	<cfreturn getAgentIdentsThread.output>
</cffunction>

<cffunction name="getEditPartsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getEditPartsThread">
		<cftry>
			<cfquery name="collcode" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select collection_cde from cataloged_item where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
			</cfquery>
			<cfquery name="ctDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select coll_obj_disposition from ctcoll_obj_disp order by coll_obj_disposition
			</cfquery>
			<cfquery name="ctModifiers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select modifier from ctnumeric_modifiers order by modifier desc
			</cfquery>
			<cfquery name="ctPreserveMethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select preserve_method
				from ctspecimen_preserv_method
				where collection_cde = '#collcode.collection_cde#'
				order by preserve_method
			</cfquery>
			<cfquery name="rparts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
					<cfquery name="citations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
					<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select collection_id,collection from collection
						order by collection
					</cfquery>
					<cfquery name="ctColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select collection,collection_id from collection order by collection
					</cfquery>
					<cfquery name="ctTypeStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select type_status from ctcitation_type_status order by type_status
					</cfquery>
					<cfquery name="ctjournal_name" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select journal_name from ctjournal_name order by journal_name
					</cfquery>
					<cfquery name="ctpublication_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select publication_type from ctpublication_type order by publication_type
					</cfquery>
					<cfquery name="getCited" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
						<cfquery name="getpubs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<cfquery name="deleteCitation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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

<cfquery name="getCited" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
	<cfquery name="newCite" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
	<cfquery name="edCit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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

<cfquery name="getCited" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
	<cfquery name="deleCit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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

<cffunction name="getEditAttributesHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getEditAttributesThread"> <cfoutput>
			<cftry>
				<cfquery name="attribute1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					attributes.attribute_type,
					attributes.attribute_value,
					attributes.attribute_units,
					attributes.attribute_remark,
					attributes.determination_method,
					attributes.determined_date,
					attribute_determiner.agent_name attributeDeterminer
				FROM
					attributes,
					preferred_agent_name attribute_determiner
				WHERE
					attributes.determined_by_agent_id = attribute_determiner.agent_id and
					attributes.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
			</cfquery>
				<cfquery name="relns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					distinct biol_indiv_relationship, related_collection, related_coll_object_id, related_cat_num, biol_indiv_relation_remarks FROM (
				SELECT
					rel.biol_indiv_relationship as biol_indiv_relationship,
					collection as related_collection,
					rel.related_coll_object_id as related_coll_object_id,
					rcat.cat_num as related_cat_num,
					rel.biol_indiv_relation_remarks as biol_indiv_relation_remarks
				FROM
					biol_indiv_relations rel
					left join cataloged_item rcat
						 on rel.related_coll_object_id = rcat.collection_object_id
					left join collection
						 on collection.collection_id = rcat.collection_id
					left join ctbiol_relations ctrel
						on rel.biol_indiv_relationship = ctrel.biol_indiv_relationship
				WHERE rel.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL"> 
					and ctrel.rel_type <> 'functional'
				UNION
				SELECT
					 ctrel.inverse_relation as biol_indiv_relationship,
					 collection as related_collection,
					 irel.collection_object_id as related_coll_object_id,
					 rcat.cat_num as related_cat_num,
					irel.biol_indiv_relation_remarks as biol_indiv_relation_remarks
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
				<cfquery name="sex" dbtype="query">
				select * from attribute1 where attribute_type = 'sex'
			</cfquery>
				<cfif len(attribute1.attribute_value) gt 0>
					<form class="row mx-0">
						<div class="bg-light border rounded p-2">
							<h1 class="h3">Edit Existing Attributes</h1>
							<ul class="col-12 px-0 pb-3">
								<cfloop query="sex">
									<li class="list-group-item float-left col-12 col-md-2 px-1">
										<label class="data-entry-label">Sex:</label>
										<input class="data-entry-input" value="#attribute_value#">
									</li>
									<cfif len(attributeDeterminer) gt 0>
										<li class="list-group-item float-left col-12 col-md-3 px-1">
											<label class="data-entry-label">Determiner:</label>
											<input class="data-entry-input" value="#attributeDeterminer#">
										</li>
										<cfif len(determined_date) gt 0>
											<li class="list-group-item float-left col-12 col-md-2 px-1">
												<label class="data-entry-label">Date:</label>
												<input class="data-entry-input" value="#dateformat(determined_date,'yyyy-mm-dd')#">
											</li>
										</cfif>
										<cfif len(determination_method) gt 0>
											<li class="list-group-item float-left col-12 col-md-2 px-1">
												<label class="data-entry-label">Method:</label>
												<input class="data-entry-input" value="#determination_method#">
											</li>
										</cfif>
									</cfif>
									<cfif len(attribute_remark) gt 0>
										<li class="list-group-item float-left col-12 col-md-3 px-1">
											<label class="data-entry-label">Remark:</label>
											<input class="data-entry-input" value="#attribute_remark#">
										</li>
									</cfif>
								</cfloop>
							</ul>
							<cfquery name="code" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select collection_cde from cataloged_item where collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL"> 
						</cfquery>
							<cfif #code.collection_cde# is "Mamm">
								<cfquery name="total_length" dbtype="query">
							select * from attribute1 where attribute_type = 'total length'
						</cfquery>
								<cfquery name="tail_length" dbtype="query">
							select * from attribute1 where attribute_type = 'tail length'
						</cfquery>
								<cfquery name="hf" dbtype="query">
							select * from attribute1 where attribute_type = 'hind foot with claw'
						</cfquery>
								<cfquery name="efn" dbtype="query">
							select * from attribute1 where attribute_type = 'ear from notch'
						</cfquery>
								<cfquery name="weight" dbtype="query">
							select * from attribute1 where attribute_type = 'weight'
						</cfquery>
								<cfif
							len(total_length.attribute_units) gt 0 OR
							len(tail_length.attribute_units) gt 0 OR
							len(hf.attribute_units) gt 0 OR
							len(efn.attribute_units) gt 0 OR
							len(weight.attribute_units) gt 0>
									<!---semi-standard measurements ---> 
									<span class="h5 pt-1 px-2 mb-0">Standard Measurements</span>
									<table class="table table-responsive bg-white mt-2 mb-1 mx-0" aria-label="Standard Measurements">
										<thead>
											<tr>
												<th>total length</th>
												<th>tail length</th>
												<th>hind foot</th>
												<th>efn</th>
												<th>weight</th>
											</tr>
										</thead>
										<tbody>
											<tr class="col-12 px-0 pt-2">
												<td><input type="text" class="col-8 float-left px-1" value="#total_length.attribute_value#">
													<input type="text" class="col-4 px-1 float-left" value="#total_length.attribute_units#"></td>
												<td><input type="text" class="col-8 float-left px-1" value="#tail_length.attribute_value#">
													<input type="text" class="col-4 px-1 float-left" value="#tail_length.attribute_units#"></td>
												<td><input type="text" class="col-8 px-1 float-left" value="#hf.attribute_value#">
													<input type="text" class="col-4 px-1 float-left" value="#hf.attribute_units#"></td>
												<td><input type="text" class="col-8 px-1 float-left" value="#efn.attribute_value#">
													<input type="text" class="col-4 px-1 float-left" value="#efn.attribute_units#"></td>
												<td><input type="text" class="col-8 px-1 float-left" value="#weight.attribute_value#">
													<input type="text" class="col-4 px-1 float-left" value="#weight.attribute_units#"></td>
											</tr>
										</tbody>
									</table>
									<cfif isdefined("attributeDeterminer") and len(#attributeDeterminer#) gt 0>
										<cfset determination = "#attributeDeterminer#">
										<cfif len(determined_date) gt 0>
											<cfset determination = '#determination#, #dateformat(determined_date,"yyyy-mm-dd")#'>
										</cfif>
										<cfif len(determination_method) gt 0>
											<cfset determination = '#determination#, #determination_method#'>
										</cfif>
#determination#
									</cfif>
								</cfif>
								<cfquery name="theRest" dbtype="query">
						select * from attribute1 
						where attribute_type NOT IN (
						'weight','sex','total length','tail length','hind foot with claw','ear from notch'
						)
					</cfquery>
								<cfelse>
								<!--- not Mamm --->
								
								<cfquery name="theRest" dbtype="query">
						select * from attribute1 where attribute_type NOT IN ('sex')
					</cfquery>
							</cfif>
							<cfloop query="theRest">
								<div class="row mx-0">
									<ul class="col-12 mb-0 px-0 mt-2 pt-1 border-top">
										<li class="list-group-item float-left col-12 col-md-2 px-1 mb-1">
											<label for="att_name" class="data-entry-label">Attribute Name</label>
											<input type="text" class="data-entry-input" id="att_name" value="#attribute_type#">
										</li>
										<li class="list-group-item float-left col-12 col-md-2 px-1 mb-1">
											<label for="att_value" class="data-entry-label">Attribute Value</label>
											<input type="text" class="data-entry-input" id="att_value" value="#attribute_value#">
										</li>
										<cfif len(attribute_units) gt 0>
											<li class="list-group-item float-left col-12 col-md-1 px-1 mb-1">
												<label for="att_units" class="data-entry-label">Units</label>
												<input type="text" class="data-entry-input" id="att_units" value="#attribute_units#">
											</li>
										</cfif>
										<cfif len(attributeDeterminer) gt 0>
											<li class="list-group-item float-left col-12 col-md-2 px-1 mb-1">
												<label class="data-entry-label">Determiner</label>
												<input type="text" class="data-entry-input" id="att_det" value="#attributeDeterminer#">
											</li>
											<cfif len(determined_date) gt 0>
												<li class="list-group-item float-left col-12 col-md-2 px-1 mb-1">
													<label class="data-entry-label">Determined Date</label>
													<input type="text" class="data-entry-input" id="att_det" value="#dateformat(determined_date,"yyyy-mm-dd")#">
												</li>
											</cfif>
											<cfif len(determination_method) gt 0>
												<li class="list-group-item float-left col-12 col-md-2 px-1 mb-1">
													<label class="data-entry-label">Determined Method</label>
													<input type="text" class="data-entry-input" id="att_meth" value="#determination_method#">
												</li>
											</cfif>
										</cfif>
									</ul>
								</div>
								<cfif len(attribute_remark) gt 0>
									<div class="mx-0 row">
										<ul class="col-12 mb-0 px-0 mt-2 mb-1">
											<li class="list-group-item float-left col-12 col-md-12 px-1 mb-1">
												<label for="att_rem" class="data-entry-label">Remarks</label>
												<input type="text" class="data-entry-input" id="att_rem" value="#attribute_remark#">
											</li>
										</ul>
									</div>
								</cfif>
							</cfloop>
						</div>
						<input type="button" value="Save" aria-label="Save Changes" class="mt-2 btn mx-1 btn-xs btn-primary">
					</form>
					<cfelse>
				</cfif>
				<div class="col-12 mt-4 px-1">
					<div id="accordionAttribute">
						<div class="card">
							<div class="card-header pt-1" id="headingAttribute">
								<h1 class="my-0 px-1 pb-1">
									<button class="btn btn-link text-left collapsed" data-toggle="collapse" data-target="##collapseAttribute" aria-expanded="true" aria-controls="collapseAttribute"> <span class="h4">Add New Attribute</span> </button>
								</h1>
							</div>
							<div id="collapseAttribute" class="collapse" aria-labelledby="headingAttribute" data-parent="##accordionAttribute">
								<div class="card-body mt-2">
									<form name="newOID">
										<div class="row mx-0 pb-2">
										<ul class="col-12 px-0 mt-2 mb-1">
											<li class="list-group-item float-left col-12 col-md-3 px-1">
												<label for="new_att_name" class="data-entry-label">Attribute Name</label>
												<input type="text" class="data-entry-input" id="new_att_name" value="">
											</li>
											<li class="list-group-item float-left col-12 col-md-3 px-1">
												<label for="new_att_value" class="data-entry-label">Attribute Value</label>
												<input type="text" class="data-entry-input" id="new_att_value" value="">
											</li>
											<li class="list-group-item float-left col-12 col-md-2 px-1">
												<label for="new_att_determiner" class="data-entry-label">Determiner</label>
												<input type="text" class="data-entry-input" id="new_att_determiner" value="">
											</li>
											<li class="list-group-item float-left col-12 col-md-2 px-1">
												<label for="new_att_det_date" class="data-entry-label">Determined Date</label>
												<input type="text" class="data-entry-input" id="new_att_det_date" value="">
											</li>
											<li class="list-group-item float-left col-12 col-md-2 px-1">
												<label for="new_att_det_method" class="data-entry-label">Determined Method</label>
												<input type="text" class="data-entry-input" id="new_att_det_method" value="">
											</li>
											<li class="list-group-item float-left col-12 col-md-12 px-1">
												<label for="new_att_det_remarks" class="data-entry-label">Remarks</label>
												<input type="text" class="data-entry-input" id="new_att_det_remarks" value="">
											</li>
										</ul>
										<div class="col-12 col-md-12 px-1 mt-2">
											<button id="newID_submit" value="Create" class="btn btn-xs btn-primary" title="Create Identification">Create Attribute</button>
										</div>
									</form>
								</div>
							</div>
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
		</cfoutput> </cfthread>
	<cfthread action="join" name="getEditAttributesThread" />
	<cfreturn getEditAttributesThread.output>
</cffunction>

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
				<cfquery name="l" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
				<cfquery name="g" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
				<cfquery name="ctElevUnit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select orig_elev_units from ctorig_elev_units
				</cfquery>
				<cfquery name="ctdepthUnit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select depth_units from ctdepth_units
				</cfquery>
				<cfquery name="ctdatum" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select datum from ctdatum
				</cfquery>
				<cfquery name="ctGeorefMethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select georefMethod from ctgeorefmethod
				</cfquery>
				<cfquery name="ctVerificationStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select VerificationStatus from ctVerificationStatus order by VerificationStatus
				</cfquery>
				<cfquery name="cterror" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select LAT_LONG_ERROR_UNITS from ctLAT_LONG_ERROR_UNITS
				</cfquery>
				<cfquery name="ctew" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select e_or_w from ctew
				</cfquery>
				<cfquery name="ctns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select n_or_s from ctns
				</cfquery>
				<cfquery name="ctunits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select ORIG_LAT_LONG_UNITS from ctLAT_LONG_UNITS
				</cfquery>
				<cfquery name="ctcollecting_source" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select COLLECTING_SOURCE from ctcollecting_source
				</cfquery>
				<cfquery name="ctgeology_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select geology_attribute from ctgeology_attribute order by ordinal
				</cfquery>
				<cfquery name="ctSovereignNation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
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
				<cfquery name="getLoc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
							and concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%' 
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
							and concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%' 
							and locality.spec_locality is not null
						then 
							'Masked'
						else
							locality.spec_locality
						end spec_locality,
						case when
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1
							and concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%'
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
							and concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%' 
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
							and concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%'
							and locality.locality_remarks is not null
						then 
							'Masked'
						else
								locality.locality_remarks
						end locality_remarks,
						case when
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1
							and concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%' 
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
									<label for="verbatim_locality" class="data-entry-label px-2"> Verbatim Locality &nbsp;&nbsp; <a href="Locality.cfm?Action=editCollEvnt&collecting_event_id=#l.collecting_event_id#" target="_blank"> Edit Shared Collecting Event</a>
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
	<cfthread name="getEditRelationsThread"> <cfoutput>
			<cftry>
				<cfquery name="relns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT 
				distinct biol_indiv_relationship, related_collection, related_coll_object_id, related_cat_num, biol_indiv_relation_remarks FROM (
			SELECT
				rel.biol_indiv_relationship as biol_indiv_relationship,
				collection as related_collection,
				rel.related_coll_object_id as related_coll_object_id,
				rcat.cat_num as related_cat_num,
				rel.biol_indiv_relation_remarks as biol_indiv_relation_remarks
			FROM
				biol_indiv_relations rel
				left join cataloged_item rcat
				on rel.related_coll_object_id = rcat.collection_object_id
				left join collection
					on collection.collection_id = rcat.collection_id
				left join ctbiol_relations ctrel
					on rel.biol_indiv_relationship = ctrel.biol_indiv_relationship
			WHERE rel.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL"> 
					and ctrel.rel_type <> 'functional'
			UNION
			SELECT
				ctrel.inverse_relation as biol_indiv_relationship,
				collection as related_collection,
				irel.collection_object_id as related_coll_object_id,
				rcat.cat_num as related_cat_num,
				irel.biol_indiv_relation_remarks as biol_indiv_relation_remarks
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
				<cfif len(relns.biol_indiv_relationship) gt 0 >
					<div class="row mx-0 mt-3">
						<div class="col-12 px-0">
							<ul class="list-group list-group-flush float-left">
								<cfloop query="relns">
									<li class="list-group-item py-0">
										<input class="" type="text" value="#biol_indiv_relationship#">
										<a href="/Specimen.cfm?collection_object_id=#related_coll_object_id#" target="_top">
										<input class="" type="" value="#related_collection#">
										<input class="" value="#related_cat_num#" type="text">
										</a>
										<cfif len(relns.biol_indiv_relation_remarks) gt 0>
											<input class="" size="39" type="text" value="#biol_indiv_relation_remarks#">
										</cfif>
									</li>
								</cfloop>
								<cfif len(relns.biol_indiv_relationship) gt 0>
									<li class="pb-1 list-group-item"> <a href="/Specimen.cfm?collection_object_id=#valuelist(relns.related_coll_object_id)#" target="_top">(Specimens List)</a> </li>
								</cfif>
							</ul>
						</div>
					</div>
					<div class="row mx-0 pb-2">
						<div class="col-12 col-md-12 p-2">
							<input type="submit" id="theSubmit" value="Save" class="btn btn-xs btn-primary">
						</div>
					</div>
				</cfif>
				<cfquery name="ctReln" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select biol_indiv_relationship from ctbiol_relations
				</cfquery>
				<cfquery name="thisCollId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select collection from cataloged_item,collection where cataloged_item.collection_id=collection.collection_id and
					collection_object_id=#collection_object_id#
				</cfquery>
				<div class="col-12 mt-4 px-1">
					<div id="accordionAttribute">
						<div class="card">
							<div class="card-header pt-1" id="headingAttribute">
								<h1 class="my-0 px-1 pb-1">
									<button class="btn btn-link text-left collapsed" data-toggle="collapse" data-target="##collapseAttribute" aria-expanded="true" aria-controls="collapseAttribute"> <span class="h4">Add New Relationship</span> </button>
								</h1>
							</div>
							<div id="collapseAttribute" class="collapse" aria-labelledby="headingAttribute" data-parent="##accordionAttribute">
								<div class="card-body mt-0">
									<form name="newRelationship" >
										<input type="hidden" name="collection_object_id" value="#collection_object_id#">
										<div class="row mx-0 pb-0">
											<ul class="col-12 px-0 mb-2">
												<li class="list-group-item float-left col-12 col-md-3 px-1 py-2">
													<label class="data-entry-label">Relationship:</label>
													<select name="biol_indiv_relationship" size="1" class="reqdClr data-entry-select">
														<cfloop query="ctReln">
															<option value="#ctReln.biol_indiv_relationship#">#ctReln.biol_indiv_relationship#</option>
														</cfloop>
													</select>
													<cfquery name="ctColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
														select collection from collection 
														group by collection order by collection
													</cfquery>
												</li>
												<li class="list-group-item float-left col-12 col-md-3 px-1 py-2">
													<label class="data-entry-label">Relationship:</label>
													<select name="collection" size="1" class="data-entry-select">
														<cfloop query="ctColl">
															<option 
																<cfif #thisCollId.collection# is "#ctColl.collection#"> selected </cfif>
																value="#ctColl.collection#">#ctColl.collection#</option>
														</cfloop>
													</select>
												</li>
												<cfquery name="ctOtherIdType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
												select distinct(other_id_type) FROM ctColl_Other_Id_Type ORDER BY other_Id_Type
												</cfquery>
												<li class="list-group-item float-left col-12 col-md-3 px-1 py-2">
													<label class="data-entry-label">Other ID Type:</label>
													<select name="other_id_type" size="1" class="data-entry-select">
														<option value="catalog_number">Catalog Number</option>
														<cfloop query="ctOtherIdType">
															<option value="#ctOtherIdType.other_id_type#">#ctOtherIdType.other_id_type#</option>
														</cfloop>
													</select>
												</li>
												<li class="list-group-item float-left col-12 col-md-3 px-1 pt-2">
													<label class="data-entry-label">Other ID Number:</label>
													<input type="text" name="oidNumber" class="reqdClr data-entry-input" size="8">
												</li>
												<li class="list-group-item float-left col-12 col-md-12 px-1 py-2 my-0">
													<label class="data-entry-label">Remarks:</label>
													<input type="text" id="" name="biol_indiv_relation_remarks" size="50" class="data-entry-input">
												</li>
											</ul>
										</div>
										<div class="row mx-0 pb-2">
											<div class="col-12 col-md-12 px-1">
												<input type="submit" id="createRel" value="Create Relationship" class="btn btn-xs btn-primary">
											</div>
										</div>
										<div class="row mx-0 pb-2">
											<div class="col-12 col-md-12 px-1 mt-3">
												<label class="data-entry-label">Picked Cataloged Item:</label>
												<input type="text" id="catColl" name="catColl" class="data-entry-input read-only" readonly="yes" size="46">
											</div>
										</div>
									</form>
								</div>
							</div>
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
		</cfoutput> </cfthread>
	<cfthread action="join" name="getEditRelationsThread" />
	<cfreturn getEditRelationsThread.output>
</cffunction>

<cffunction name="getEditTransactionsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getEditTransactionsThread"> <cfoutput>
			<cftry>
				<cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT
		cataloged_item.collection_object_id,
		cataloged_item.cat_num,
		accn.accn_number,
		preferred_agent_name.agent_name,
		collector.coll_order,
		geog_auth_rec.higher_geog,
		locality.spec_locality,
		collecting_event.verbatim_date,
		identification.scientific_name,
		collection.institution_acronym,
		trans.institution_acronym transInst,
		trans.transaction_id,
		collection.collection,
		a_coll.collection accnColln
	FROM
		cataloged_item,
		accn,
		trans,
		collecting_event,
		locality,
		geog_auth_rec,
		collector,
		preferred_agent_name,
		identification,
		collection,
		collection a_coll
	WHERE
		cataloged_item.accn_id = accn.transaction_id AND
		accn.transaction_id = trans.transaction_id AND
		trans.collection_id=a_coll.collection_id and
		cataloged_item.collection_object_id = collector.collection_object_id AND
		collector.agent_id = preferred_agent_name.agent_id AND
		collector_role='c' AND
		cataloged_item.collecting_event_id = collecting_event.collecting_event_id AND
		cataloged_item.collection_id = collection.collection_id AND
		collecting_event.locality_id = locality.locality_id AND
		locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id AND
		cataloged_item.collection_object_id = identification.collection_object_id AND
		identification.accepted_id_fg = 1 AND
		cataloged_item.collection_object_id = 
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
	ORDER BY cataloged_item.collection_object_id
	</cfquery>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_transactions")>
					<cfset oneOfUs = 1>
					<cfelse>
					<cfset oneOfUs = 0>
				</cfif>
				<cfquery name="one" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
        collecting_event.began_date,
        collecting_event.ended_date,
        collecting_event.verbatim_date,
		collecting_event.startDayOfYear,
		collecting_event.endDayOfYear,
		collecting_event.habitat_desc,
        collecting_event.coll_event_remarks,
		locality.locality_id,
		locality.minimum_elevation,
		locality.maximum_elevation,
		locality.orig_elev_units,
        locality.spec_locality,
        verbatimLatitude,
        verbatimLongitude,
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
		accn.transaction_id Accession,
		concatencumbrances(cataloged_item.collection_object_id) concatenatedEncumbrances,
		concatEncumbranceDetails(cataloged_item.collection_object_id) encumbranceDetail,
		locality.locality_remarks,
        collecting_event.verbatim_locality,
		collecting_time,
		fish_field_number,
		min_depth,
		max_depth,
		depth_units,
		collecting_method,
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
		collecting_event.locality_id = locality.locality_id  AND
		locality.locality_id = accepted_lat_long.locality_id (+) AND
		accepted_lat_long.determined_by_agent_id = latLongAgnt.agent_id (+) AND
		locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id AND
		cataloged_item.collection_object_id = coll_object.collection_object_id AND
		coll_object.collection_object_id = coll_object_remark.collection_object_id (+) AND
		coll_object.entered_person_id = enteredPerson.agent_id AND
		coll_object.last_edited_person_id = editedPerson.agent_id (+) AND
		cataloged_item.accn_id =  accn.transaction_id  AND
		accn.transaction_id = trans.transaction_id(+) AND
		cataloged_item.collection_object_id = specimen_part.derived_from_cat_item AND
		cataloged_item.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
</cfquery>
				<cfquery name="accnMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" >
					SELECT 
						media.media_id,
						media.media_uri,
						media.mime_type,
						media.media_type,
						media.preview_uri,
						label_value descr 
					FROM 
						media,
						media_relations,
						(select media_id,label_value from media_labels where media_label='description') media_labels 
					WHERE 
						media.media_id=media_relations.media_id and
						media.media_id=media_labels.media_id (+) and
						media_relations.media_relationship like '% accn' and
						media_relations.related_primary_key = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
				</cfquery>
				<div>
				<form name="addItems" method="post" action="Specimen.cfm">
					<input type="hidden" name="Action" value="addItems">
					<cfif isdefined("collection_object_id") and listlen(collection_object_id) is 1>
						<input type="hidden" name="collection_object_id" value="#collection_object_id#">
					</cfif>
					<div class="container">
						<div class="row">
							<div class="col-12">
								<h1 class="h3 my-1">Add this cataloged item (listed below) to accession:</h1>
								<div class="form-row">
									<div class="col-12 col-sm-3 mb-0">
										<label for="accn_number" class="data-entry-label">Accession</label>
										<input type="text" name="accn_number"  class="data-entry-input" id="accn_number" onchange="findAccession();">
										<span class="small d-block mb-1">TAB to see if accession is valid</span>
										<p>Validation message placeholder</p>
									</div>
									<div class="col-12 col-sm-3 mt-3"> <a class="btn btn-xs btn-secondary text-dark" href="/Transactions.cfm?action=findAccessions" target="_blank">Lookup</a></div>
								</div>
								<div class="col-12 px-0 mb-3">
									<div id="g_num">
										<input type="submit" id="s_btn" value="Add Items" class="btn btn-xs btn-primary">
									</div>
								</div>
							</div>
						</div>
					</div>
				</form>
				<div class="container test">
					<div class="row mx-0">
						<div class="col-12 px-0">
							<table class="table table-responsive">
								<thead>
									<tr>
										<th>Cat Num</th>
										<th>Scientific Name</th>
										<th>Accn</th>
										<th>Collector(s)</th>
										<th>Geog</th>
										<th>Spec Loc</th>
										<th>Date</th>
									</tr>
								</thead>
								<tbody>
									<tr>
										<td>#getItems.collection# #one.cat_num#</td>
										<td>#getItems.scientific_name#</td>
										<td><a href="Specimens.cfm?Accn_trans_id=#getItems.transaction_id#" target="_top">#getItems.accnColln# #getItems.Accn_number#</a></td>
										<td><cfquery name="getAgent" dbtype="query">
				select agent_name, coll_order 
				from getItems 
				where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getItems.collection_object_id#">
				order by coll_order
			</cfquery>
											<cfset colls = "">
											<cfloop query="getAgent">
												<cfif len(#colls#) is 0>
													<cfset colls = #getAgent.agent_name#>
													<cfelse>
													<cfset colls = "#colls#, #getAgent.agent_name#">
												</cfif>
											</cfloop>
#colls# 											</td>
										<td>#getItems.higher_geog#</td>
										<td>#getItems.spec_locality#</td>
										<td>#getItems.verbatim_date#</td>
									</tr>
							</table>
						</div>
						<div class="col-12 bg-light border rounded p-3 mt-4">
							<ul class="list-group list-group-flush pl-0">
								<h2 class="h3 my-1">List of Transactions <span class="small">&ndash; with links to edit page(s)</span></h2>
								<li class="list-group-item">
									<h5 class="mb-0 d-inline-block">Accession:</h5>
									<cfif oneOfUs is 1>
										<a href="/transactions/Accession.cfm?action=edit&transaction_id=#one.accn_id#" target="_blank">#getItems.accn_number#</a>
										<cfelse>
#getItems.accn_number#
									</cfif>
									<cfif accnMedia.recordcount gt 0>
										<cfloop query="accnMedia">
											<div class="m-2 d-inline">
												<cfset mt = #media_type#>
												<a href="/media/#media_id#" target="_blank"> <img src="#getMediaPreview('preview_uri','media_type')#" class="d-block border rounded" width="100" alt="#descr#">Media Details </a> <span class="small d-block">#media_type# (#mime_type#)</span> <span class="small d-block">#descr#</span> </div>
										</cfloop>
									</cfif>
								</li>
								<!--------------------  Project / Usage ------------------------------------>
								<cfquery name="isProj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									SELECT 
										project_name, project.project_id project_id 
									FROM
										project left join project_trans on project.project_id = project_trans.project_id
									WHERE
										project_trans.transaction_id = <cfqueryparam value="#one.accn_id#" cfsqltype="CF_SQL_DECIMAL">
									GROUP BY project_name, project.project_id
								</cfquery>
								<cfquery name="isLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									SELECT 
										project_name, project.project_id 
									FROM 
										loan_item,
										project,
										project_trans,
										specimen_part 
									WHERE 
										specimen_part.derived_from_cat_item = <cfqueryparam value="#one.collection_object_id#" cfsqltype="CF_SQL_DECIMAL"> AND
										loan_item.transaction_id=project_trans.transaction_id AND
										project_trans.project_id=project.project_id AND
										specimen_part.collection_object_id = loan_item.collection_object_id 
									GROUP BY 
										project_name, project.project_id
								</cfquery>
								<cfquery name="isLoanedItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									SELECT 
										loan_item.collection_object_id 
									FROM 
										loan_item,specimen_part 
									WHERE 
										loan_item.collection_object_id=specimen_part.collection_object_id AND
										specimen_part.derived_from_cat_item = <cfqueryparam value="#one.collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
								</cfquery>
								<cfquery name="loanList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									SELECT 
										distinct loan_number, loan_type, loan_status, loan.transaction_id 
									FROM
										specimen_part left join loan_item on specimen_part.collection_object_id=loan_item.collection_object_id
										left join loan on loan_item.transaction_id = loan.transaction_id
									WHERE
										loan_number is not null AND
										specimen_part.derived_from_cat_item = <cfqueryparam value="#one.collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
								</cfquery>
								<cfquery name="isDeaccessionedItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									SELECT 
										deacc_item.collection_object_id 
									FROM
										specimen_part left join deacc_item on specimen_part.collection_object_id=deacc_item.collection_object_id
									WHERE
										specimen_part.derived_from_cat_item = <cfqueryparam value="#one.collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
								</cfquery>
								<cfquery name="deaccessionList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									SELECT 
										distinct deacc_number, deacc_type, deaccession.transaction_id 
									FROM
										specimen_part left join deacc_item on specimen_part.collection_object_id=deacc_item.collection_object_id
										left join deaccession on deacc_item.transaction_id = deaccession.transaction_id
									where
										deacc_number is not null AND
										specimen_part.derived_from_cat_item = <cfqueryparam value="#one.collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
								</cfquery>
								<cfif isProj.recordcount gt 0 OR isLoan.recordcount gt 0 or (oneOfUs is 1 and isLoanedItem.collection_object_id gt 0) or (oneOfUs is 1 and isDeaccessionedItem.collection_object_id gt 0)>
									<cfloop query="isProj">
										<li class="list-group-item">
											<h5 class="mb-0 d-inline-block">Contributed By Project:</h5>
											<a href="/ProjectDetail.cfm?src=proj&project_id=#isProj.project_id#">#isProj.project_name#</a> </li>
									</cfloop>
									<cfloop query="isLoan">
										<li class="list-group-item">
											<h5 class="mb-0 d-inline-block">Used By Project:</h5>
											<a href="/ProjectDetail.cfm?src=proj&project_id=#isLoan.project_id#" target="_mainFrame">#isLoan.project_name#</a> </li>
									</cfloop>
									<cfif isLoanedItem.collection_object_id gt 0 and oneOfUs is 1>
										<li class="list-group-item">
											<h5 class="mb-0 d-inline-block">Loan History:</h5>
											<a class="d-inline-block" href="/Loan.cfm?action=listLoans&collection_object_id=#valuelist(isLoanedItem.collection_object_id)#"
							target="_mainFrame">Loans that include this cataloged item (#loanList.recordcount#).</a>
											<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions")>
												<cfloop query="loanList">
													<ul class="d-block">
														<li class="d-block">#loanList.loan_number# (#loanList.loan_type# #loanList.loan_status#)</li>
													</ul>
												</cfloop>
											</cfif>
										</li>
									</cfif>
									<cfif isDeaccessionedItem.collection_object_id gt 0 and oneOfUs is 1>
										<li class="list-group-item">
											<h5 class="mb-1 d-inline-block">Deaccessions: </h5>
											<a href="/Deaccession.cfm?action=listDeacc&collection_object_id=#valuelist(isDeaccessionedItem.collection_object_id)#"
							target="_mainFrame">Deaccessions that include this cataloged item (#deaccessionList.recordcount#).</a> &nbsp;
											<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions")>
												<cfloop query="deaccessionList">
													<ul class="d-block">
														<li class="d-block"> <a href="/Deaccession.cfm?action=editDeacc&transaction_id=#deaccessionList.transaction_id#">#deaccessionList.deacc_number# (#deaccessionList.deacc_type#)</a></li>
													</ul>
												</cfloop>
											</cfif>
										</li>
									</cfif>
								</cfif>
							</ul>
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
		</cfoutput> </cfthread>
	<cfthread action="join" name="getEditTransactionsThread" />
	<cfreturn getEditTransactionsThread.output>
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
				<cfquery name="itemDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
				<cfquery name="cond" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
					<p class="mt-2 text-danger">Error in #function_called#: #error_message#</p>
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
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
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
					<cfquery name="getEncumbrances" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
					<p class="mt-2 text-danger">Error in #function_called#: #error_message#</p>
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
			<cfquery name="removeFromEncumbrance" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="removeFromEncumbrance_result">
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

</cfcomponent>
