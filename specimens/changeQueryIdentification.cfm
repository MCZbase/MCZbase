<!--- 
  specimens/changeQueryIdentification.cfm manage specimens by adding 
  new current identification to multiple specimens.

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
<cfset pageTitle = "Manage: Add new current identification">
<cfinclude template="/shared/_header.cfm">

<script type='text/javascript' src='/specimens/js/identification.js'></script>

<cfif isDefined("result_id") and len(result_id) GT 0>
	<cfset mode="result_id">
<cfelseif isDefined("collection_object_id") and len(collection_object_id) GT 0>
	<cfset mode="collection_object_id">
<cfelse>
	<cfthrow message="No specimens identified (by either collection_object_id or result_id) to add identifications to.">
</cfif>


<main class="container-fluid" id="content">
	<!----------------------------------------------------------------------------------->
	<cfif isDefined("action") AND #action# is "createManyNew">
		<cfoutput>
			<cfif taxa_formula is "A {string}">
				<!--- unused special case handling --->
				<cfset scientific_name = user_identification>
			<cfelseif taxa_formula is "A">
				<cfset scientific_name = taxona>
			<cfelseif Find("B",taxa_formula) GT 0>
				<cfif Find("A",taxa_formula) LT Find("B",taxa_formula)>
					<cfset scientific_name = Replace(taxa_formula,"B",taxonb, "one")>
					<cfset scientific_name = Replace(scientific_name,"A",taxona,"one")>
				<cfelse>
					<cfthrow message="The taxa formula you entered isn&apos;t handled yet! Please submit a bug report.">
				</cfif>
			<cfelse>
				<cfset scientific_name = Replace(taxa_formula,"A",taxona, "one")>
			</cfif>
			<cfset success=false>
			<cfset errorMessage ="">
			<!--- loop through the collection_object_list and update things one at a time--->
			<cftransaction>
				<cftry>
					<cfquery name="specimenList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT
							collection_object_id
						FROM
							cataloged_item 
						WHERE
							<cfif mode EQ "result_id">
								 cataloged_item.collection_object_id IN (
									SELECT collection_object_id 
									FROM user_search_table 
									WHERE
										result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
									)
							<cfelse>
								cataloged_item.collection_object_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#" list="yes">)
							</cfif>
					</cfquery>
					<cfloop query="specimenList">
						<cfquery name="upOldID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							UPDATE identification 
							SET ACCEPTED_ID_FG=0 
							WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#specimenList.collection_object_id#">
						</cfquery>
						<cfquery name="newID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							INSERT INTO identification (
								IDENTIFICATION_ID,
								COLLECTION_OBJECT_ID
								<cfif len(MADE_DATE) gt 0>
									,MADE_DATE
								</cfif>
								,NATURE_OF_ID
								 ,ACCEPTED_ID_FG
								 <cfif len(#IDENTIFICATION_REMARKS#) gt 0>
									,IDENTIFICATION_REMARKS
								</cfif>
								,taxa_formula
								,scientific_name
								<cfif isDefined("publication_id") and len(publication_id) GT 0>
									,publication_id
								</cfif>
							) VALUES (
								sq_identification_id.nextval,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#specimenList.collection_object_id#">
								<cfif len(#MADE_DATE#) gt 0>
									,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#MADE_DATE#">
								</cfif>
								,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#NATURE_OF_ID#">
								,1
								<cfif len(#IDENTIFICATION_REMARKS#) gt 0>
									,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#IDENTIFICATION_REMARKS#">
								</cfif>
								,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#taxa_formula#">
								,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#scientific_name#">
								<cfif isDefined("publication_id") and len(publication_id) GT 0>
									,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
								</cfif>
							)
						</cfquery>
						<cfquery name="newIdAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							insert into identification_agent (
								identification_id,
								agent_id,
								identifier_order)
							values (
								sq_identification_id.currval,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#newIdById#">,
								1
								)
						</cfquery>
						<cfif len(#newIdById_two#) gt 0>
							<cfquery name="newIdAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								insert into identification_agent (
									identification_id,
									agent_id,
									identifier_order)
								values (
									sq_identification_id.currval,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#newIdById_two#">,
									2
									)
							</cfquery>
						</cfif>
						<cfif len(#newIdById_three#) gt 0>
							<cfquery name="newIdAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								insert into identification_agent (
									identification_id,
									agent_id,
									identifier_order)
								values (
									sq_identification_id.currval,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#newIdById_three#">,
									3
									)
							</cfquery>
						</cfif>
						<cfquery name="newId2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							INSERT INTO identification_taxonomy (
								identification_id,
								taxon_name_id,
								variable)
							VALUES (
								sq_identification_id.currval,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxona_id#">,
								'A')
						</cfquery>
						<cfif #taxa_formula# contains "B">
							<cfquery name="newId3" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								INSERT INTO identification_taxonomy (
									identification_id,
									taxon_name_id,
									variable)
								VALUES (
									sq_identification_id.currval,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxonb_id#">,
									'B')
							</cfquery>
						</cfif>
					</cfloop>
					<cftransaction action="commit">
					<cfset success=true>
				<cfcatch>
					<cftransaction action="rollback">
					<cfset errorMessage = "#cfcatch.message#">
					<cfif isDefined("cfcatch.queryError") >
						<cfset errorMessage = "#errorMessage#: #cfcatch.queryError#">
					</cfif>
					<cfif isDefined("cfcatch.cause")>
						<cfif isDefined("cfcatch.cause.message")>
							<cfset errorMessage = "#errorMessage# #cfcatch.cause.message#">
						</cfif>
						<cfif isDefined("cfcatch.cause.tagcontext")>
							<cftry>
								<cfset errorMessage = "#errorMessage# Line:#cfcatch.cause.tagcontext[1].line#">
							<cfcatch>
							</cfcatch>
							</cftry>
						</cfif>
					</cfif>
				</cfcatch>
				</cftry>
			</cftransaction>
			<section class="row mx-0" aria-labelledby="resultHead">
				<div class="col-12 pt-4">	
					<cfif success>
						<h2 class="h2" id="resultHead">Added new current identification to these specimens.</h2> 
					<cfelse>
						<h2 class="h2" id="resultHead">Error: Unable to add identification to these specimens.</h2> 
						<div>#errorMessage#</div>
					</cfif>
				</div>
			</section>
		</cfoutput>
	</cfif>
	<!--------------------------------------------------------------------------------------------------->
	<section class="row" aria-labelledby="formHead">
		<cfquery name="ctnature" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT nature_of_id 
			FROM ctnature_of_id
		</cfquery>
		<cfquery name="ctFormula" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT taxa_formula 
			FROM cttaxa_formula 
			ORDER BY taxa_formula
		</cfquery>
		<cfoutput> 
			<div class="col-12 px-3 px-xl-4 pt-4">
				<h1 class="h2" id="formHead">Add a new Current Identification to <strong>All</strong> specimens listed below:</h1>
				<form name="newID" method="post" action="/specimens/changeQueryIdentification.cfm">
					<input type="hidden" name="Action" value="createManyNew">
					<cfif mode EQ "result_id">
						<input type="hidden" name="result_id" value="#result_id#" >
					<cfelse>
						<input type="hidden" name="collection_object_id" value="#collection_object_id#" >
					</cfif>
					<div class="form-row mb-2">
						<div class="col-12 col-md-2">
							<label for="taxa_formula" class="data-entry-label">
								ID Formula: 
								<a href="/vocabularies/ControlledVocabulary.cfm?table=CTTAXA_FORMULA" target="_blank"><i class="fas fa-info-circle" aria-label="help link to controlled vocabulariy for taxon formula"></i></a>
							</label>
							<cfif not isdefined("taxa_formula")>
								<cfset taxa_formula='A'>
							</cfif>
							<cfset thisForm = "#taxa_formula#">
							<select name="taxa_formula" id="taxa_formula" size="1" class="data-entry-select reqdClr" onchange="newIdFormula(this.value);">
								<cfloop query="ctFormula">
									<option <cfif #thisForm# is "#ctFormula.taxa_formula#"> selected </cfif>value="#ctFormula.taxa_formula#">#taxa_formula#</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12 col-md-5">
							<label class="data-entry-label" for="taxona">Taxon A: </label>
							<input type="text" name="taxona" id="taxona" class="data-entry-input reqdClr" required>
							<input type="hidden" name="taxona_id" id="taxona_id">
						</div>
						<script>
							$(document).ready(function() { 
								makeScientificNameAutocompleteMeta("taxona","taxona_id");
							});
						</script>
						<div class="col-12 col-md-5" id="taxon_b_row">
							<label class="data-entry-label" for="taxonb">Taxon B: </label>
							<input type="text" name="taxonb" id="taxonb" class="data-entry-input" disabled >
							<input type="hidden" name="taxonb_id" id="taxonb_id">
						</div>
						<script>
							$(document).ready(function() { 
								makeScientificNameAutocompleteMeta("taxonb","taxonb_id");
							});
						</script>
						<div class="col-12" id="userID" style="display:none;">
							<!--- unused feature A {string} pattern --->
							<label class="data-entry-label" for="user_identification">Custom Identification: </label>
							<input type="text" name="user_identification" id="user_identification" class="data-entry-input">
						</div>
						<div class="col-12 form-row" id="determiners">
							<div class="col-12 col-md-3">
								<label for="idBy" class="data-entry-label">Identified By:</label>
								<input type="text" name="idBy" id="idBy" class="data-entry-input reqdClr" required>
								<input type="hidden" name="newIdById" id="newIdById">
							</div>
							<div class="col-12 col-md-1">
								<span class="btn btn-xs btn-secondary mt-3" onclick="addNewIdBy('two');">more...</span>
							</div>
							<script>
								$(document).ready(function() { 
									makeAgentAutocompleteMeta("idBy", "newIdById");
								});
							</script>
							<div class="col-12 col-md-3 determiner_block_two"  id="addNewIdBy_two" style="display:none;">
								<label for="idBy_two" class="data-entry-label">
									ID By:
									<span class="infoLink" onclick="clearNewIdBy('two');"> clear</span>
								</label>
								<input type="text" name="idBy_two" id="idBy_two" class="data-entry-input reqdClr">
								<input type="hidden" name="newIdById_two" id="newIdById_two">
							</div>
							<div class="col-12 col-md-1 determiner_block_two" style="display:none;">
								<span class="btn btn-xs btn-secondary mt-3" onclick="addNewIdBy('three');">more...</span>
							</div>
							<script>
								$(document).ready(function() { 
									makeAgentAutocompleteMeta("idBy_two","newIdById_two");
								});
							</script>
							<div class="col-12 col-md-4 determiner_block_three" id="addNewIdBy_three" style="display:none;">
								<label for="idBy_three" class="data-entry-label">
										ID By:
										<span class="infoLink" onclick="clearNewIdBy('three');"> clear</span>
								</label>
								<input type="text" name="idBy_three" id="idBy_three" class="data-entry-input reqdClr">
								<input type="hidden" name="newIdById_three" id="newIdById_three">
							</div>
							<script>
								$(document).ready(function() { 
									makeAgentAutocompleteMeta("idBy_three","newIdById_three");
								});
							</script>
						</div>
						<div class="col-12 col-md-4">
							<label for="made_date" class="data-entry-label">Date Identified</label>
							<input type="text" name="made_date" id="made_date" class="data-entry-input">
							<script>
								$(document).ready(function() { 
									$("##made_date").datepicker({ dateFormat: 'yy-mm-dd'});
								});
							</script>
						</div>
						<div class="col-12 col-md-4">
							<label for="nature_of_id" class="data-entry-label">
								Nature of ID: 
								<a href="/vocabularies/ControlledVocabulary.cfm?table=CTNATURE_OF_ID" target="_blank"><i class="fas fa-info-circle" aria-label="help link to controlled vocabulary for nature of id"></i></a>
							</label>
							<select name="nature_of_id" id="nature_of_id" class="data-entry-select reqdClr" required>
								<option value=""></option>
								<cfloop query="ctnature">
									<option value="#ctnature.nature_of_id#">#ctnature.nature_of_id#</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12 col-md-4">
							<!--- buisness logic in TR_STORED_AS_FG prevents current identification from being stored as --->
							<label for="stored_as_fg" class="data-entry-label">Stored As Name: </label>
							<select name="stored_as_fg" id="stored_as_fg" class="data-entry-select" disabled>
								<option value="" selected>Current Id cannot be marked &apos;Stored As&apos;</option>
							</select>
						</div>
						<div class="col-12">
							<label for="publication" class="data-entry-label">Sensu</label>
							<input type="text" name="publication" id="publication" class="data-entry-input">
							<input type="hidden" name="publication_id" id="publication_id" class="data-entry-input">
							<script>
								$(document).ready(function() { 
									makePublicationAutocompleteMeta('publication', 'publication_id');
								});
							</script>
						</div>
						<div class="col-12">
							<label for="identification_remarks" class="data-entry-label">
								Remarks:
								(<span id="length_identification_remarks"></span>)
							</label>
							<textarea name="identification_remarks" id="identification_remarks" rows="2" 
								onkeyup="countCharsLeft('identification_remarks', 4000, 'length_identification_remarks');"
								class="data-entry-textarea autogrow mb-1" 
								></textarea>
						</div>
						<script>
							// make selected textareas autogrow as text is entered.
							$(document).ready(function() {
								// bind the autogrow function to the keyup event
								$('textarea.autogrow').keyup(autogrow);
								// trigger keyup event to size textareas to existing text
								$('textarea.autogrow').keyup();
							});
						</script> 
						<div class="col-12">
							<input type="submit" value="Add Identification to all listed specimens" class="btn btn-xs mt-2 btn-primary">
						</div>
					</div>
				</form>
			</div>
	
			<cfquery name="specimenList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				 SELECT
				 	cataloged_item.collection_object_id as collection_object_id,
					cat_num,
					concatSingleOtherId(cataloged_item.collection_object_id,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.CustomOtherIdentifier#">) AS CustomID,
					concattypestatus(cataloged_item.collection_object_id) as type_status,
					scientific_name,
					country,
					state_prov,
					county,
					spec_locality,
					institution_acronym,
					collection.collection,
					collection.collection_cde,
					identification.nature_of_id,
					concatIdAgent(identification.identification_id) as determiners,
					identification.made_date
				FROM
					identification,
					collecting_event,
					locality,
					geog_auth_rec,
					cataloged_item,
					collection
				WHERE
					locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
					AND collecting_event.locality_id = locality.locality_id
					AND cataloged_item.collecting_event_id = collecting_event.collecting_event_id
					AND cataloged_item.collection_object_id = identification.collection_object_id
					and accepted_id_fg=1
					AND cataloged_item.collection_id = collection.collection_id
					<cfif mode EQ "result_id">
						AND cataloged_item.collection_object_id IN (
							SELECT collection_object_id 
							FROM user_search_table 
							WHERE
								result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
							)
					<cfelse>
						AND cataloged_item.collection_object_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#" list="yes">)
					</cfif>
				ORDER BY
					collection_object_id
			</cfquery>
			<cfif specimenList.recordcount EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
				<div class="col-12 px-3 px-xl-4">
					<h2 class="mt-2">#specimenList.recordcount# Specimen#plural# to be Re-Identified:</h2>
					<table class="table table-responsive table-striped d-md-table">
						<thead class="thead-light">
							<tr>
								<th><strong>Catalog Number</strong></th>
								<th><strong><cfoutput>#session.CustomOtherIdentifier#</cfoutput></strong></th>
								<th><strong>Current Identification</strong></th>
								<th><strong>Made By</strong></th>
								<th><strong>Made Date</strong></th>
								<th><strong>Country</strong></th>
								<th><strong>State</strong></th>
								<th><strong>County</strong></th>
								<th><strong>Locality</strong></th>
								<th><strong>Type Status</strong></th>
							</tr>
						</thead>
					<cfloop query="specimenList">
						<tbody>
							<tr>
								<td><a href="/guid/MCZ:#collection_cde#:#cat_num#" target="_blank">MCZ:#collection_cde#:#cat_num#</a></td>
								<td>#CustomID#</td>
								<td><i>#Scientific_Name#</i></td>
								<td>#determiners#</td>
								<td>#made_date# (#nature_of_id#)</td>
								<td>#Country#</td>
								<td>#State_Prov#</td>
								<td>#county#</td>
								<td>#spec_locality#</td>
								<td>#type_status#</td>
							</tr>
						</tbody>
					</cfloop>
			</table>
				</div>
			</div>
		</cfoutput>
	</section>
</main>
<cfinclude template="/shared/_footer.cfm">
