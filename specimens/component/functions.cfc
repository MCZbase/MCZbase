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

<cffunction name="getIdentifications" returntype="query" access="remote">
	<cfargument name="identification_id" type="string" required="yes">
	<cftry>
		<cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select 1 as status, identification_id, collection_object_id, nature_of_id, accepted_id_fg,
				identification_remarks, taxa_formula, scientific_name, publication_id, sort_order, stored_as_fg
			from identification
			where identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#identification_id#">
		</cfquery>
		<cfif theResult.recordcount eq 0>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "0", 1)>
			<cfset t = QuerySetCell(theResult, "message", "No identifications found.", 1)>
		</cfif>
	<cfcatch>
		<cfset theResult=queryNew("status, message")>
		<cfset t = queryaddrow(theResult,1)>
		<cfset t = QuerySetCell(theResult, "status", "-1", 1)>
		<cfset t = QuerySetCell(theResult, "message", "#cfcatch.type# #cfcatch.message# #cfcatch.detail#", 1)>
	</cfcatch>
	</cftry>
	<cfreturn theResult>
</cffunction>

<!--- getEditIdentificationsHTML obtain a block of html to populate an identification edtior dialog for a specimen.
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
						<div class="col-12 px-0">
							<!--- form name="newID" id="newID" method="post" action="editIdentification.cfm" --->
        					<h1 class="h3 wikilink mb-0 px-1">
								Add New Determination
								<a href="javascript:void(0);" onClick="getMCZDocs('identification')"><img src="/images/info.gif" border="0"></a>
							</h1>
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
									<div class="border bg-light px-3 rounded mt-0 pt-2 pb-3">
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
											<div class="col-12 col-md-5">
												<label for="user_id" class="data-entry-label" >Identification</label>
		  										<input type="text" name="user_id" id="user_id" class="data-entry-input">
											</div>
										</div>
										<div class="row mt-2">
											<div class="col-12 col-md-4">
												<label for="newIdBy" id="newIdBy_label" class="data-entry-label mb-0">Identified By
													<h5 id="newIdBy_view" class="d-inline p-0 m-0">&nbsp;&nbsp;&nbsp;&nbsp;</h5> 
												</label>
												<div class="input-group">
													<div class="input-group-prepend">
														<span class="input-group-text smaller bg-lightgreen" id="newIdBy_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
													</div>
													<input type="text" name="newIdBy" id="newIdBy" class="form-control rounded-right data-entry-input form-control-sm">
            									<input type="hidden" name="newIdBy_id" id="newIdBy_id">
												</div>
												<!--- TODO: Add determiners --->
											</div>
											<div class="col-12 col-md-4">
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
											<div class="col-12 col-md-8">
												<label for="identification_publication" class="data-entry-label" >Sensu</label>
												<input type="hidden" name="new_publication_id" id="new_publication_id">
												<input type="text" id="newPub" class="data-entry-input">
											</div>
										</div>
										<div class="row mt-2">
											<div class="col-12 col-md-8">
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
					<form name="editIdentification" id="editIdentification" method="post" action="editIdentification.cfm">
						<h1 class="h3 mb-0 px-1">
								Edit Existing Determinations
								<a href="javascript:void(0);" onClick="getMCZDocs('identification')"><i class="fa fa-info-circle"></i></a>
								</h1>
						<div class="border bg-light px-3 rounded mt-0 pt-2 pb-3">
						<div class="row">
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
									<!---<div class="row border bg-light px-3 rounded mt-2 pt-2 pb-3">--->
										<cfquery name="identifiers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
											SELECT distinct
												agent_name, identifier_order,
												identification_agent.agent_id, identification_agent_id
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
										<div class="col-12">
											<div class="row mt-2">
												<div class="col-12 col-md-5">
													<!--- TODO: A/B pickers --->
													<label for="scientific_name_#i#" class="data-entry-label">Scientific Name</label>
			  										<input type="text" name="scientific_name_#i#" id="scientific_name_#i#" 
														class="data-entry-input" readonly="true" value="#scientific_name#">
												</div>
												<div class="col-12 col-md-3">
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
													<select name="accepted_id_fg_#i#" id="accepted_id_fg_#i#" size="1" #read#
															class="reqdClr w-50" onchange="flippedAccepted('#i#')">
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
												<div class="col-12">
													<cfset idnum=1>
													<cfloop query="identifiers">
														<div class="row" id="IdTr_#i#_#idnum#">
															<div class="col-12 col-md-6">
																<label for="IdBy_#i#_#idnum#">Identified By
																	<h5 id="IdBy_#i#_#idnum#_view" class="d-inline">&nbsp;&nbsp;&nbsp;&nbsp;</h5> 
																</label>
																<div class="input-group">
																	<div class="input-group-prepend">
																		<span class="input-group-text smaller bg-lightgreen" id="IdBy_#i#_#idnum#_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
																	</div>
																	<input type="text" name="IdBy_#i#_#idnum#" id="IdBy_#i#_#idnum#"
																		value="#agent_name#" class="reqdClr data-entry-input form-control" >
																</div>
																<input type="hidden" name="IdBy_#i#_#idnum#_id" id="IdBy_#i#_#idnum#_id" value="#agent_id#" >
																<input type="hidden" name="identification_agent_id_#i#_#idnum#" id="identification_agent_id_#i#_#idnum#"
																	value="#identification_agent_id#">
															</div>
															<div class="col-12 col-md-6">
																<cfif #idnum# gt 1>
																	<img src="/images/del.gif" class="likeLink" onclick="removeIdentifier('#i#','#idnum#')" />
																</cfif>
															</div>
															<script>
																makeRichAgentPicker("IdBy_#i#_#idnum#", "IdBy_#i#_#idnum#_id", "IdBy_#i#_#idnum#_icon", "IdBy_#i#_#idnum#_view", #agent_id#);
															</script>
														</div>
														<cfset idnum=idnum+1>
													</cfloop>
													<span class="infoLink" id="addIdentifier_#i#"
														onclick="addIdentifier('#i#','#idnum#')" style="display: inline-block;padding-right: 1em;">Add Identifier</span>
												</div>
											</div>
											<div class="row mt-2">
												<div class="col-12 col-md-3">
													<label for="made_date_#i#" class="data-entry-label">ID Date</label>
													<input type="text" value="#made_date#" name="made_date_#i#" id="made_date_#i#" class="data-entry-input">
												</div>
												<div class="col-12 col-md-3">
													<label for="nature_of_id_#i#" class="data-entry-label">Nature of ID 	<span class="infoLink" onClick="getCtDoc('ctnature_of_id',newID.nature_of_id.value)">Define</span></label>
													<cfset thisID = #nature_of_id#>
													<select name="nature_of_id_#i#" id="nature_of_id_#i#" size="1" class="reqdClr data-entry-select">
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
													<input type="text" id="publication_#i#" value='#formatted_publication#' class="data-entry-input">
												</div>
											</div>
											<div class="row mt-2">
												<div class="col-12 col-md-6">
          											<label for="identification_remarks_#i#" class="data-entry-label">Remarks:</label>
													<input type="text" name="identification_remarks_#i#" id="identification_remarks_#i#"
														class="data-entry-input"
														value="#encodeForHtml(identification_remarks)#" >
												</div>
												<div class="col-12 col-md-2">
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
												<div class="col-12 col-md-4 mt-3">
													<cfif #accepted_id_fg# is 0>
           											<label for="storedas_#i#" class="d-inline-block mt-1">Stored As</label>
														<input type="checkbox" class="data-entry-checkbox" 
															name="storedas_#i#" id="storedas_#i#" value = "1" <cfif #stored_as_fg# EQ 1>checked</cfif> />
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
										<cfif #i# gt 1><hr class="border border-dark"></cfif>

								</cfloop>
								<div class="col-12 mt-2">
								<input type="submit" class="savBtn btn btn-xs btn-primary" id="editIdentification_submit" value="Save Changes" title="Save Changes">
							</div>
							</div>										
						</div>
						</div>
					</form>
						</div>
					</div>
				</div>
			<cfcatch>
				<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
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

	<cfthread action="join" name="getEditIdentsThread" />
	<cfreturn getEditIdentsThread.output>
</cffunction>


<!----------------------------------------------------------------------------------------------------------------->
<!--- function getIdentificationHtml obtain an html block to popluate an edit dialog for an identification 
 @param identification-id the identification.identification_id to edit.
 @return html for editing the identification 
--->
<cffunction name="getIdentificationHTML" returntype="string" access="remote" returnformat="plain">
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
											<input type="text" name="taxona" id="taxona" class="reqdClr form-control form-control-sm" value="#scientific_name#" size="1" 
												onChange="taxaPick('taxona_id','taxona','newID',this.value); return false;"
												onKeyPress="return noenter(event);">
											<input type="hidden" name="taxona_id" id=taxona_id" class="reqdClr">
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
											<input type="text" class="form-control-sm" id="determinedby" value="#agent_name#">
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
											<input type="text" class="form-control-sm" id="full_taxon_name" value="#full_taxon_name#">
										</div>
										<div class="form-group">
											<label for="identification_remarks">Identification Remarks:</label>
											<textarea type="text" class="form-control" id="identification_remarks" value="#identification_remarks#"></textarea>
										</div>
										<div class="form-check">
											<input type="checkbox" class="form-check-input" id="materialUnchecked">
											<label class="mt-2 form-check-label" for="materialUnchecked">Stored as #scientific_name#</label>
										</div>
										<div class="form-group float-right">
											<button type="button" value="Create New Identification" class="btn btn-primary ml-2"
												 onClick="$('.dialog').dialog('open'); loadNewIdentificationForm(identification_id,'newIdentificationForm');">Create New Identification</button>
										</div>
									</div>
								</div>
							</form>
						</div>
			 		</cfloop> <!--- theResult --->
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

<!----------------------------------------------------------------------------------------------------------------->
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

<cffunction name="loadLocality" returntype="query" access="remote">
	<cfargument name="locality_id" type="string" required="yes">
	<cftry>
		<cfquery name="theResults" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		   select 1 as status, locality_id, geog_auth_rec_id, spec_locality
             from locality
             where locality_id  =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
		</cfquery>
		<cfif theResults.recordcount eq 0>
	  	  <cfset theResults=queryNew("status, message")>
		  <cfset t = queryaddrow(theResults,1)>
		  <cfset t = QuerySetCell(theResults, "status", "0", 1)>
		  <cfset t = QuerySetCell(theResults, "message", "No localities found.", 1)>
		</cfif>
	  <cfcatch>
	   	<cfset theResults=queryNew("status, message")>
		<cfset t = queryaddrow(theResults,1)>
		<cfset t = QuerySetCell(theResults, "status", "-1", 1)>
		<cfset t = QuerySetCell(theResults, "message", "#cfcatch.type# hi #cfcatch.message# #cfcatch.detail#", 1)>
	  </cfcatch>
	</cftry>
	<cfreturn theResults>
</cffunction>
			
<cffunction name="getLocalityHTML" returntype="string" access="remote" returnformat="plain">
   <cfargument name="locality_id" type="string" required="yes">
   <cfset r=1>
   <cfthread name="getLocalityThread">
   <cftry>
    <cfquery name="theResults" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select 1 as status, locality.spec_locality, locality.geog_auth_rec_id, collecting_event.collecting_event_id, collecting_event.verbatim_locality, collecting_event.began_date, collecting_event.ended_date, collecting_event.collecting_source 
		from locality, collecting_event, geog_auth_rec 
		where locality.geog_auth_rec_id= geog_auth_rec.geog_auth_rec_id
		and collecting_event.locality_id = locality.locality_id
		and locality.locality_id = <cfqueryparam value="#locality_id#" cfsqltype="CF_SQL_DECIMAL">
	</cfquery>

      <cfset resulthtml1 = "<div id='localityHTML'> ">

      <cfloop query="theResults">
         <cfset resulthtml1 = resulthtml1 & "<div class='localityExistingForm'>">
            <cfset resulthtml1 = resulthtml1 & "<form><div class='container pl-1'>">
			<cfset resulthtml1 = resulthtml1 & "<div class='col-md-6 col-sm-12 float-left'>">
			<cfset resulthtml1 = resulthtml1 & "<div class='form-group'><label for='spec_locality' class='data-entry-label mb-0'>Specific Locality</label>">
			<cfset resulthtml1 = resulthtml1 & "<input name='spec_locality' class='data-entry-input' value='#spec_locality#'></div>">
			<cfset resulthtml1 = resulthtml1 & "<div class='form-row form-group'><label for='verbatim_locality' class='data-entry-label mb-0'>Verbatim Locality</label>">
			<cfset resulthtml1 = resulthtml1 & "<input name='verbatim_locality' class='data-entry-input' value='#verbatim_locality#'></div></div>">
			<cfset resulthtml1 = resulthtml1 & "<div class='col-md-6 col-sm-12 float-left'><label for='collecting_source' class='data-entry-label mb-0'>Collecting Source</label>">
			<cfset resulthtml1 = resulthtml1 & "<input name='collecting_source' class='data-entry-input' value='#collecting_source#'>">
			<cfset resulthtml1 = resulthtml1 & "<label for='began_date' class='data-entry-label mb-0'>Began Date</label>">
			<cfset resulthtml1 = resulthtml1 & "<input name='began_date' class='data-entry-input' value='#began_date#'>">
			<cfset resulthtml1 = resulthtml1 & "<label for='ended_date' class='data-entry-label mb-0'>End Date</label>">
			<cfset resulthtml1 = resulthtml1 & "<input name='ended_date' class='data-entry-input' value='#ended_date#'></div>">
		
			<cfset resulthtml1 = resulthtml1 & "</div></div></form>">
       
				<cfset resulthtml1 = resulthtml1 & "</div></div>"> 
      </cfloop> <!--- theResult --->

   <cfcatch>
       <cfset resulthtml1 = resulthtml1 & "Error:" & "#cfcatch.type# #cfcatch.message# #cfcatch.detail#">
   </cfcatch>
   </cftry>
     <cfoutput>#resulthtml1#</cfoutput>
   </cfthread>
    <cfthread action="join" name="getLocalityThread" />
    <cfreturn getLocalityThread.output>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getPartName" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>

   <cftry>
      <cfset rows = 0>
      <cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			select a.part_name
			from (
				select part_name, partname
				from ctspecimen_part_name, ctspecimen_part_list_order
				where ctspecimen_part_name.part_name =  ctspecimen_part_list_order.partname (+)
					and upper(part_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(term)#%">
				) a
			group by a.part_name, a.partname
			order by a.partname asc, a.part_name
      </cfquery>
   <cfset rows = search_result.recordcount>
      <cfset i = 1>
      <cfloop query="search">
         <cfset row = StructNew()>
         <cfset row["id"] = "#search.part_name#">
         <cfset row["value"] = "#search.part_name#" >
         <cfset data[i]  = row>
         <cfset i = i + 1>
      </cfloop>
      <cfreturn #serializeJSON(data)#>
   <cfcatch>
      <cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
      <cfset message = trim("Error processing getAgentPartName: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
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
	<cfreturn #serializeJSON(data)#>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getMediaForPublication" returntype="string" access="remote" returnformat="plain">
	<cfargument name="publication_id" type="string" required="yes">
	<cfthread name="getMediaForCitPub">
		<cfquery name="query"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
		<cfoutput>
		<div class='Media1'>
				<span class="pb-2">
					<cfloop query="query">
						<cfquery name="mediaQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select media.media_id, media_uri, preview_uri, media_type, mczbase.get_media_descriptor(media.media_id) as media_descriptor
							from media_relations left join media on media_relations.media_id = media.media_id
							where media_relations.media_relationship = '%publication'
								and media_relations.related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value=#publication_id#>
						</cfquery>
						<cfset mediaLink = "&##8855;">
						<cfloop query="mediaQuery">
							<cfset puri=getMediaPreview(preview_uri,media_type) >
							<cfif puri EQ "/images/noThumb.jpg">
								<cfset altText = "Red X in a red square, with text, no preview image available">
							<cfelse>
								<cfset altText = mediaQuery.media_descriptor>
							</cfif>
							<cfset mediaLink = "<a href='#media_uri#'target='_blank' rel='noopener noreferrer'><img src='#puri#' height='15' alt='#altText#'></a>" >
						</cfloop>
						<ul class='list-style-disc pl-4 pr-0'>
							<li class="my-1">
								#formatted_publication# 
								
							</li>
						</ul>
					</cfloop>
					<cfif query.recordcount eq 0>
				 		None
					</cfif>
				</span>
			</div> <!---  --->
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getMediaForCitPub" />
	<cfreturn getMediaForCitPub.output>
</cffunction>

</cfcomponent>
