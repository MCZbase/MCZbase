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

<!---THIS? getEditIdentificationsHTML obtain a block of html to populate an identification editor dialog for a specimen.
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
						<div class="col-12" id="buttons">
							<button type="button" class="dialogBtn btn btn-xs btn-secondary small mt-0 p-1 mx-2" onClick="openEditIdentificationsDialog(#collection_object_id#,'identificationsDialog')">Identifications</button>
							<button type="button" class="dialogBtn btn btn-xs btn-secondary small mt-0 p-1 mx-1" onClick="openEditCitationsDialog(#collection_object_id#,'citationsDialog')">Citations</button>
							<button type="button" class="dialogBtn btn btn-xs  btn-secondary small mt-0 p-1 mx-2" onClick="openEditOtherIDsDialog(#collection_object_id#,'otherIDsDialog')">Other IDs</button>
							<button type="button" class="dialogBtn btn btn-xs btn-secondary small mt-0 p-1 mx-2" onClick="openEditIdentificationsDialog(#collection_object_id#,'identificationsDialog')">Parts</button>
							<button type="button" class="dialogBtnbtn btn-xs btn-secondary small mt-0 p-1 mx-2" onClick="openEditCitationsDialog(#collection_object_id#,'citationsDialog')">Attributes</button>
							<button type="button" class="dialogBtn btn btn-xs  btn-secondary small mt-0 p-1 mx-2" onClick="openEditOtherIDsDialog(#collection_object_id#,'otherIDsDialog')">Relationships</button>
						</div>
						<div class="col-10 mt-2">
							<div class="col-12 col-lg-12 float-left mb-4 px-0">
							<form name="editIdentification" id="editIdentification" method="post" action="editIdentification.cfm">
								<h1 class="h3 px-1"> <span style="font-size: 1.25rem;">Edit Existing Determinations <a href="javascript:void(0);" onClick="getMCZDocs('identification')"><i class="fa fa-info-circle"></i></a></span> </h1>
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
												accepted_id_fg, sort_order DESC
										</cfquery>
										<cfset i = 1>
										<cfset sortCount=getIds.recordcount - 1>
										<input type="hidden" name="Action" value="saveEdits">
										<input type="hidden" name="collection_object_id" value="#collection_object_id#" >
										<input type="hidden" name="number_of_ids" id="number_of_ids" value="#getIds.recordcount#">
										<cfloop query="getIds">
											<cfquery name="identifiers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
											<input type="hidden" name="number_of_identifiers_#i#" id="number_of_identifiers_#i#" value="#identifiers.recordcount#">
											<div class="col-12 border bg-light px-3 rounded mt-0 mb-2 pt-2 pb-3">
												<div class="row mt-2">
													<div class="col-12 col-md-6 pr-0"> 
														<!--- TODO: A/B pickers --->
														<label for="scientific_name_#i#" class="data-entry-label">Scientific Name</label>
														<input type="text" name="scientific_name_#i#" id="scientific_name_#i#" class="data-entry-input" readonly="true" value="#scientific_name#">
													</div>
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
														<span class="infoLink text-dander" onclick="document.getElementById('accepted_id_fg_#i#').value='DELETE';flippedAccepted('#i#');">Delete</span>
														</cfif>
													</div>
												</div>
												<div class="row mt-2">
													<div class="col-6 px-0">
														<cfset idnum=1>
														<cfloop query="identifiers">
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
													<span id="addIdentifier_#i#" onclick="addIdentifier('#i#','#idnum#')" class="infoLink col-2 px-0 mt-4 float-right" style="display: inline-block;padding-right: 1em;">Add Identifier</span> 
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
											<input type="submit" class="savBtn btn btn-xs btn-primary" id="editIdentification_submit" value="Save Changes" title="Save Changes">
										</div>
									</div>
								</div>
							</form>
						</div>
							<div class="col-12 col-lg-12 float-left px-0">
							<div id="accordion1">
								<div class="card">
									<div class="card-header" id="headingOnex">
									<h1 class="my-0 px-1 pb-2">
										<button class="btn btn-link w-100 text-left collapsed" data-toggle="collapse" data-target="##collapseOnex" aria-expanded="true" aria-controls="collapseOnex">
											<span style="font-size: 1.25rem;">Add New Determination</span> 
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
												<select name="taxa_formula" id="taxa_formula" size="1" 
																			 class="reqdClr w-100" required 
																			 onchange="idFormulaChanged(this.value,'taxonb');">
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
											<div class="col-12 col-md-3">
												<label for="taxona" class="data-entry-label reqdClr" required>Taxon A</label>
												<input type="text" name="taxona" id="taxona" class="reqdClr data-entry-input" size="50">
												<input type="hidden" name="taxona_id" id="taxona_id">
											</div>
											<div class="col-12 col-md-3 d-none">
												<label id="taxonb_label" for="taxonb" class="data-entry-label" style="display:none;">Taxon B</label>
												<input type="text" name="taxonb" id="taxonb" class="reqdClr w-100" size="50" style="display:none">
												<input type="hidden" name="taxonb_id" id="taxonb_id">
											</div>
											<div class="col-12 col-md-6">
												<label for="user_id" class="data-entry-label" >Identification</label>
												<input type="text" name="user_id" id="user_id" class="data-entry-input">
											</div>
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
<!-----------------------------------------------------------------------------------------------------------------> 
<!---THIS? function getIdentificationHtml obtain an html block to popluate an edit dialog for an identification 
 @param identification-id the identification.identification_id to edit.
 @return html for editing the identification 
--->
<cffunction name="getIdentificationHtml" returntype="string" access="remote" returnformat="plain">
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

<!---THIS? getEditIdentificationsHTML obtain a block of html to populate an identification editor dialog for a specimen.
 @param collection_object_id the collection_object_id for the cataloged item for which to obtain the identification
	editor dialog.
 @return html for editing identifications for the specified cataloged item. 
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
					<div class="col-12">
						<button type="button" class="btn btn-xs btn-secondary small mt-0 p-1" onClick="openEditIdentificationsDialog(#collection_object_id#,'identificationsDialog')">Identifications</button>
						<button type="button" class="btn btn-xs btn-secondary small mt-0 p-1" onClick="openEditCitationsDialog(#collection_object_id#,'citationsDialog')">Citations</button>
						<button type="button" class="btn btn-xs  btn-secondary small mt-0 p-1" onClick="openEditOtherIDsDialog(#collection_object_id#,'otherIDsDialog')">Other IDs</button>
						<button type="button" class="btn btn-xs btn-secondary small mt-0 p-1" onClick="openEditIdentificationsDialog(#collection_object_id#,'identificationsDialog')">Parts</button>
						<button type="button" class="btn btn-xs btn-secondary small mt-0 p-1" onClick="openEditAttributesDialog(#collection_object_id#,'cattributesDialog')">Attributes</button>
						<button type="button" class="btn btn-xs  btn-secondary small mt-0 p-1" onClick="openEditOtherIDsDialog(#collection_object_id#,'otherIDsDialog')">Relationships</button>
					</div>
					<h1 class="h3">Edit existing identifiers:</h1>
					<form name="ids" method="post" action="editIdentifiers.cfm">
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
							<input type="text" name="cat_num" value="#catAF.cat_num#" class="reqdClr">
							<input type="submit" value="Save" class="btn btn-xs btn-primary">
						</div>
					</form>
					<cfset i=1>
					<cfloop query="oids">
						<cfif len(#other_id_type#) gt 0>
							<form name="oids#i#" method="post" action="editIdentifiers.cfm">
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
										<input type="text" class="data-entry-input" value="#encodeForHTML(oids.other_id_suffix)#" size="12"  name="other_id_suffix">
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
					<div class="col-12 px-0 mt-4">
						<div id="accordion2">
							<div class="card">
							<div class="card-header" id="headingTwo">
								<h1 class="my-0 px-1 pb-1">
								<button class="btn btn-link text-left collapsed" data-toggle="collapse" data-target="##collapseTwo" aria-expanded="true" aria-controls="collapseTwo">
									<span style="font-size: 1.25rem;">Add New Identifier</span>
								</button>
							</h1>
							</div>
							<div id="collapseTwo" class="collapse" aria-labelledby="headingTwo" data-parent="##accordion2">
								<div class="card-body">
									<form name="newOID" method="post" action="editIdentifiers.cfm">
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
												<label class="data-entry-label" id="other_id_number">Other ID Number</label>
												<input type="text" class="reqdClr data-entry-input" name="other_id_suffix" size="6">		
											</div>
											<div class="form-group col-1 px-1 mt-3">
												<input type="submit" value="Save" class="btn btn-xs btn-primary">	
											</div>
										</div>
									</form>
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
	<cfthread action="join" name="getEditOtherIDsThread" />
	<cfreturn getEditOtherIDsThread.output>
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
						<td><span class="">#part_name#</span></td>
						<td>#part_condition#</td>
						<td>#part_disposition#</td>
						<td>#lot_count#</td>
						<td>#label#</td>
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
						<td><span class="">#part_name#</span></td>
						<td>#part_condition#</td>
						<td>#part_disposition#</td>
						<td>#lot_count#</td>
						<td>#label#</td>
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
			where identification_id  =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#identification_id#">
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
									citation.cited_taxon_name_id = cited_taxa.taxon_name_id  AND
									citation.publication_id = formatted_publication.publication_id AND
									format_style='short' and
									citation.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
								order by
									substr(formatted_publication, - 4)
						</cfquery>
						<cfquery name="publicationMedia"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
									<cfquery name="citationPub"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
										select
											media_label,
											label_value
										from
											media_labels
										where
											media_id = <cfqueryparam value="#media_id#" cfsqltype="CF_SQL_DECIMAL">
									</cfquery>
									<cfquery name="labels"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
								citation.cited_taxon_name_id = cited_taxa.taxon_name_id  AND
								citation.publication_id = formatted_publication.publication_id AND
								format_style='short' and
								citation.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
							order by
								substr(formatted_publication, - 4)
						</cfquery>
						<cfquery name="publicationMedia"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
									<cfquery name="citationPub"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
										select
												media_label,
												label_value
										from
												media_labels
										where
												media_id = <cfqueryparam value="#media_id#" cfsqltype="CF_SQL_DECIMAL">
									</cfquery>
									<cfquery name="labels"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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


</cfcomponent>
