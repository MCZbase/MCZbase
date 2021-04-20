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
<cf_rolecheck>
<cfinclude template = "/shared/functionLib.cfm">

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
				<div class="container-fluid">				
					<div class="row">
						<div class="col-12 mt-2">
							<div class="col-12 col-lg-12 float-left mb-4 px-0">
								<form name="editIdentificationsForm" id="editIdentificationsForm">
									<input type="hidden" name="method" value="updateIdentifications">
									<input type="hidden" name="returnformat" value="json">
									<input type="hidden" name="queryformat" value="column">
									<input type="hidden" name="collection_object_id" value="#collection_object_id#">
									<h1 class="h3 px-1"> Edit Existing Determinations <a href="javascript:void(0);" onClick="getMCZDocs('identification')"><i class="fa fa-info-circle"></i></a> </h1>
									<div class="row mx-0">
										<div class="col-12 px-0">
											<cfquery name="getIDs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
												SELECT distinct
													identification.identification_id,
													institution_acronym,
													identification.scientific_name,
													cat_num,
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
												<div class="col-12 border bg-light px-3 rounded mt-0 mb-2 pt-2 pb-3">
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
														<div class="col-6 px-0">
															<cfset idnum=1>
															<cfloop query="determiners">
																<div id="IdTr_#i#_#idnum#">
																	<div class="col-12">
																		<label for="IdBy_#i#_#idnum#">
																		Identified By
																		<h5 id="IdBy_#i#_#idnum#_view" class="d-inline infoLink">&nbsp;&nbsp;&nbsp;&nbsp;</h5>
																		</label>
																		<div class="col-12 px-0">
																			<div class="input-group">
																				<div class="input-group-prepend"> <span class="input-group-text smaller bg-lightgreen" id="IdBy_#i#_#idnum#_icon"><i class="fa fa-user" aria-hidden="true"></i></span> </div>
																				<input type="text" name="IdBy_#i#_#idnum#" id="IdBy_#i#_#idnum#" value="#encodeForHTML(agent_name)#" class="reqdClr data-entry-input form-control" >
																			</div>
																			<input type="hidden" name="IdBy_#i#_#idnum#_id" id="IdBy_#i#_#idnum#_id" value="#agent_id#" >
																			<input type="hidden" name="identification_agent_id_#i#_#idnum#" id="identification_agent_id_#i#_#idnum#" value="#identification_agent_id#">
																		</div>
																	</div>
																	<script>
																		makeRichAgentPicker("IdBy_#i#_#idnum#", "IdBy_#i#_#idnum#_id", "IdBy_#i#_#idnum#_icon", "IdBy_#i#_#idnum#_view", #agent_id#);
																	</script>
																</div>
																<cfset idnum=idnum+1>
															</cfloop>
														</div>
														<button id="addIdentifier_#i#" onclick="addIdentifier('#i#','#idnum#')" class="btn btn-xs btn-secondary px-2 mt-3 float-right">Add Identifier</button> 
													</div>
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
														<div class="col-12 col-md-6 pr-0">
															<label for="identification_remarks_#i#" class="data-entry-label">Remarks:</label>
															<input type="text" name="identification_remarks_#i#" id="identification_remarks_#i#" class="data-entry-input" value="#encodeForHtml(identification_remarks)#" >
														</div>
														<div class="col-12 col-md-3">
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
														<div class="col-12 col-md-3 mt-3">
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
											<div class="col-12 mt-2">
												<input type="button" value="Save Changes" aria-label="Save Changes" class="btn btn-xs btn-primary"
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
							<div class="col-12 col-lg-12 float-left px-0">
							<div id="accordion1">
								<div class="card">
									<div class="card-header pt-1" id="headingOnex">
									<h1 class="my-0 px-1 pb-1">
										<button class="btn btn-link w-100 text-left collapsed" data-toggle="collapse" data-target="##collapseOnex" aria-expanded="true" aria-controls="collapseOnex">
											<span class="h4">Add New Determination</span> 
										</button>
									</h1>
									</div>
									<div id="collapseOnex" class="collapse" aria-labelledby="headingOnex" data-parent="##accordion1">
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
											<form name="newIDForm" id="newIDForm">
											<input type="hidden" name="Action" value="createNew">
											<input type="hidden" name="collection_object_id" value="#collection_object_id#" >
											<div class="px-3 mt-0 pt-2 pb-3">
												<div class="row mt-2">
													<div class="col-12 col-md-3">
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
													<div class="col-12 col-md-6">
														<label for="taxona" class="data-entry-label reqdClr" required>Taxon A</label>
														<input type="text" name="taxona" id="taxona" class="reqdClr data-entry-input">
														<input type="hidden" name="taxona_id" id="taxona_id">
													</div>
													<div class="col-12 col-md-3 d-none">
														<label id="taxonb_label" for="taxonb" class="data-entry-label" style="display:none;">Taxon B</label>
														<input type="text" name="taxonb" id="taxonb" class="reqdClr w-100" size="50" style="display:none">
														<input type="hidden" name="taxonb_id" id="taxonb_id">
													</div>
		<!---											<div class="col-12 col-md-6">
														<label for="user_id" class="data-entry-label" >Identification</label>
														<input type="text" name="user_id" id="user_id" class="data-entry-input">
													</div>--->
												</div>
												<div class="row mt-2">
													<div class="col-12 col-md-4 pr-0">
														<label for="newIdBy" id="newIdBy_label" class="data-entry-label mb-0">
														Identified By
														<h5 id="newIdBy_view" class="d-inline p-0 m-0">&nbsp;&nbsp;&nbsp;&nbsp;</h5>
														</label>
														<div class="input-group">
															<div class="input-group-prepend"> <span class="input-group-text smaller bg-lightgreen" id="newIdBy_icon"><i class="fa fa-user" aria-hidden="true"></i></span> </div>
															<input type="text" name="newIdBy" id="newIdBy" class="form-control rounded-right data-entry-input form-control-sm">
															<input type="hidden" name="newIdBy_id" id="newIdBy_id">
														</div>
														<!--- TODO: Add determiners ---> 
													</div>
													<div class="col-12 col-md-4 pr-0">
														<label for="made_date" class="data-entry-label" >Date Identified</label>
														<input type="text" name="made_date" id="made_date" class="data-entry-input">
													</div>
													<div class="col-12 col-md-4">
														<label for="nature_of_id" class="data-entry-label" >Nature of ID <span class="infoLink" onClick="getCtDoc('ctnature_of_id',newID.nature_of_id.value)">Define</span></label>
														<select name="nature_of_id" id="nature_of_id" size="1" class="reqdClr w-100">
															<cfloop query="ctnature">
																<option <cfif #ctnature.nature_of_id# EQ "expert id">selected</cfif> value="#ctnature.nature_of_id#">#ctnature.nature_of_id#</option>
															</cfloop>
														</select>
													</div>
												</div>
												<div class="row mt-2">
													<div class="col-12 col-md-6 pr-0">
														<label for="identification_publication" class="data-entry-label" >Sensu</label>
														<input type="hidden" name="new_publication_id" id="new_publication_id">
														<input type="text" id="newPub" class="data-entry-input">
													</div>
													<div class="col-12 col-md-6">
														<label for="identification_remarks" class="data-entry-label" >Remarks</label>
														<input type="text" name="identification_remarks" id="identification_remarks" class="data-entry-input">
													</div>
												</div>
												<div class="row mt-2">
													<div class="col-12 col-md-12">
														<button id="newID_submit" value="Create" class="btn btn-xs btn-primary" title="Create Identification">Create Identification</button>
													</div>
												</div>
												<script>
													$(document).ready(function() {
														makeScientificNameAutocompleteMeta("taxona", "taxona_id");
														makeScientificNameAutocompleteMeta("taxonb", "taxonb_id");
														makeRichAgentPicker("newIdBy", "newIdBy_id", "newIdBy_icon", "newIdBy_view", null);
														makePublicationAutocompleteMeta("newPub", "new_publication_id");
													});
												</script>
											</div>
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
	<cfthread action="join" name="getEditIdentsThread" />
	<cfreturn getEditIdentsThread.output>
</cffunction>

<!--- function updateIdentifications update the identifications for an arbitrary number of identifications in the identification history of a collection object 
	@param collection_object_id the collecton object to which the identification history pertains
	@param number_of_ids the number of determinations in the identification history
--->
<cffunction name="updateIdentifications" returntype="any" access="remote" returnformat="json">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="number_of_ids" type="string" required="yes">

	<cfoutput>
		<!--- disable trigger that enforces one and only one stored as flag, can't be done inside cftransaction as datasource is different --->
		<cftry>
			<cfquery datasource="uam_god">
				alter trigger tr_stored_as_fg disable
			</cfquery>
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
		</cftransaction>
		<cftry>
			<!--- reeable trigger that enforces one and only one stored as flag, can't be done inside cftransaction as datasource is different --->
			<cfquery datasource="uam_god">
				alter trigger tr_stored_as_fg enable
			</cfquery>
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
		</cfcatch>
		</cftry>
	</cfoutput>
</cffunction>


<!-----------------------------------------------------------------------------------------------------------------> 
<!---function getIdentificationHtml obtain an html block to popluate an edit dialog for an identification 
 @param identification-id the identification.identification_id to edit.
 @return html for editing the identification 
--->
<cffunction name="getIdentificationHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="identification_id" type="string" required="yes">
	<cfargument name="collection_object_id" type="string" required="yes">
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
									<div class="col-md-6 col-sm-12 float-left">
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

<!---getEditOtherIDsHTML obtain a block of html to populate an other ids editor dialog for a specimen.
 @param collection_object_id the collection_object_id for the cataloged item for which to obtain the other ids
	editor dialog.
 @return html for editing other ids for the specified cataloged item. 
--->
<cffunction name="getEditOtherIDsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getEditOtherIDsThread"> 
		<cftry>
			<cfquery name="getIDs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select 
					COLL_OBJ_OTHER_ID_NUM_ID,
					cat_num,
					cat_num_prefix,
					cat_num_integer,
					cat_num_suffix,
					other_id_prefix,
					other_id_number,
					other_id_suffix,
					other_id_type, 
					cataloged_item.collection_id,
					collection.collection_cde,
					institution_acronym
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
			<cfquery name="oids" dbtype="query">
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
					<div class="col-12 mt-2">
						<h1 class="h3">Edit Existing Identifiers</h1>
						<form name="ids" method="post" action="Specimen.cfm">
							<div class="mb-4">
								<input type="hidden" name="collection_object_id" value="#collection_object_id#">
								<input type="hidden" name="Action" value="saveCatEdits">
								Catalog&nbsp;Number:
								<select name="collection_id" size="1" class="reqdClr">
									<cfset thisCollId=#getIDs.collection_id#>
									<cfloop query="ctcoll_cde">
										<option 
											<cfif #thisCollId# is #collection_id#> selected </cfif>
										value="#collection_id#">#institution_acronym# #collection_cde#</option>
									</cfloop>
								</select>
								<input type="text" name="cat_num" value="#cataf.cat_num#" class="reqdClr">
								<input type="submit" value="Save" class="btn btn-xs btn-primary">
							</div>
						</form>
						<cfset i=1>
						<cfloop query="oids">
							<cfif len(#other_id_type#) gt 0>
								<form name="oids#i#" method="post" action="Specimen.cfm">
									<input type="hidden" name="collection_object_id" value="#collection_object_id#">
									<input type="hidden" name="COLL_OBJ_OTHER_ID_NUM_ID" value="#COLL_OBJ_OTHER_ID_NUM_ID#">
									<input type="hidden" name="Action">
									<cfset thisType = #oids.other_id_type#>
									<div class="row mx-0">
										<div class="form-group col-2 pl-0 pr-1">
											<label class="data-entry-label">Other ID Type</label>
											<select name="other_id_type" class="data-entry-select" style="" size="1">				
												<cfloop query="ctType">					
													<option 
														<cfif #ctType.other_id_type# is #thisType#> selected </cfif>
														value="#ctType.other_id_type#">#ctType.other_id_type#</option>
												</cfloop>			
											</select>
										</div>
										<div class="form-group col-2 px-1">
											<label for="other_id_prefix" class="data-entry-label">Other ID Prefix</label>
											<input class="data-entry-input" type="text" value="#encodeForHTML(oids.other_id_prefix)#" size="12" name="other_id_prefix">
										</div>
										<div class="form-group col-2 px-1">
											<label for="other_id_number" class="data-entry-label">Other ID Number</label>
											<input type="text" class="data-entry-input" value="#encodeForHTML(oids.other_id_number)#" size="12" name="other_id_number">
										</div>
										<div class="form-group col-2 px-1">
											<label for="other_id_suffix" class="data-entry-label">Other ID Suffix</label>
											<input type="text" class="data-entry-input" value="#encodeForHTML(oids.other_id_suffix)#" size="12" name="other_id_suffix">
										</div>
										<div class="form-group col-2 px-1 mt-3">
											<input type="button" value="Save" class="btn btn-xs btn-primary" onclick="oids#i#.Action.value='saveOIDEdits';submit();">
											<input type="button" value="Delete" class="btn btn-xs btn-danger" onclick="oids#i#.Action.value='deleOID';confirmDelete('oids#i#');">
										</div>
									</div>
								</form>
							<cfset i=#i#+1>
							</cfif>
						</cfloop>
					</div>
					<div class="col-12 mt-4">
						<div id="accordion2">
							<div class="card">
								<div class="card-header pt-1" id="headingTwo">
									<h1 class="my-0 px-1 pb-1">
										<button class="btn btn-link text-left collapsed" data-toggle="collapse" data-target="##collapseTwo" aria-expanded="true" aria-controls="collapseTwo">
											<span class="h4">Add New Identifier</span>
										</button>
									</h1>
								</div>
								<div id="collapseTwo" class="collapse" aria-labelledby="headingTwo" data-parent="##accordion2">
									<div class="card-body">
										<form name="newOID" method="post" action="Specimens.cfm">
											<div class="row mx-0">
												<div class="form-group col-3 pl-0 pr-1">
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
												<div class="form-group col-2 px-1">
													<label class="data-entry-label" id="other_id_number">Other ID Number</label>
													<input type="text" class="reqdClr data-entry-input" name="other_id_number" size="6">
												</div>
												<div class="form-group col-2 px-1">
													<label class="data-entry-label" id="other_id_suffix">Other ID Suffix</label>
													<input type="text" class="reqdClr data-entry-input" name="other_id_suffix" size="6">		
												</div>
												<div class="form-group col-1 px-1 mt-3">
													<input type="submit" value="Create New Identifier" class="btn btn-xs btn-primary">	
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
	</cfthread>
	<cfthread action="join" name="getEditOtherIDsThread" />
	<cfreturn getEditOtherIDsThread.output>
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
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
			<cfheader statusCode="500" statusText="#message#">
			<cfoutput>
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
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


<cffunction name="getOtherIDsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="coll_obj_other_id_num_id" type="string" required="yes">
	<cfthread name="getOtherIDsThread">
		<cftry>
			<cfoutput>
				<cfquery name="oid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					case when status = 1 and
						concatencumbrances(coll_obj_other_id_num.collection_object_id) like '%mask original field number%' and
						coll_obj_other_id_num.other_id_type = 'original identifier'
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
	<cfthread action="join" name="getOtherIDThread" />
	<cfreturn getOtherIDThread.output>
</cffunction>
		

		
<cffunction name="getEditCollectorsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getEditCollectorsThread"> 
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
			<cfquery name="colls" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT
				collector.coll_order,
				case when
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1 and concatencumbrances(collector.collection_object_id) like '%mask collector%' then 'Anonymous'
				else
					preferred_agent_name.agent_name
				end collectors
			FROM
				collector,
				preferred_agent_name
			WHERE
				collector.collector_role='c' and
				collector.agent_id=preferred_agent_name.agent_id and
				collector.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
			ORDER BY
				coll_order
		</cfquery>
		<cfquery name="preps" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT
				collector.coll_order,
				case when
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1 and concatencumbrances(collector.collection_object_id) like '%mask preparator%' then 'Anonymous'
				else
					preferred_agent_name.agent_name
				end preparators
			FROM
				collector,
				preferred_agent_name
			WHERE
				collector.collector_role='p' and
				collector.agent_id=preferred_agent_name.agent_id and
				collector.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
			ORDER BY
				coll_order
		</cfquery>
			<div class="container-fluid">
				<div class="col-12">
					<div class="row">
						<cfif colls.recordcount gt 0>
							<cfloop query="colls">
								<div class="col-12 mt-3 px-0">
									<div class="form-row border rounded mt-3 pt-2">
									<cfset i = 0>
										<label class="data-entry-label mx-2 pr-0 mt-2 mb-0 col-1 w-auto">Collector</label>
										<input name="collectors" class="mx-2 mt-0 mb-2 col-12 col-md-5 data-entry-input" value="#colls.collectors#">
										<label class="data-entry-label mx-2 mt-2 mb-0 col-1 w-auto text-right">Sort Order</label>
										<input name="sort order" class="mx-2 mt-0 mb-2 col-1 data-entry-input" value="#i#">
										<button class="mr-3 mr-md-5 btn btn-xs btn-danger float-left mb-2 ml-4">Delete</button>
									</div>
							</cfloop>
							<cfset i = i++>
							<button class="btn btn-xs btn-primary mr-2 mt-3 float-left">Save</button>
							<button class="btn btn-xs btn-secondary mx-2 mt-3 float-left">Add Collector</button>
						</cfif>
					</div>
					<div class="row">
						<cfif preps.recordcount gt 0>
							<cfloop query="preps">
								<div class="col-12 mt-3 px-0">
									<cfset i = 0>
										<label class="data-entry-label mx-2 mt-2 mb-0">Collector</label>
										<input name="collectors" class="mx-2 mt-0 mb-2 col-11 col-md-6 data-entry-input" value="#colls.collectors#">
										<label class="data-entry-label mx-2 mt-2 mb-0">Sort Order</label>
										<input name="sort order" class="mx-2 mt-0 mb-2 col-2 data-entry-input" value="#i#">
										<button class="col-5 col-md-2 btn btn-xs btn-primary m-2 float-left">Save</button>
										<button class="col-5 mr-3 col-md-2 mr-md-5 btn btn-xs btn-danger float-left my-2 ml-2">Delete</button>
								</div>
							</cfloop>
							<cfset i = i++>
						</cfif>
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
	<cfthread action="join" name="getEditCollectorsThread" />
	<cfreturn getEditCollectorsThread.output>
</cffunction>
		
<cffunction name="getEditPartsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getEditPartsThread"> 
		<cftry>
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
		<form>
			<div class="container-fluid">
				<div class="row">
					<div class="col-12 mt-3">
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
							<td colspan="5"><span class="pl-3 d-block"><span class="font-italic">Remarks:</span> #part_remarks#</span></td>
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
							<td colspan="5">
								<cfloop query="patt">
									<div class="small pl-3" style="line-height: .9rem;">
										#attribute_type#=#attribute_value#
									<cfif len(attribute_units) gt 0>
										#attribute_units#
									</cfif>
									<cfif len(determined_date) gt 0>
										determined date=<strong>#dateformat(determined_date,"yyyy-mm-dd")#
									</cfif>
									<cfif len(agent_name) gt 0>
										determined by=#agent_name#
									</cfif>
									<cfif len(attribute_remark) gt 0>
										remark=#attribute_remark#
									</cfif>
									</div>
								</cfloop>
							</td>
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
							<td colspan="5">
								<span class="pl-3 d-block">
									<span class="font-italic">Remarks:</span> #part_remarks#
								</span>
							</td>
						</tr>
						</cfif>
					</cfloop>
				</cfloop>
				</tbody>
			</table>
					</div>
				</div>
			</div>
		</form>
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
<cffunction name="getPartsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getPartsThread">
		<cftry>
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
						<td><input class="data-entry-input" size="3" value="#lot_count#"></td>
						<td><input class="data-entry-input" value="#label#"></td>
					</tr>
					<cfif len(part_remarks) gt 0>
						<tr class="small">
							<td colspan="5"><span class="pl-3 d-block"><span class="font-italic">Remarks:</span> <input class="data-entry-input" value="#part_remarks#"></span></td>
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
							<td colspan="5">
								<cfloop query="patt">
									<div class="small pl-3" style="line-height: .9rem;">
										<input class="data-entry-input" value="#attribute_type#=#attribute_value#">
									<cfif len(attribute_units) gt 0>
										<input class="data-entry-input" value="#attribute_units#">
									</cfif>
									<cfif len(determined_date) gt 0>
										<input class="data-entry-input" value="determined date=#dateformat(determined_date,'yyyy-mm-dd')#">
									</cfif>
									<cfif len(agent_name) gt 0>
										<input class="data-entry-input" value="determined by=#agent_name#">
									</cfif>
									<cfif len(attribute_remark) gt 0>
										<input class="data-entry-input" value="remark=#attribute_remark#">
									</cfif>
									</div>
								</cfloop>
							</td>
						</tr>
					</cfif>
					<cfquery name="sPart" dbtype="query">
						select * from parts where sampled_from_obj_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
					</cfquery>
					<cfloop query="sPart">
						<tr>
							<td><span class="d-inline-block pl-3"><input class="data-entry-input" value="#part_name#"> <span class="font-italic">subsample</span></span></td>
							<td><input class="data-entry-input" value="#part_condition#"></td>
							<td><input class="data-entry-input" value="#part_disposition#"></td>
							<td><input class="data-entry-input" value="#lot_count#"></td>
							<td><input class="data-entry-input" value="#label#"></td>
						</tr>
						<cfif len(part_remarks) gt 0>
						<tr class="small">
							<td colspan="5">
								<span class="pl-3 d-block">
									<span class="font-italic">Remarks:</span> <input class="data-entry-input" value="#part_remarks#">
								</span>
							</td>
						</tr>
						</cfif>
					</cfloop>
				</cfloop>
				</tbody>
			</table>
			<cfcatch>
				<cfoutput>
					<p class="mt-2 text-danger">Error: #cfcatch.type# #cfcatch.message# #cfcatch.detail#</p>
				</cfoutput>
			</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getPartsThread" />
	<cfreturn getPartsThread.output>
</cffunction>

<cffunction name="getIdentificationTable" returntype="query" access="remote">
	<cfargument name="identification_id" type="string" required="yes">
	<cfset r=1>
	<cftry>
		<cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select 1 as status, identifications_id, collection_object_id, made_date, nature_of_id, accepted_id_fg,identification_remarks, taxa_formula, scientific_name, publication_id, sort_order, stored_as_fg
			from identification
			where identification_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#identification_id#">
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
<cffunction name="getEditCitationsHTML" returntype="string" access="remote" returnformat="plain">
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
									formatted_publication.formatted_publication,
									formatted_publication.publication_id,
									cited_taxa.taxon_status as cited_name_status
								from
									citation,
									taxonomy cited_taxa,
									formatted_publication
								where
									citation.cited_taxon_name_id = cited_taxa.taxon_name_id AND
									citation.publication_id = formatted_publication.publication_id AND
									format_style='short' and
									citation.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
								order by
									substr(formatted_publication, - 4)
						</cfquery>
						<cfquery name="publicationMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								SELECT
									mr.media_id, m.media_uri, m.preview_uri, ml.label_value descr, m.media_type, m.mime_type
								FROM
									media_relations mr, media_labels ml, media m, citation c, formatted_publication fp
								WHERE
									mr.media_id = ml.media_id and
									mr.media_id = m.media_id and
									ml.media_label = 'description' and
									MEDIA_RELATIONSHIP like '% publication' and
									RELATED_PRIMARY_KEY = c.publication_id and
									c.publication_id = fp.publication_id and
									fp.format_style='short' and
									c.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
								ORDER by substr(formatted_publication, -4)
						</cfquery>
							<cfset i = 1>
							<cfloop query="citations" group="formatted_publication">
								<div class="d-block py-1 px-2 w-100 float-left">
									<span class="d-inline"></span>
									<a href="/SpecimenUsage.cfm?action=search&publication_id=#publication_id#" target="_mainFrame">#formatted_publication#</a>,
									<cfif len(occurs_page_number) gt 0>
										Page
										<cfif len(citation_page_uri) gt 0>
											<a href ="#citation_page_uri#" target="_blank">#occurs_page_number#</a>,
										<cfelse>
										#occurs_page_number#,
										</cfif>
									</cfif>
									<span class="font-weight-lessbold">#type_status#</span> of 
										<a href="/TaxonomyDetails.cfm?taxon_name_id=#cited_name_id#" target="_mainFrame"><i>#replace(cited_name," ","&nbsp;","all")#</i></a>
										<cfif find("(ms)", #type_status#) NEQ 0>
											<!--- Type status with (ms) is used to mark to be published types, for which we aren't (yet) exposing the new name.  Append sp. nov or ssp. nov.as appropriate to the name of the parent taxon of the new name --->
											<cfif find(" ", #cited_name#) NEQ 0>
											&nbsp;ssp. nov.
											<cfelse>
											&nbsp;sp. nov.
											</cfif>
										</cfif>
										<span class="small font-italic">
											<cfif len(citation_remarks) gt 0></cfif>
											#CITATION_REMARKS#
										</span>
								</div>
								<cfset i = i + 1>
							</cfloop>
							<cfif publicationMedia.recordcount gt 0>
								<cfloop query="publicationMedia">
									<cfset puri=getMediaPreview(preview_uri,mime_type)>
									<cfquery name="citationPub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
										select
											media_label,
											label_value
										from
											media_labels
										where
											media_id = <cfqueryparam value="#media_id#" cfsqltype="CF_SQL_DECIMAL">
									</cfquery>
									<cfquery name="labels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
										select
											media_label,
											label_value
										from
											media_labels
										where
											media_id = <cfqueryparam value="#media_id#" cfsqltype="CF_SQL_DECIMAL">
									</cfquery>
									<cfquery name="desc" dbtype="query">
										select 
											label_value 
										from 
											labels 
										where 
											media_label='description'
									</cfquery>
									<cfset alt="Media Preview Image">
									<cfif desc.recordcount is 1>
										<cfset alt=desc.label_value>
									</cfif>
									<div class="col-2 m-2 float-left d-inline">
										<cfset mt = #mime_type#>
										<cfset muri = #media_uri#>
										<a href="#media_uri#" target="_blank">
											<img src="#getMediaPreview(preview_uri,mime_type)#" alt="#alt#" class="mx-auto w-100">
										</a>
										<span class="d-block smaller text-center" style="line-height:.7rem;">
											<a class="d-block" href="/media/#media_id#" target="_blank">Media Record</a> 
										</span>
									</div>
								</cfloop>
							</cfif>	
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
	<cfthread action="join" name="getEditCitationsThread" />
	<cfreturn getEditCitationsThread.output>
</cffunction>					
<cffunction name="getCitationsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getCitationsThread">
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
								formatted_publication.formatted_publication,
								formatted_publication.publication_id,
								cited_taxa.taxon_status as cited_name_status
							from
								citation,
								taxonomy cited_taxa,
								formatted_publication
							where
								citation.cited_taxon_name_id = cited_taxa.taxon_name_id AND
								citation.publication_id = formatted_publication.publication_id AND
								format_style='short' and
								citation.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
							order by
								substr(formatted_publication, - 4)
						</cfquery>
						<cfquery name="publicationMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT
								mr.media_id, m.media_uri, m.preview_uri, ml.label_value descr, m.media_type, m.mime_type
							FROM
								media_relations mr, media_labels ml, media m, citation c, formatted_publication fp
							WHERE
								mr.media_id = ml.media_id and
								mr.media_id = m.media_id and
								ml.media_label = 'description' and
								MEDIA_RELATIONSHIP like '% publication' and
								RELATED_PRIMARY_KEY = c.publication_id and
								c.publication_id = fp.publication_id and
								fp.format_style='short' and
								c.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
							ORDER by substr(formatted_publication, -4)
						</cfquery>
							<cfset i = 1>
							<cfloop query="citations" group="formatted_publication">
								<div class="d-block py-1 px-2 w-100 float-left">
									<span class="d-inline"></span>
									<a href="/SpecimenUsage.cfm?action=search&publication_id=#publication_id#" target="_mainFrame">#formatted_publication#</a>,
									<cfif len(occurs_page_number) gt 0>
										Page
										<cfif len(citation_page_uri) gt 0>
											<a href ="#citation_page_uri#" target="_blank">#occurs_page_number#</a>,
										<cfelse>
										#occurs_page_number#,
										</cfif>
									</cfif>
									<span class="font-weight-lessbold">#type_status#</span> of 
										<a href="/TaxonomyDetails.cfm?taxon_name_id=#cited_name_id#" target="_mainFrame"><i>#replace(cited_name," ","&nbsp;","all")#</i></a>
										<cfif find("(ms)", #type_status#) NEQ 0>
										<!--- Type status with (ms) is used to mark to be published types, for which we aren't (yet) exposing the new name. Append sp. nov or ssp. nov.as appropriate to the name of the parent taxon of the new name --->
											<cfif find(" ", #cited_name#) NEQ 0>
											&nbsp;ssp. nov.
											<cfelse>
											&nbsp;sp. nov.
											</cfif>
										</cfif>
										<span class="small font-italic">
											<cfif len(citation_remarks) gt 0></cfif>
											#CITATION_REMARKS#
										</span>
								</div>
								<cfset i = i + 1>
							</cfloop>
							<cfif publicationMedia.recordcount gt 0>
								<cfloop query="publicationMedia">
									<cfset puri=getMediaPreview(preview_uri,mime_type)>
									<cfquery name="citationPub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
										select
												media_label,
												label_value
										from
												media_labels
										where
												media_id = <cfqueryparam value="#media_id#" cfsqltype="CF_SQL_DECIMAL">
									</cfquery>
									<cfquery name="labels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
										select
												media_label,
												label_value
										from
												media_labels
										where
												media_id = <cfqueryparam value="#media_id#" cfsqltype="CF_SQL_DECIMAL">
									</cfquery>
									<cfquery name="desc" dbtype="query">
										select 
												label_value 
										from 
												labels 
										where 
												media_label='description'
									</cfquery>
									<cfset alt="Media Preview Image">
									<cfif desc.recordcount is 1>
										<cfset alt=desc.label_value>
									</cfif>
									<div class="col-2 m-2 float-left d-inline">
										<cfset mt = #mime_type#>
										<cfset muri = #media_uri#>
										<a href="#media_uri#" target="_blank">
											<img src="#getMediaPreview(preview_uri,mime_type)#" alt="#alt#" class="mx-auto w-100">
										</a>
										<span class="d-block smaller text-center" style="line-height:.7rem;">
											<a class="d-block" href="/media/#media_id#" target="_blank">Media Record</a> 
										</span>
									</div>
								</cfloop>
							</cfif>	
					</div>
			<cfcatch>
				<cfoutput>
					<p class="mt-2 text-danger">Error: #cfcatch.type# #cfcatch.message# #cfcatch.detail#</p>
				</cfoutput>
			</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getCitationsThread" />
	<cfreturn getCitationsThread.output>
</cffunction>							
<cffunction name="getEditAttributesHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getEditAttributesThread"> 
		<cfoutput>
		<cftry>
			<cfquery name="attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
				select * from attribute where attribute_type = 'sex'
			</cfquery>
			<form class="row mx-0">
			<ul class="col-12">
				<cfloop query="sex">
				<li class="list-group-item float-left col-12 col-md-2"> <label>Sex:</label><input class="data-entry-input" value="#attribute_value#"></li>
					<cfif len(attributeDeterminer) gt 0>
					<li class="list-group-item float-left col-12 col-md-3"><label>Determiner:</label> <input class="data-entry-input" value="#attributeDeterminer#"></li>
						<cfif len(determined_date) gt 0>
						<li class="list-group-item float-left col-12 col-md-2"><label class="data-entry-label">Date:</label> <input class="data-entry-input" value="#dateformat(determined_date,'yyyy-mm-dd')#"></li>
						</cfif>
						<cfif len(determination_method) gt 0>
							<li class="list-group-item float-left col-12 col-md-2"><label class="data-entry-label">Method:</label> <input class="data-entry-input" value="#determination_method#"></li>
						</cfif>
						
					</cfif>
					<cfif len(attribute_remark) gt 0>
						<li class="list-group-item float-left col-12 col-md-3"><label class="data-entry-label">Remark:</label> <input class="data-entry-input" value="#attribute_remark#"></li>
					</cfif>
		
				</cfloop>
				</ul>
				<ul class="col-12">
					<cfquery name="code" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select collection_cde from cataloged_item where collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL"> </cfquery>
				<cfif #code.collection_cde# is "Mamm">
					<cfquery name="total_length" dbtype="query">
						select * from attribute where attribute_type = 'total length'
					</cfquery>
					<cfquery name="tail_length" dbtype="query">
						select * from attribute where attribute_type = 'tail length'
					</cfquery>
					<cfquery name="hf" dbtype="query">
						select * from attribute where attribute_type = 'hind foot with claw'
					</cfquery>
					<cfquery name="efn" dbtype="query">
						select * from attribute where attribute_type = 'ear from notch'
					</cfquery>
					<cfquery name="weight" dbtype="query">
						select * from attribute where attribute_type = 'weight'
					</cfquery>
					<cfif
						len(total_length.attribute_units) gt 0 OR
						len(tail_length.attribute_units) gt 0 OR
						len(hf.attribute_units) gt 0 OR
						len(efn.attribute_units) gt 0 OR
						len(weight.attribute_units) gt 0>
						<!---semi-standard measurements --->
						<span class="h5 pt-1 px-2 mb-0">Standard Measurements</span>
						<table class="table table-striped border mb-1 mx-1" aria-label="Standard Measurements">
						
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
						<tr>
							<td>#total_length.attribute_value# #total_length.attribute_units#&nbsp;</td>
							<td>#tail_length.attribute_value# #tail_length.attribute_units#&nbsp;</td>
							<td>#hf.attribute_value# #hf.attribute_units#&nbsp;</td>
							<td>#efn.attribute_value# #efn.attribute_units#&nbsp;</td>
							<td>#weight.attribute_value# #weight.attribute_units#&nbsp;</td>
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
						select * from attribute 
						where attribute_type NOT IN (
						'weight','sex','total length','tail length','hind foot with claw','ear from notch'
						)
					</cfquery>
					<cfelse>
					<!--- not Mamm --->
					<cfquery name="theRest" dbtype="query">
						select * from attribute where attribute_type NOT IN ('sex')
					</cfquery>
				</cfif>
				<cfloop query="theRest">
					<li class="list-group-item">#attribute_type#: #attribute_value#
						<cfif len(attribute_units) gt 0>
							, #attribute_units#
						</cfif>
						<cfif len(attributeDeterminer) gt 0>
						<cfset determination = "&nbsp;&nbsp;#attributeDeterminer#">
						<cfif len(determined_date) gt 0>
							<cfset determination = '#determination#, #dateformat(determined_date,"yyyy-mm-dd")#'>
						</cfif>
						<cfif len(determination_method) gt 0>
							<cfset determination = '#determination#, #determination_method#'>
						</cfif>
							#determination#
						</cfif>
						<cfif len(attribute_remark) gt 0>
							, Remark: #attribute_remark#
						</cfif>
					</li>
				</cfloop>
			</ul>
					</form>
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
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
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
	<cfthread action="join" name="getEditAttributesThread" />
	<cfreturn getEditAttributesThread.output>
</cffunction>		
<cffunction name="getEditLocalityHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getEditLocalityThread"> 
		<cfoutput>
		<cftry>
			<div class="col-5 pl-0 pr-3 mb-2 float-right">
				<img src="/specimens/images/map.png" height="auto" class="w-100 p-1 bg-white mt-2" alt="map placeholder"/>
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
				<!---	<cfif oneOfUs is 0 and cgi.CF_TEMPLATE_PATH contains "/specimens/SpecimenDetailBody.cfm">
				</cfif>--->
				</cfoutput> 
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
			</div>
			<div class="col-7 px-0 float-left">
				<ul class="list-unstyled row mx-0 px-3 py-1 mb-0">
					<cfif len(getLoc.continent_ocean) gt 0>
						<li class="list-group-item col-5 px-0"><em>Continent Ocean:</em></li>
						<li class="list-group-item col-7 px-0">#getLoc.continent_ocean#</li>
					</cfif>
					<cfif len(getLoc.sea) gt 0>
						<li class="list-group-item col-5 px-0"><em>Sea:</em></li>
						<li class="list-group-item col-7 px-0">#getLoc.sea#</li>
					</cfif>
					<cfif len(getLoc.country) gt 0>
						<li class="list-group-item col-5 px-0"><em>Country:</em></li>
						<li class="list-group-item col-7 px-0">#getLoc.country#</li>
					</cfif>
					<cfif len(getLoc.state_prov) gt 0>
						<li class="list-group-item col-5 px-0"><em>State:</em></li>
						<li class="list-group-item col-7 px-0">#getLoc.state_prov#</li>
					</cfif>
					<cfif len(getLoc.feature) gt 0>
						<li class="list-group-item col-5 px-0"><em>Feature:</em></li>
						<li class="list-group-item col-7 px-0">#getLoc.feature#</li>
					</cfif>
					<cfif len(getLoc.county) gt 0>
						<li class="list-group-item col-5 px-0"><em>County:</em></li>
						<li class="list-group-item col-7 px-0">#getLoc.county#</li>
					</cfif>

					<cfif len(getLoc.island_group) gt 0>
						<li class="list-group-item col-5 px-0"><em>Island Group:</em></li>
						<li class="list-group-item col-7 px-0">#getLoc.island_group#</li>
					</cfif>
					<cfif len(getLoc.island) gt 0>
						<li class="list-group-item col-5 px-0"><em>Island:</em></li>
						<li class="list-group-item col-7 px-0">#getLoc.island#</li>
					</cfif>
					<cfif len(getLoc.quad) gt 0>
						<li class="list-group-item col-5 px-0"><em>Quad:</em></li>
						<li class="list-group-item col-7 px-0">#getLoc.quad#</li>
					</cfif>
				</ul>
			</div>
			<div class="col-12 float-left px-0">
				<ul class="list-unstyled bg-light row mx-0 px-3 pt-1 pb-2 mb-0 border-top">
					<cfif len(getLoc.spec_locality) gt 0>
						<li class="list-group-item col-5 px-0"><h5 class="my-0">Specific Locality:</h5></li>
						<li class="list-group-item col-7 px-0 last">#getLoc.spec_locality#</li>
					</cfif>
					<cfif len(getLoc.verbatim_locality) gt 0>
						<li class="list-group-item col-5 px-0"><h5 class="my-0">Verbatim Locality:</h5></li>
						<li class="list-group-item col-7 px-0 ">#getLoc.verbatim_locality#</li>
					</cfif>
					<cfif len(getLoc.collecting_source) gt 0>
						<li class="list-group-item col-5 px-0"><h5 class="my-0">Collecting Source:</h5></li>
						<li class="list-group-item col-7 px-0">#getLoc.collecting_source#</li>
					</cfif>
					<!--- TODO: Display dwcEventDate not underlying began/end dates. --->
					<cfif len(getLoc.began_date) gt 0 AND getLoc.began_date eq #getLoc.ended_date#>
						<li class="list-group-item col-5 px-0"><h5 class="my-0">On Date:</h5></li>
						<li class="list-group-item col-7 px-0">#getLoc.began_date#</li>
					</cfif>
					<cfif len(getLoc.began_date) gt 0 AND getLoc.began_date neq #getLoc.ended_date#>
						<li class="list-group-item col-5 px-0"><h5 class="my-0">Began Date - Ended Date:</h5></li>
						<li class="list-group-item col-7 px-0">#getLoc.began_date# - #getLoc.ended_date#</li>
					</cfif>
					<cfif len(getLoc.verbatim_date) gt 0>
						<li class="list-group-item col-5 px-0"><h5 class="my-0">Verbatim Date:</h5></li>
						<li class="list-group-item col-7 px-0">#getLoc.verbatim_date#</li>
					</cfif>
					<cfif len(getLoc.verbatimcoordinates) gt 0>
						<li class="list-group-item col-5 px-0"><h5 class="my-0">Verbatim Coordinates:</h5></li>
						<li class="list-group-item col-7 px-0">#getLoc.verbatimcoordinates#</li>
					</cfif>
					<cfif len(getLoc.collecting_method) gt 0>
						<li class="list-group-item col-5 px-0"><h5 class="my-0">Collecting Method:</h5></li>
						<li class="list-group-item col-7 px-0">#getLoc.collecting_method#</li>
					</cfif>
					<cfif len(getLoc.coll_event_remarks) gt 0>
						<li class="list-group-item col-5 px-0"><h5 class="my-0">Collecting Event Remarks:</h5></li>
						<li class="list-group-item col-7 px-0">#getLoc.coll_event_remarks#</li>
					</cfif>
					<cfif len(getLoc.habitat_desc) gt 0>
						<li class="list-group-item col-5 px-0"><h5 class="my-0">Habitat Description:</h5></li>
						<li class="list-group-item col-7 px-0">#getLoc.habitat_desc#</li>
					</cfif>
					<cfif len(getLoc.habitat) gt 0>
						<li class="list-group-item col-5 px-0"><em>Microhabitat:</em></li>
						<li class="list-group-item col-7 px-0">#getLoc.habitat#</li>
					</cfif>
				</ul>
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
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
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
	<cfthread action="join" name="getEditLocalityThread" />
	<cfreturn getEditLocalityThread.output>
</cffunction>							
<cffunction name="getEditRelationsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getEditRelationsThread"> 
		<cfoutput>
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
				<ul class="list-group list-group-flush float-left">
					<cfloop query="relns">
						<li class="list-group-item py-0"> #biol_indiv_relationship# <a href="/Specimen.cfm?collection_object_id=#related_coll_object_id#" target="_top"> #related_collection# #related_cat_num# </a>
							<cfif len(relns.biol_indiv_relation_remarks) gt 0>
								(Remark: #biol_indiv_relation_remarks#)
							</cfif>
						</li>
					</cfloop>
					<cfif len(relns.biol_indiv_relationship) gt 0>
						<li class="pb-1 list-group-item">
							<a href="/Specimen.cfm?collection_object_id=#valuelist(relns.related_coll_object_id)#" target="_top">(Specimens List)</a>
						</li>
					</cfif>
				</ul>
			</cfif>

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
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
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
	<cfthread action="join" name="getEditRelationsThread" />
	<cfreturn getEditRelationsThread.output>
</cffunction>		
						
<cffunction name="getAttributesHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getAttributesThread"> 
		<cfoutput>
		<cftry>
			<cfquery name="attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
				select * from attribute where attribute_type = 'sex'
			</cfquery>
			<ul class="list-group">
				<cfloop query="sex">
				<li class="list-group-item"> sex: #attribute_value#,
					<cfif len(attributeDeterminer) gt 0>
						<cfset determination = "#attributeDeterminer#">
						<cfif len(determined_date) gt 0>
							<cfset determination = '#determination#, #dateformat(determined_date,"yyyy-mm-dd")#'>
						</cfif>
						<cfif len(determination_method) gt 0>
							<cfset determination = '#determination#, #determination_method#'>
						</cfif>
						#determination#
					</cfif>
					<cfif len(attribute_remark) gt 0>
						, Remark: #attribute_remark#
					</cfif>
				</li>
			</cfloop>
				
					<cfquery name="total_length" dbtype="query">
						select * from attribute where attribute_type = 'total length'
					</cfquery>
					<cfquery name="tail_length" dbtype="query">
						select * from attribute where attribute_type = 'tail length'
					</cfquery>
					<cfquery name="hf" dbtype="query">
						select * from attribute where attribute_type = 'hind foot with claw'
					</cfquery>
					<cfquery name="efn" dbtype="query">
						select * from attribute where attribute_type = 'ear from notch'
					</cfquery>
					<cfquery name="weight" dbtype="query">
						select * from attribute where attribute_type = 'weight'
					</cfquery>
					<cfif
						len(total_length.attribute_units) gt 0 OR
						len(tail_length.attribute_units) gt 0 OR
						len(hf.attribute_units) gt 0 OR
						len(efn.attribute_units) gt 0 OR
						len(weight.attribute_units) gt 0>
						<!---semi-standard measurements --->
						<span class="h5 pt-1 px-2 mb-0">Standard Measurements</span>
						<table class="table table-striped border mb-1 mx-1" aria-label="Standard Measurements">
						<tr>
							<td><font size="-1">total length</font></td>
							<td><font size="-1">tail length</font></td>
							<td><font size="-1">hind foot</font></td>
							<td><font size="-1">efn</font></td>
							<td><font size="-1">weight</font></td>
						</tr>
						<tr>
							<td>#total_length.attribute_value# #total_length.attribute_units#&nbsp;</td>
							<td>#tail_length.attribute_value# #tail_length.attribute_units#&nbsp;</td>
							<td>#hf.attribute_value# #hf.attribute_units#&nbsp;</td>
							<td>#efn.attribute_value# #efn.attribute_units#&nbsp;</td>
							<td>#weight.attribute_value# #weight.attribute_units#&nbsp;</td>
						</tr>
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
				
					<cfquery name="theRest" dbtype="query">
						select * from attribute 
						where attribute_type NOT IN (
						'weight','sex','total length','tail length','hind foot with claw','ear from notch'
						)
					</cfquery>
					<cfelse>
					<!--- not Mamm --->
					<cfquery name="theRest" dbtype="query">
						select * from attribute where attribute_type NOT IN ('sex')
					</cfquery>
				</cfif>
				<cfloop query="theRest">
					<li class="list-group-item">#attribute_type#: #attribute_value#
						<cfif len(attribute_units) gt 0>
							, #attribute_units#
						</cfif>
						<cfif len(attributeDeterminer) gt 0>
						<cfset determination = "&nbsp;&nbsp;#attributeDeterminer#">
						<cfif len(determined_date) gt 0>
							<cfset determination = '#determination#, #dateformat(determined_date,"yyyy-mm-dd")#'>
						</cfif>
						<cfif len(determination_method) gt 0>
							<cfset determination = '#determination#, #determination_method#'>
						</cfif>
							#determination#
						</cfif>
						<cfif len(attribute_remark) gt 0>
							, Remark: #attribute_remark#
						</cfif>
					</li>
				</cfloop>
			</ul>
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
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
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
	<cfthread action="join" name="getAttributesThread" />
	<cfreturn getAttributesThread.output>
</cffunction>
				
<cffunction name="getEditTransactionsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getEditTransactionsThread"> 
		<cfoutput>
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
		<cfif (not isdefined("collection_object_id")) or (isdefined("collection_object_id") and listlen(collection_object_id) gt 1)>
			,#session.SpecSrchTab#
		</cfif>
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
    <div class="basic_wide_box" style="width: 75em;">
	Add all the items listed below to accession:
	<form name="addItems" method="post" action="Specimen.cfm">
		<input type="hidden" name="Action" value="addItems">
		<cfif isdefined("collection_object_id") and listlen(collection_object_id) is 1>
			<input type="hidden" name="collection_object_id" value="#collection_object_id#">
		</cfif>
		<table border="1">
			<tr>
				<td>
					<label for="accn_number">Accession</label>
					<input type="text" name="accn_number" id="accn_number" onchange="findAccession();">
				</td>
     			<td>
					<div id="g_num" class="noShow" style="font-size: 13px;padding:3px;text-align: center;"> Accession Valid<br/>
						<input type="submit" id="s_btn" value="Add Items" class="savBtn">
					</div>
					<div id="b_num" style="font-size: 13px;padding:3px;">
						TAB to see if valid accession<br/> - nothing happens if invalid -
					</div>
					
				</td>
                <td>
                 <a href="/Transactions.cfm?action=findAccessions" target="_blank">Lookup</a>
                </td>
			</tr>
		</table>	
	</form>
	<table border width="100%" style="font-size: 15px;">
	<tr>
		<td>Cat Num</td>
		<td>Scientific Name</td>
		<td>Accn</td>
		<td>Collectors</td>
		<td>Geog</td>
		<td>Spec Loc</td>
		<td>Date</td>
		
	</tr>

	<cfoutput query="getItems">
	<tr>
		<td>#collection# #cat_num#</td>
		<td style="width: 200px;">#scientific_name#</td>
		<td><a href="/SpecimenResults.cfm?Accn_trans_id=#transaction_id#" target="_top">#accnColln# #Accn_number#</a></td>
		<td style="width: 200px;">
<!---			<cfquery name="getAgent" dbtype="query">
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
		#colls#---></td>
		<td>#higher_geog#</td>
		<td>#spec_locality#</td>
		<td style="width:100px;">#verbatim_date#</td>
	</tr>
</cfoutput>
</table>
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
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
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
	<cfthread action="join" name="getEditTransactionsThread" />
	<cfreturn getEditTransactionsThread.output>
</cffunction>	
						
<cffunction name="getTransactionsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getTransactionsThread"> 
		<cfoutput>
		<cftry>
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
						media_relations.related_primary_key = <cfqueryparam value="#one.accn_id#" cfsqltype="CF_SQL_DECIMAL">
				</cfquery>
				<cfif oneOfUs is 1 and vpdaccn is 1>

							<ul class="list-group list-group-flush pl-0">
								<li class="list-group-item"><h5 class="mb-0 d-inline-block">Accession:</h5>
									<cfif oneOfUs is 1>
										<a href="/transactions/Accession.cfm?action=edit&transaction_id=#one.accn_id#" target="_blank">#accession#</a>
										<cfelse>
										#accession#
									</cfif>
									<cfif accnMedia.recordcount gt 0>
										<cfloop query="accnMedia">
											<div class="m-2 d-inline"> 
												<cfset mt = #media_type#>
												<a href="/media/#media_id#" target="_blank">
													<img src="#getMediaPreview('preview_uri','media_type')#" class="d-block border rounded" width="100" alt="#descr#">Media Details
												</a>
												<span class="small d-block">#media_type# (#mime_type#)</span>
												<span class="small d-block">#descr#</span> 
											</div>
										</cfloop>
									</cfif>
								</li>
								
								----------------- Project / Usage ---------------------------------
								
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
										<li class="list-group-item"><h5 class="mb-0 d-inline-block">Contributed By Project:</h5>
											<a href="/ProjectDetail.cfm?src=proj&project_id=#isProj.project_id#">#isProj.project_name#</a> </li>
									</cfloop>
									<cfloop query="isLoan">
										<li class="list-group-item"><h5 class="mb-0 d-inline-block">Used By Project:</h5> 
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
			
				</cfif>
			
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
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
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
	<cfthread action="join" name="getTransactionsThread" />
	<cfreturn getTransactionsThread.output>
</cffunction>	
						
						
						
<cffunction name="getLocalityHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getLocalityThread"> 
		<cfoutput>
		<cftry>
			<div class="col-5 pl-0 pr-3 mb-2 float-right">
				<img src="/specimens/images/map.png" height="auto" class="w-100 p-1 bg-white mt-2" alt="map placeholder"/>
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
				<!---	<cfif oneOfUs is 0 and cgi.CF_TEMPLATE_PATH contains "/specimens/SpecimenDetailBody.cfm">
				</cfif>--->
				</cfoutput> 
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
			</div>
			<div class="col-7 px-0 float-left">
				<ul class="list-unstyled row mx-0 px-3 py-1 mb-0">
					<cfif len(getLoc.continent_ocean) gt 0>
						<li class="list-group-item col-5 px-0"><em>Continent Ocean:</em></li>
						<li class="list-group-item col-7 px-0">#getLoc.continent_ocean#</li>
					</cfif>
					<cfif len(getLoc.sea) gt 0>
						<li class="list-group-item col-5 px-0"><em>Sea:</em></li>
						<li class="list-group-item col-7 px-0">#getLoc.sea#</li>
					</cfif>
					<cfif len(getLoc.country) gt 0>
						<li class="list-group-item col-5 px-0"><em>Country:</em></li>
						<li class="list-group-item col-7 px-0">#getLoc.country#</li>
					</cfif>
					<cfif len(getLoc.state_prov) gt 0>
						<li class="list-group-item col-5 px-0"><em>State:</em></li>
						<li class="list-group-item col-7 px-0">#getLoc.state_prov#</li>
					</cfif>
					<cfif len(getLoc.feature) gt 0>
						<li class="list-group-item col-5 px-0"><em>Feature:</em></li>
						<li class="list-group-item col-7 px-0">#getLoc.feature#</li>
					</cfif>
					<cfif len(getLoc.county) gt 0>
						<li class="list-group-item col-5 px-0"><em>County:</em></li>
						<li class="list-group-item col-7 px-0">#getLoc.county#</li>
					</cfif>

					<cfif len(getLoc.island_group) gt 0>
						<li class="list-group-item col-5 px-0"><em>Island Group:</em></li>
						<li class="list-group-item col-7 px-0">#getLoc.island_group#</li>
					</cfif>
					<cfif len(getLoc.island) gt 0>
						<li class="list-group-item col-5 px-0"><em>Island:</em></li>
						<li class="list-group-item col-7 px-0">#getLoc.island#</li>
					</cfif>
					<cfif len(getLoc.quad) gt 0>
						<li class="list-group-item col-5 px-0"><em>Quad:</em></li>
						<li class="list-group-item col-7 px-0">#getLoc.quad#</li>
					</cfif>
				</ul>
			</div>
			<div class="col-12 float-left px-0">
				<ul class="list-unstyled bg-light row mx-0 px-3 pt-1 pb-2 mb-0 border-top">
					<cfif len(getLoc.spec_locality) gt 0>
						<li class="list-group-item col-5 px-0"><h5 class="my-0">Specific Locality:</h5></li>
						<li class="list-group-item col-7 px-0 last">#getLoc.spec_locality#</li>
					</cfif>
					<cfif len(getLoc.verbatim_locality) gt 0>
						<li class="list-group-item col-5 px-0"><h5 class="my-0">Verbatim Locality:</h5></li>
						<li class="list-group-item col-7 px-0 ">#getLoc.verbatim_locality#</li>
					</cfif>
					<cfif len(getLoc.collecting_source) gt 0>
						<li class="list-group-item col-5 px-0"><h5 class="my-0">Collecting Source:</h5></li>
						<li class="list-group-item col-7 px-0">#getLoc.collecting_source#</li>
					</cfif>
					<!--- TODO: Display dwcEventDate not underlying began/end dates. --->
					<cfif len(getLoc.began_date) gt 0 AND getLoc.began_date eq #getLoc.ended_date#>
						<li class="list-group-item col-5 px-0"><h5 class="my-0">On Date:</h5></li>
						<li class="list-group-item col-7 px-0">#getLoc.began_date#</li>
					</cfif>
					<cfif len(getLoc.began_date) gt 0 AND getLoc.began_date neq #getLoc.ended_date#>
						<li class="list-group-item col-5 px-0"><h5 class="my-0">Began Date - Ended Date:</h5></li>
						<li class="list-group-item col-7 px-0">#getLoc.began_date# - #getLoc.ended_date#</li>
					</cfif>
					<cfif len(getLoc.verbatim_date) gt 0>
						<li class="list-group-item col-5 px-0"><h5 class="my-0">Verbatim Date:</h5></li>
						<li class="list-group-item col-7 px-0">#getLoc.verbatim_date#</li>
					</cfif>
					<cfif len(getLoc.verbatimcoordinates) gt 0>
						<li class="list-group-item col-5 px-0"><h5 class="my-0">Verbatim Coordinates:</h5></li>
						<li class="list-group-item col-7 px-0">#getLoc.verbatimcoordinates#</li>
					</cfif>
					<cfif len(getLoc.collecting_method) gt 0>
						<li class="list-group-item col-5 px-0"><h5 class="my-0">Collecting Method:</h5></li>
						<li class="list-group-item col-7 px-0">#getLoc.collecting_method#</li>
					</cfif>
					<cfif len(getLoc.coll_event_remarks) gt 0>
						<li class="list-group-item col-5 px-0"><h5 class="my-0">Collecting Event Remarks:</h5></li>
						<li class="list-group-item col-7 px-0">#getLoc.coll_event_remarks#</li>
					</cfif>
					<cfif len(getLoc.habitat_desc) gt 0>
						<li class="list-group-item col-5 px-0"><h5 class="my-0">Habitat Description:</h5></li>
						<li class="list-group-item col-7 px-0">#getLoc.habitat_desc#</li>
					</cfif>
					<cfif len(getLoc.habitat) gt 0>
						<li class="list-group-item col-5 px-0"><em>Microhabitat:</em></li>
						<li class="list-group-item col-7 px-0">#getLoc.habitat#</li>
					</cfif>
				</ul>
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
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
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
	<cfthread action="join" name="getLocalityThread" />
	<cfreturn getLocalityThread.output>
</cffunction>



<cffunction name="getCollectorsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getCollectorsThread">
		<cftry>
		<cfoutput>
			<ul class="list-unstyled list-group form-row p-1 mb-0">
					<cfif colls.recordcount gt 0>
						<li class="list-group-item"><h5 class="my-0">Collector(s):&nbsp;</h5>
							<cfloop query="colls">
								#colls.collectors#<span>,</span>
							</cfloop>
						</li>
					</cfif>
					<cfif preps.recordcount gt 0>
						<li class="list-group-item"><h5 class="my-0">Preparator(s):&nbsp;</h5>
							<cfloop query="preps">
								#preps.preparators#<span>,</span>
							</cfloop>
						</li>
					</cfif>
				</ul></cfoutput>
			<cfcatch>
				<cfoutput>
					<p class="mt-2 text-danger">Error: #cfcatch.type# #cfcatch.message# #cfcatch.detail#</p>
				</cfoutput>
			</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getCollectorsThread" />
	<cfreturn getCollectorsThread.output>
</cffunction>
</cfcomponent>
