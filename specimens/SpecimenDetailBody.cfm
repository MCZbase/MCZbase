<!---
SpecimenDetailBody.cfm

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

<!---  TODO: Header hasn't been shown, handle approprately, probably with a redirect to SpecimenDetails.cfm --->
<!---<cfif not isdefined("HEADER_DELIVERED")>
</cfif>--->
<cfoutput>
	<cfif not isdefined("collection_object_id") or not isnumeric(collection_object_id)>
		<div class="error"> Improper call. Aborting..... </div>
		<cfabort>
	</cfif>
	<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
		<cfset oneOfUs = 1>
		<cfset isClicky = "likeLink">
		<cfelse>
		<cfset oneOfUs = 0>
		<cfset isClicky = "">
	</cfif>
	<cfif oneOfUs is 0 and cgi.CF_TEMPLATE_PATH contains "/specimens/SpecimenDetailBody.cfm">
		<!--- TODO: Fix this redirect, this is probably the header delivered block above.  ----> 
		<!---<cfheader statuscode="301" statustext="Moved permanently">
	<cfheader name="Location" value="/Specimens.cfm?collection_object_id=#collection_object_id#">--->
	</cfif>
</cfoutput> 
<!--- Include the template that contains functions used to load portions of this page --->
<cfinclude template="/specimens/component/public.cfc">
<!--- query one is needed for the counts on media and part headers and metadata block--->
<cfquery name="one" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT
		cataloged_item.collection_object_id as collection_object_id,
		cataloged_item.cat_num,
		collection.collection_cde,
		coll_object.coll_object_entered_date,
		coll_object.last_edit_date,
		coll_object.flags,
		coll_object_remark.coll_object_remarks,
		enteredPerson.agent_name EnteredBy,
		editedPerson.agent_name EditedBy,
		concatencumbrances(cataloged_item.collection_object_id) concatenatedEncumbrances,
		concatEncumbranceDetails(cataloged_item.collection_object_id) encumbranceDetail
	FROM
		cataloged_item,
		collection,
		identification,
		collecting_event,
		coll_object,
		coll_object_remark,
		specimen_part,
		preferred_agent_name enteredPerson,
		preferred_agent_name editedPerson
	WHERE
		cataloged_item.collection_id = collection.collection_id AND
		cataloged_item.collection_object_id = identification.collection_object_id AND
		cataloged_item.collecting_event_id = collecting_event.collecting_event_id AND
		cataloged_item.collection_object_id = coll_object.collection_object_id AND
		coll_object.collection_object_id = coll_object_remark.collection_object_id AND
		coll_object.entered_person_id = enteredPerson.agent_id AND
		coll_object.last_edited_person_id = editedPerson.agent_id (+) AND
		cataloged_item.collection_object_id = specimen_part.derived_from_cat_item AND
		cataloged_item.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
</cfquery>
	
		<cfset guid = "MCZ:#one.collection_cde#:#one.cat_num#">
			<cfquery name="ctmedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select count(*) as ct 
				from 
					media_relations
				where 
					media_relations.related_primary_key = <cfqueryparam value=#collection_object_id# CFSQLType="CF_SQL_DECIMAL" >
			</cfquery>
			<cfquery name="rparts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select
					specimen_part.collection_object_id part_id
				from
					specimen_part
				where
					specimen_part.derived_from_cat_item = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#one.collection_object_id#">
			</cfquery>

			<cfset ctPart.ct=''>
			<cfquery name="ctPart" dbtype="query">
				select count(*) as ct from rparts
			</cfquery>
<cfoutput>
	<cfif ctmedia.recordcount gt 0>
		<div class="col-12 col-sm-12 col-md-3 col-lg-3 col-xl-2 px-1 mb-2 float-left">
<!-----------------------------Media----------------------------------> 
				<div class="accordion" id="accordionMedia">
					<div class="card mb-2 bg-light">
						<div id="mediaDialog">
						</div>
						<script>
							function reloadMedia() { 
								// invoke specimen/component/public.cfc function getIdentificationHTML via ajax and repopulate the identification block.
								loadMedia(#collection_object_id#,'mediaCardBody');
							}
						</script>
						<div class="card-header" id="headingMedia">
							<h3 class="h4 my-0 float-left collapsed btn-link">
								<a href="##" role="button" data-toggle="collapse" data-target="##mediaPane">Media</a>
								<span class="text-success small ml-2">(count: #ctmedia.ct# media records)</span>
							</h3>
							<cfif listcontainsnocase(session.roles,"manage_media")>
								<button type="button" class="btn btn-xs small py-0 float-right" onClick="openEditMediaDialog(#collection_object_id#,'mediaDialog','#guid#',reloadMedia)">Edit</button>
							</cfif>
						</div>
						<div id="mediaPane" class="collapse show" aria-labelledby="headingMedia" data-parent="##accordionMedia">
							<div class="card-body py-2 mb-0 float-left" id="mediaCardBody">
								<cfset block = getMediaHTML(collection_object_id = "#collection_object_id#")>
								#block#
							</div>
						</div>
					</div>
				</div>
		</div>
	</cfif>
<!----------------------------- two right columns ---------------------------------->
		<div class="col-12 col-sm-12 mb-2 px-0 <cfif ctmedia.recordcount gt 0>col-md-9 col-lg-9 col-xl-10<cfelse>col-md-12 col-lg-12 col-xl-12</cfif> float-left">
			<div class="col-12 col-md-6 px-1 float-left"> 

<!----------------------------- identifications ----------------------------------> 
				<div class="accordion" id="accordionB">
					<div class="card mb-2 bg-light">
						<div id="identificationsDialog">
						</div>
						<script>
							function reloadIdentifications() { 
								// invoke specimen/component/public.cfc function getIdentificationHTML via ajax and repopulate the identification block.
								loadIdentifications(#collection_object_id#,'identificationsCardBody');
							}
						</script>
								<cfset blockident = getIdentificationsHTML(collection_object_id = "#collection_object_id#")>
						<div class="card-header" id="heading1">
							<cfif len(#blockident#) gt 10> 
							<h3 class="h4 my-0 float-left collapsed btn-link">
								<a href="##" role="button" data-toggle="collapse" data-target="##identificationsPane">Identifications</a>
							</h3>
							<cfif listcontainsnocase(session.roles,"manage_specimens")>
								<button type="button" id="btn_pane" class="btn btn-xs small py-0 float-right" onClick="openEditIdentificationsDialog(#collection_object_id#,'identificationsDialog','#guid#',reloadIdentifications)">Edit</button>
							</cfif>
							<cfelse>
								<h3 class="h4 my-0 float-left collapsed btn-link">
								Identifications
							</h3>
							<cfif listcontainsnocase(session.roles,"manage_specimens")>
								<button type="button" id="btn_pane" class="btn btn-xs small py-0 float-right" onClick="openEditIdentificationsDialog(#collection_object_id#,'identificationsDialog','#guid#',reloadIdentifications)">Add</button>
							</cfif>
							</cfif>
						</div>
						<div id="identificationsPane" class="collapse show" aria-labelledby="heading1" data-parent="##accordionB">
							<div class="card-body py-2 mb-0 float-left" id="identificationsCardBody">
								#blockident#
									<div id="identificationHTML"></div>
							</div>
						</div>
					</div>
				</div>
<!----------------------------- Citations new ----------------------------------> 
			
				<div class="accordion" id="accordionCitations">
					<div class="card mb-2 bg-light">
						<div id="citationsDialog"></div>
						<script>
							function reloadCitations() { 
								// invoke specimen/component/public.cfc function getIdentificationHTML via ajax and repopulate the identification block.
								loadCitations(#collection_object_id#,'citationsCardBody');
							}
						</script>
						<cfset blockcit = getCitationsHTML(collection_object_id = "#collection_object_id#")>
						<div class="card-header" id="headingCitations">
							<cfif len(#blockcit#) gt 10> 
							<h3 class="h4 my-0 float-left collapsed btn-link">
								<a href="##" role="button" data-toggle="collapse" data-target="##citationsPane">Citations</a>
							</h3>
								<cfif listcontainsnocase(session.roles,"manage_specimens")>
									<button type="button" id="addbtn" class="btn btn-xs small py-0 float-right" onClick="openEditCitationsDialog(#collection_object_id#,'citationsDialog','#guid#',reloadCitations)">Edit</button>
								</cfif>
							<cfelse>
							<h3 class="h4 my-0 float-left collapsed text-black">
								Citations
							</h3>
								<cfif listcontainsnocase(session.roles,"manage_specimens")>
									<button type="button" id="addbtn" class="btn btn-xs small py-0 float-right" onClick="openEditCitationsDialog(#collection_object_id#,'citationsDialog','#guid#',reloadCitations)">Add</button>
								</cfif>
							</cfif>
						</div>
						<div id="citationsPane" class="collapse show" aria-labelledby="headingCitations" data-parent="##accordionCitations">
							<div class="card-body py-2 mb-1 float-left" id="citationsCardBody">
								<cfif len(#blockcit#) gt 10>
									#blockcit#
								<cfelse>
									<ul class="pl-0 mb-0"><li>None</li></ul>
								</cfif>
							</div>
						</div>

					</div>
				</div>

<!------------------------------------ other identifiers ---------------------------------->
				<div class="accordion" id="accordionOtherID">
					<div class="card mb-2 bg-light">
						<div id="otherIDsDialog"></div>
						<script>
							function reloadOtherIDs() { 
								// invoke specimen/component/public.cfc function getOtherIDsHTML via ajax and repopulate the Other ID block.
								loadOtherIDs(#collection_object_id#,'otherIDsCardBody');
							}
						</script>
							<cfset blockotherid = getOtherIDsHTML(collection_object_id = "#collection_object_id#")>
						<div class="card-header" id="headingOtherID">
							<cfif len(#blockotherid#) gt 10> 
								<h3 class="h4 my-0 float-left collapsed btn-link">
									<a href="##" role="button" data-toggle="collapse" data-target="##OtherIDsPane">Other IDs</a>
								</h3>
								<cfif listcontainsnocase(session.roles,"manage_specimens")>
									<button type="button" class="btn btn-xs small py-0 float-right" onClick="openEditOtherIDsDialog(#collection_object_id#,'otherIDsDialog','#guid#',reloadOtherIDs)">Edit</button>
								</cfif>
							<cfelse>
								<h3 class="h4 my-0 float-left collapsed text-black">
								Other IDs
								</h3>
								<cfif listcontainsnocase(session.roles,"manage_specimens")>
									<button type="button" class="btn btn-xs small py-0 float-right" onClick="openEditOtherIDsDialog(#collection_object_id#,'otherIDsDialog','#guid#',reloadOtherIDs)">Add</button>
								</cfif>
							</cfif>
						</div>
						<div id="OtherIDsPane" class="collapse show" aria-labelledby="headingOtherID" data-parent="##accordionOtherID">
							<div class="card-body py-2 mb-2 float-left" id="otherIDsCardBody">
								#blockotherid#
							</div>
						</div>
					</div>
				</div>

<!------------------------------------ parts new ---------------------------------->
 
				<div class="accordion" id="accordionParts">
					<div class="card mb-2 bg-light">
						<div id="partsDialog"></div>
						<script>
							function reloadParts() { 
								// invoke specimen/component/public.cfc function getOtherIDsHTML via ajax and repopulate the Other ID block.
								loadParts(#collection_object_id#,'partsCardBody');
							}
						</script>
						
						<div class="card-header" id="headingParts">
					
							<h3 class="h4 my-0 float-left collapsed btn-link">
								<a href="##" role="button" data-toggle="collapse" data-target="##PartsPane">Parts</a>
								<span class="text-success small ml-2">(count: #ctPart.ct# parts)</span>
							</h3>
							<cfif listcontainsnocase(session.roles,"manage_specimens")>
								<button type="button" class="btn btn-xs small py-0 float-right" onClick="openEditPartsDialog(#collection_object_id#,'partsDialog','#guid#',reloadParts)">Edit</button>
							</cfif>
						</div>
						<div id="PartsPane" <cfif #ctPart.ct# gt 5>style="height:300px;"</cfif> class="collapse show" aria-labelledby="headingParts" data-parent="##accordionParts">
							<div class="card-body py-2 w-100 mb-1 float-left" id="partsCardBody">
								<cfset blockparts = getPartsHTML(collection_object_id = "#collection_object_id#")>
								#blockparts#
							</div>
						</div>
					</div>
				</div>
						
<!------------ attributes ----------------------------------------->
				<div class="accordion" id="accordionAttributes">
					<div class="card mb-2 bg-light">
						<div id="attributesDialog"></div>
						<script>
							function reloadAttributes() { 
								// invoke specimen/component/public.cfc function getAttributesHTML via ajax and repopulate the Other ID block.
								loadAttributes(#collection_object_id#,'attributesCardBody');
							}
						</script>
						<cfset blockattributes = getAttributesHTML(collection_object_id = "#collection_object_id#")>
						<div class="card-header" id="headingAttributes">
						<cfif len(#blockattributes#) gt 50> 
							<h3 class="h4 my-0 float-left collapsed btn-link">
								<a href="##" role="button" data-toggle="collapse" data-target="##AttributesPane">Attributes</a>
							</h3>
							<cfif listcontainsnocase(session.roles,"manage_specimens")>
								<button type="button" class="btn btn-xs small py-0 float-right" onClick="openEditAttributesDialog(#collection_object_id#,'attributesDialog','#guid#',reloadAttributes)">Edit</button>
							</cfif>
						<cfelse>
							<h3 class="h4 my-0 float-left collapsed">
								Attributes
							</h3>
							<cfif listcontainsnocase(session.roles,"manage_specimens")>
								<button type="button" class="btn btn-xs small py-0 float-right text-black" onClick="openEditAttributesDialog(#collection_object_id#,'attributesDialog','#guid#',reloadAttributes)">Add</button>
							</cfif>
						</cfif>
						</div>
						<div id="AttributesPane" class="collapse show" aria-labelledby="headingAttributes" data-parent="##accordionAttributes">
							<div class="card-body py-2 mb-1 float-left" id="attributesCardBody">
								<cfif len(#blockattributes#) gt 50>#blockattributes#<cfelse><ul class="pl-0 mb-0"><li>None</li></ul></cfif>
							</div>
						</div>
					</div>
				</div>

<!------------------------------------ relationships  ------------------------------------->

				<div class="accordion" id="accordionRelations">
					<div class="card mb-2 bg-light">
						<div id="relationsDialog"></div>
						<script>
							function reloadRelations() { 
								// invoke specimen/component/public.cfc function getRelationsHTML via ajax and repopulate the Other ID block.
								loadRelations(#collection_object_id#,'RelationsCardBody');
							}
						</script>
						<cfset blockrel = getRelationsHTML(collection_object_id = "#collection_object_id#")>
						<div class="card-header" id="headingRelations">
						<cfif len(#blockrel#) gt 60> 
							<h3 class="h4 my-0 float-left collapsed btn-link">
								<a href="##" role="button" data-toggle="collapse" data-target="##RelationsPane">Relationships</a>
							</h3>
							<cfif listcontainsnocase(session.roles,"manage_specimens")>
								<button type="button" class="btn btn-xs small py-0 float-right" onClick="openEditRelationsDialog(#collection_object_id#,'relationsDialog','#guid#',reloadRelations)">Edit</button>
							</cfif>
						<cfelse>
							<h3 class="h4 my-0 float-left collapsed text-black">
								Relationships
							</h3>
							<cfif listcontainsnocase(session.roles,"manage_specimens")>
								<button type="button" class="btn btn-xs small py-0 float-right" onClick="openEditRelationsDialog(#collection_object_id#,'relationsDialog','#guid#',reloadRelations)">Add</button>
							</cfif>
						</cfif>
						</div>
						<div id="RelationsPane" class="collapse show" aria-labelledby="headingRelations" data-parent="##accordionRelations">
							<div class="card-body py-2 mb-1 float-left" id="relationsCardBody">
									<cfif len(#blockrel#) gt 60> #blockrel# <cfelse><ul class="pl-0 mb-0"><li>None</li></ul></cfif>
							</div>
						</div>
					</div>
				</div>
			</div>
			<!---  start of column three  --->
			<div class="col-12 col-md-6 px-1 float-left"> 

				<!--- --------------------------------- locality and collecting event-------------------------------------- ---->
				<div class="accordion" id="accordionLocality">
					<div class="card mb-2 bg-light">
						<div id="localityDialog"></div>
						<script>
							function reloadLocality() { 
								loadLocality(#collection_object_id#,'localityCardBody');
							}
						</script>
						<cfset blocklocality = getLocalityHTML(collection_object_id = "#collection_object_id#")>
						<div class="card-header" id="headingLocality">
							<cfif len(#blocklocality#) gt 60>
							<h3 class="h4 my-0 float-left collapsed btn-link">
								<a href="##" role="button" data-toggle="collapse" data-target="##LocalityPane">Location and Collecting Event</a>
							</h3>
							<cfif listcontainsnocase(session.roles,"manage_specimens")>
								<button type="button" class="btn btn-xs small py-0 float-right" onClick="openEditLocalityDialog(#collection_object_id#,'localityDialog','#guid#',reloadLocality)">Edit</button>
							</cfif>
							<cfelse>
							<h3 class="h4 my-0 float-left collapsed">
								<a href="##" role="button" data-toggle="collapse" data-target="##LocalityPane">Location and Collecting Event</a>
							</h3>
							<cfif listcontainsnocase(session.roles,"manage_specimens")>
								<button type="button" class="btn btn-xs small py-0 float-right text-black" onClick="openEditLocalityDialog(#collection_object_id#,'localityDialog','#guid#',reloadLocality)">Add</button>
							</cfif>
						</cfif>
						</div>
						<div id="LocalityPane" class="collapse show" aria-labelledby="headingLocality" data-parent="##accordionLocality">
							<div class="card-body px-0 py-2 mb-1 float-left" id="localityCardBody">
								<cfif len(#blocklocality#) gt 60> #blocklocality# <cfelse><ul class="pl-0 mb-0"><li>None</li></ul></cfif>
							</div>
						</div>
					</div>
				</div> 
				
				<!--- --------------------------------- Collectors and Preparators ----------------------------- --->
				
				<div class="accordion" id="accordionCollectors">
					<div class="card mb-2 bg-light">
						<div id="collectorsDialog"></div>
						<script>
							function reloadCollectors() { 
								// invoke specimen/component/public.cfc function getCollectorsHTML via ajax and repopulate the Other ID block.
								loadCollectors(#collection_object_id#,'collectorsCardBody');
							}
						</script>
						<cfset blockcollectors = getCollectorsHTML(collection_object_id = "#collection_object_id#")>
						<cfif len(#blockcollectors#) gt 5>
						<div class="card-header" id="headingCollectors">
								<h3 class="h4 my-0 float-left collapsed btn-link">
									<a href="##" role="button" data-toggle="collapse" data-target="##CollectorsPane">Collectors and Preparators</a>
								</h3>
								<cfif listcontainsnocase(session.roles,"manage_specimens")>
									<button type="button" class="btn btn-xs small py-0 float-right" onClick="openEditCollectorsDialog(#collection_object_id#,'collectorsDialog','#guid#',reloadCollectors)">Edit</button>
								</cfif>
							<cfelse>
								<h3 class="h4 my-0 float-left collapsed text-black">
									<a href="##" role="button" data-toggle="collapse" data-target="##CollectorsPane">Collectors and Preparators</a>
								</h3>
								<cfif listcontainsnocase(session.roles,"manage_specimens")>
									<button type="button" class="btn btn-xs small py-0 float-right" onClick="openEditCollectorsDialog(#collection_object_id#,'collectorsDialog','#guid#',reloadCollectors)">Add</button>
								</cfif>
							</cfif>
						</div>
						<div id="CollectorsPane" class="collapse show" aria-labelledby="headingCollectors" data-parent="##accordionCollectors">
							<div class="card-body py-2 mb-1 float-left" id="collectorsCardBody">
								<cfif len(#blockcollectors#) gt 60> #blockcollectors# <cfelse><ul class="pl-0 mb-0"><li>None</li></ul></cfif>
							</div>
						</div>
					</div>
				</div>

				<!--- ---------------------------------- tranactions  ----------------------------------- --->
					
				<div class="accordion" id="accordionTransactions">
					<div class="card mb-2 bg-light">
						<div id="transactionsDialog"></div>
						<script>
							function reloadTransactions() { 
								// invoke specimen/component/public.cfc function getCollectorsHTML via ajax and repopulate the Other ID block.
								loadTransactions(#collection_object_id#,'transactionsCardBody');
							}
						</script>
						<div class="card-header" id="headingTransactions">
							<h3 class="h4 my-0 float-left collapsed btn-link">
								<a href="##" role="button" data-toggle="collapse" data-target="##TransactionsPane">Transactions</a>
							</h3>
							<cfif listcontainsnocase(session.roles,"manage_specimens")>
								<button type="button" class="btn btn-xs small py-0 float-right" onClick="openEditTransactionsDialog(#collection_object_id#,'transactionsDialog','#guid#',reloadTransactions)">Edit</button>
							</cfif>
						</div>
						<div id="TransactionsPane" class="collapse show" aria-labelledby="headingTransactions" data-parent="##accordionTransactions">
							<div class="card-body py-2 mb-2 float-left" id="transactionsCardBody">
								<cfset block = getTransactionsHTML(collection_object_id = "#collection_object_id#")>
								#block#
							</div>
						</div>
					</div>
				</div>
				<cfif oneofus is 1 or not Findnocase("mask parts", one.encumbranceDetail)>
					<cfif oneOfUs is 1>
					<div class="accordion" id="accordionMetadata">
					<div class="card mb-2 bg-light">
						<div id="metadataDialog"></div>
						<script>
							function reloadMetadata() { 
								// invoke specimen/component/public.cfc function getCollectorsHTML via ajax and repopulate the Other ID block.
								loadMetadata(#collection_object_id#,'metadataCardBody');
							}
						</script>
						<cfset blockMeta = getMetadataHTML(collection_object_id = "#collection_object_id#")>
						<div class="card-header" id="headingMetadata">
							<h3 class="h4 my-0 float-left collapsed btn-link">
								<a href="##" role="button" data-toggle="collapse" data-target="##MetadataPane">Meta Data</a>
							</h3>
							<cfif listcontainsnocase(session.roles,"manage_specimens")>
								<button type="button" class="btn btn-xs small py-0 float-right" onClick="openEditMetadataDialog(#collection_object_id#,'metadataDialog','#guid#',reloadMetadata)">Edit</button>
							</cfif>
						</div>
						<div id="MetadataPane" class="collapse show" aria-labelledby="headingMetadata" data-parent="##accordionMetadata">
							<div class="card-body py-2 mb-2 float-left" id="metadataCardBody">
								#blockMeta#
							</div>
						</div>
					</div>
				</div>
				<!---		<div class="card mb-2">
							<div class="card-header pt-1 float-left w-100">
								<h3 class="h4 my-0 mx-2 pb-1 float-left">
								Metadata
								</h3>
							</div>
							<div class="card-body mb-2 float-left">
								<ul class="list-group pl-0 pt-1">
									<cfif len(#one.coll_object_remarks#) gt 0>
										<li class="list-group-item">Remarks: #one.coll_object_remarks# </li>
									</cfif>
									<li class="list-group-item"> Entered By: #one.EnteredBy# on #dateformat(one.coll_object_entered_date,"yyyy-mm-dd")# </li>
									<cfif #one.EditedBy# is not "unknown" OR len(#one.last_edit_date#) is not 0>
										<li class="list-group-item"> Last Edited By: #one.EditedBy# on #dateformat(one.last_edit_date,"yyyy-mm-dd")# </li>
									</cfif>
									<cfif len(#one.flags#) is not 0>
										<li class="list-group-item"> Missing (flags): #one.flags# </li>
									</cfif>
									<cfif len(#one.encumbranceDetail#) is not 0>
										<li class="list-group-item"> Encumbrances: #replace(one.encumbranceDetail,";","<br>","all")# </li>
									</cfif>
								</ul>
							</div>
						</div>--->
					</cfif>
				</cfif>
			</div>
			<!--- end of column 3 --->
			
			<cfif oneOfUs is 1>
				</form>
						
			</cfif>
		</div>
	</div>
	</cfoutput>
	</div>
</section>
