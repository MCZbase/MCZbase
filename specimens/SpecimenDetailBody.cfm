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
<cfinclude template="/media/component/search.cfc" runOnce="true">
<cfinclude template="/vocabularies/component/search.cfc" runOnce="true">
<!--- query one is needed for the metadata block and one.collection_object_id is used for the counts on media and part headers --->
<cfquery name="one" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="one_result">
	SELECT distinct
		cataloged_item.collection_object_id as collection_object_id,
		cataloged_item.cat_num,
		collection.collection_cde,
		coll_object.coll_object_entered_date,
		coll_object.last_edit_date,
		coll_object.flags,
		<cfif #oneOfUs# eq 1>
			cataloged_item.accn_id,
		<cfelse>
			NULL as accn_id,
		</cfif>
		getpreferredagentname(coll_object.entered_person_id) EnteredBy,
		getpreferredagentname(coll_object.last_edited_person_id) EditedBy,
		concatencumbrances(cataloged_item.collection_object_id) concatenatedEncumbrances,
		concatEncumbranceDetails(cataloged_item.collection_object_id) encumbranceDetail
	FROM
		cataloged_item 
		left join coll_object on cataloged_item.collection_object_id = coll_object.collection_object_id
		left join collection on cataloged_item.collection_id = collection.collection_id
	WHERE
		cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
</cfquery>
<cfif one.recordcount EQ 0>
	<cfthrow message = "Error: Unable to find cataloged_item.collection_object_id = '#encodeForHtml(collection_object_id)#'">
</cfif>
<cfif one.recordcount GT 1>
	<cfthrow message = "Error: multiple rows returned from query 'one' for cataloged_item.collection_object_id = '#encodeForHtml(collection_object_id)#'">
</cfif>
<cfset guid = "MCZ:#one.collection_cde#:#one.cat_num#">
<cfquery name="mediaCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="mediaCount_result">
	select count(*) as ct 
	from 
		media_relations
	where 
		media_relations.related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#one.collection_object_id#" >
</cfquery>
<cfquery name="images" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT
		media.media_id
	FROM
		media
		left join media_relations on media_relations.media_id = media.media_id
	WHERE
		media_relations.related_primary_key = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
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
	<div class="container-lg d-none d-lg-block mb-2 my-lg-1">
		<div class="row">
			<cfif #oneOfUs# eq 1>
				<ul class="list-group list-inline list-group-horizontal-md mt-0 pt-0 pb-1 mx-auto">
					<li class="list-group-item px-0 mx-1">
						<div id="mediaDialog"></div>
						<script>
							function reloadMedia() { 
								// invoke specimen/component/public.cfc function getIdentificationHTML via ajax and repopulate the identification block.
								loadMedia(#collection_object_id#,'mediaCardBody');
							}
						</script>
						<cfif listcontainsnocase(session.roles,"manage_media")>
							<button type="button" class="btn btn-xs btn-powder-blue small py-0" onClick="openEditMediaDialog(#collection_object_id#,'mediaDialog','#guid#',reloadMedia)">Media</button>
						</cfif>
					</li>
					<li class="list-group-item px-0 mx-1">
						<button type="button" id="btn_pane" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditIdentificationsDialog(#collection_object_id#,'identificationsDialog','#guid#',reloadIdentifications)">Identifications</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<button type="button" id="btn_pane" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditCitationsDialog(#collection_object_id#,'citationsDialog','#guid#',reloadCitations)">Citations</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<div id="otherIDsDialog"></div>
						<script>
							function reloadOtherIDs() { 
								// invoke specimen/component/public.cfc function getIdentificationHTML via ajax and repopulate the identification block.
								loadOtherIDs(#collection_object_id#,'otherIDsCardBody');
							}
						</script>
						<button type="button" id="btn_pane" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditOtherIDsDialog(#collection_object_id#,'otherIDsDialog','#guid#',reloadOtherIDs)">Other&nbsp;IDs</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<button type="button" id="btn_pane" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditPartsDialog(#collection_object_id#,'partsDialog','#guid#',reloadParts)">Parts</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<button type="button" id="btn_pane" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditAttributesDialog(#collection_object_id#,'attributesDialog','#guid#',reloadAttributes)">Attributes</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<button type="button" id="btn_pane" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditRelationsDialog(#collection_object_id#,'relationsDialog','#guid#',reloadRelations)">Relationships</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<button type="button" id="btn_pane" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditLocalityDialog(#collection_object_id#,'localityDialog','#guid#',reloadLocality)">Locality</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<button type="button" id="btn_pane" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditLocalityDialog(#collection_object_id#,'localityDialog','#guid#',reloadLocality)">Event</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<button type="button" id="btn_pane" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditCollectorsDialog(#collection_object_id#,'collectorsDialog','#guid#',reloadCollectors)">Collectors</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<button type="button" id="btn_pane" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditTransactionsDialog(110406,'transactionsDialog','#guid#',reloadTransactions)">Transactions</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<button type="button" id="btn_pane" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditMetadataDialog(#collection_object_id#,'metadataDialog','#guid#',reloadMetadata)">Meta&nbsp;Data</button>
					</li>
				</ul>
			</cfif>
		</div>
	</div>
	<div class="container-fluid mt-3 mt-lg-0">
		<div class="row mx-0">
			<!----------------------------- one left column for media ---------------------------------->
			<cfif mediaCount.ct gt 0>
				<div class="col-12 col-sm-12 col-md-3 col-lg-3 col-xl-2 px-1 mb-2 float-left">
					<!-----------------------------Media----------------------------------> 
					<div class="accordion" id="accordionMedia">
						<div class="card mb-2 bg-light">
							<div id="mediaDialog"></div>
							<script>
								function reloadMedia() { 
									// invoke specimen/component/public.cfc function getMediaHTML via ajax and repopulate the media block.
									loadMedia(#collection_object_id#,'mediaCardBody');
								}
							</script>
							<div class="card-header" id="headingMedia">
								<h3 class="h4 my-0 text-dark">
									<button type="button" class="headerLnk text-left h-100 w-100" href="##" data-toggle="collapse" data-target="##mediaPane" aria-expanded="true" aria-controls="mediaPane">
										Media
										<span class="text-success font-weight-light">(#mediaCount.ct#)</span>
									</button>
									<cfif listcontainsnocase(session.roles,"manage_media")>
										<a role="button" href="##" class="btn btn-xs small py-0 anchorFocus" id="btn_pane" onClick="openEditMediaDialog(#collection_object_id#,'mediaDialog','#guid#',reloadMedia)">Add/Remove</a>
									</cfif>
								</h3>
							</div>
							<div id="mediaPane" class="collapse show" aria-labelledby="headingMedia" data-parent="##accordionMedia">
								<div class="card-body w-100 px-1 pt-2 float-left" id="mediaCardBody">
									<cfloop query="images">
										<cfquery name="getImages" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
											select media_labels.label_value 
											from media_labels 
											where media_labels.media_label = 'height'
											order by label_value
										</cfquery>
										<div class="col-12 px-1 col-md-6 mb-2 float-left">
											<cfset mediaBlock= getMediaBlockHtml(media_id="#images.media_id#", height=#getImages.label_value#, displayAs="thumb")>
											<div id="mediaBlock#images.media_id#">
												#mediaBlock#
											</div>
										</div>
									</cfloop>
								</div>
							</div>
						</div>
					</div>
				</div>
			</cfif>
			<!----------------------------- two right columns ---------------------------------->
			<div class="col-12 col-sm-12 mb-2 clearfix px-0 <cfif mediaCount.ct gt 0>col-md-9 col-lg-9 col-xl-10<cfelse>col-md-12 col-lg-12 col-xl-12</cfif> float-left">
				<div class="col-12 col-md-6 px-1 float-left"> 
					<!----------------------------- identifications ----------------------------------> 
					<div class="accordion" id="accordionB">
						<div class="card mb-2 bg-light">
							<div id="identificationsDialog"></div>
							<script>
								function reloadIdentifications() { 
									// invoke specimen/component/public.cfc function getIdentificationHTML via ajax and repopulate the identification block.
									loadIdentifications(#collection_object_id#,'identificationsCardBody');
								}
							</script>
							<cfset blockident = getIdentificationsHTML(collection_object_id = "#collection_object_id#")>
							<div class="card-header" id="heading1">
								<cfif len(#blockident#) gt 10> 
									<h3 class="h4 my-0" tabindex="0">
										<button type="button" class="headerLnk text-left w-100" href="##" data-toggle="collapse" data-target="##identificationsPane" aria-expanded="true" aria-controls="identificationPane">
											Identifications
										</button>
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<a role="button" href="##" id="btn_pane" class="anchorFocus btn btn-xs small py-0" onClick="openEditIdentificationsDialog(#collection_object_id#,'identificationsDialog','#guid#',reloadIdentifications)">
												Edit
											</a>
										</cfif>
									</h3>
								<cfelse>
									<h3 class="h4 my-0" tabindex="0">
										<button type="button" class="headerLnk text-left w-100 h-100" href="##" data-toggle="collapse" data-target="##identificationsPane" aria-controls="identificationPane">
											Identifications
										</button>
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<a role="button" href="##" id="btn_pane" class="anchorFocus btn btn-xs small py-0" onClick="openEditIdentificationsDialog(#collection_object_id#,'identificationsDialog','#guid#',reloadIdentifications)">
												Add
											</a>
										</cfif>
									</h3>
								</cfif>
							</div>
							<div id="identificationsPane" class="collapse show" aria-labelledby="heading1" data-parent="##accordionB">
								<div class="card-body py-1 mb-1 w-100 float-left" id="identificationsCardBody">
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
								<h3 class="h4 my-0 text-dark">
									<button type="button" class="headerLnk text-left h-100 w-100" href="##" data-toggle="collapse" data-target="##citationsPane" aria-expanded="true" aria-controls="citationsPane">
										Citations
									</button>
									<cfif listcontainsnocase(session.roles,"manage_specimens")>
										<a role="button" href="##" class="btn btn-xs small py-0 anchorFocus" onClick="openEditCitationsDialog(#collection_object_id#,'citationsDialog','#guid#',reloadCitations)">Add/Remove</a>
									</cfif>
								</h3>
							</div>
							<div id="citationsPane" class="collapse show" aria-labelledby="headingCitations" data-parent="##accordionCitations">
								<div class="card-body py-1 mb-1 float-left" id="citationsCardBody">
									<cfif len(#blockcit#) gt 10>
										#blockcit#
									<cfelse>
										<ul class="pl-0 mb-0">
											<li>None</li>
										</ul>
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
								<cfif len(#blockotherid#) gt 1> 
									<h3 class="h4 my-0">
										<button type="button" class="headerLnk text-left w-100 h-100" aria-expanded="true" aria-controls="OtherIDsPane" data-toggle="collapse" data-target="##OtherIDsPane">
											Other IDs
										</button>
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<a role="button" href="##" class="anchorFocus btn btn-xs small py-0" onClick="openEditOtherIDsDialog(#collection_object_id#,'otherIDsDialog','#guid#',reloadOtherIDs)">
												Edit
											</a>
										</cfif>
									</h3>
								<cfelse>
									<h3 class="h4 my-0">
										<button type="button" aria-controls="OtherIDsPane" data-toggle="collapse" data-target="##OtherIDsPane">
											Other IDs
										</button>
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<a role="button" href="##" class="btn btn-xs small py-0 anchorFocus" onClick="openEditOtherIDsDialog(#collection_object_id#,'otherIDsDialog','#guid#',reloadOtherIDs)">
												Add
											</a>
										</cfif>
									</h3>
								</cfif>
							</div>
							<div id="OtherIDsPane" class="collapse show" aria-labelledby="headingOtherID" data-parent="##accordionOtherID">
								<div class="card-body py-1 mb-1 float-left" id="otherIDsCardBody">
									<cfif len(#blockotherid#) gt 0>
										#blockotherid#
									<cfelse>
										<ul class="pl-0 mb-0"><li>None</li></ul>
									</cfif>
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
								<h3 class="h4 my-0">
									<button type="button" class="headerLnk text-left w-100 h-100" aria-controls="PartsPane" aria-expanded="true" data-toggle="collapse" data-target="##PartsPane">
										Parts <span class="text-success font-weight-light">(#ctPart.ct#)</span>
									</button>
									
									<cfif listcontainsnocase(session.roles,"manage_specimens")>
										<a href="##" role="button" class="btn btn-xs small py-0 anchorFocus" onClick="openEditPartsDialog(#collection_object_id#,'partsDialog','#guid#',reloadParts)">
											Edit
										</a>
									</cfif>
								</h3>
							</div>
							<div id="PartsPane" <cfif #ctPart.ct# gt 5>style="height:300px;"</cfif> class="collapse show" aria-labelledby="headingParts" data-parent="##accordionParts">
								<div class="card-body py-1 w-100 mb-1 float-left" id="partsCardBody">
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
									<h3 class="h4 my-0">
										<button type="button" class="headerLnk text-left w-100 h-100" aria-expanded="true" aria-controls="AttributesPane" data-toggle="collapse" data-target="##AttributesPane">
											Attributes
										</button>
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<a href="##" role="button" class="btn btn-xs small py-0 anchorFocus" onClick="openEditAttributesDialog(#collection_object_id#,'attributesDialog','#guid#',reloadAttributes)">
												Edit
											</a>
										</cfif>
									</h3>
								<cfelse>
									<h3 class="h4 my-0">
										<button type="button" class="headerLnk text-left w-100 h-100" aria-expanded="true" aria-controls="AttributesPane" data-toggle="collapse" data-target="##AttributesPane">
											Attributes
										</button>
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<a href="##" role="button" class="btn btn-xs small py-0 anchorFocus" onClick="openEditAttributesDialog(#collection_object_id#,'attributesDialog','#guid#',reloadAttributes)">
												Add
											</a>
										</cfif>
									</h3>
								</cfif>
							</div>
							<div id="AttributesPane" class="collapse show" aria-labelledby="headingAttributes" data-parent="##accordionAttributes">
								<div class="card-body py-1 mb-1 float-left" id="attributesCardBody">
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
									<h3 class="h4 my-0">
										<button type="button" class="headerLnk w-100 h-100 text-left" data-toggle="collapse" aria-expanded="true" data-target="##RelationsPane">
											Relationships
										</button>
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<a role="button" href="##" class="btn btn-xs small py-0 anchorFocus" onClick="openEditRelationsDialog(#collection_object_id#,'relationsDialog','#guid#',reloadRelations)">
												Edit
											</a>
										</cfif>
									</h3>
								<cfelse>
									<h3 class="h4 my-0">
										<button type="button" class="headerLnk w-100 h-100 text-left" data-toggle="collapse" aria-expanded="true" data-target="##RelationsPane">
											Relationships
										</button>
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<a role="button" href="##" class="btn btn-xs small py-0 anchorFocus" onClick="openEditRelationsDialog(#collection_object_id#,'relationsDialog','#guid#',reloadRelations)">
												Add
											</a>
										</cfif>
									</h3>
								</cfif>
							</div>
							<div id="RelationsPane" class="collapse show" aria-labelledby="headingRelations" data-parent="##accordionRelations">
								<div class="card-body py-1 mb-1 float-left" id="relationsCardBody">
										<cfif len(#blockrel#) gt 60> #blockrel# <cfelse><ul class="pl-0 mb-0"><li>None</li></ul></cfif>
								</div>
							</div>
						</div>
					</div>
				</div>
				<!---  start of column three  --->
				<div class="col-12 col-md-6 px-1 float-left"> 
					<!--------------------locality and collecting event------------------------------>
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
									<h3 class="h4 my-0">
										<button type="button" data-toggle="collapse" aria-expanded="true" data-target="##LocalityPane" aria-controls="LocalityPane" class="headerLnk w-100 h-100 text-left">
											Location and Collecting Event
										</button>
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<a href="##" role="button" class="btn btn-xs small py-0 anchorFocus" onClick="openEditLocalityDialog(#collection_object_id#,'localityDialog','#guid#',reloadLocality)">
												Edit
											</a>
										</cfif>
									</h3>
								<cfelse>
									<h3 class="h4 my-0">
										<button type="button" class="headerLnk w-100 h-100 text-left" data-toggle="collapse" aria-expanded="true" aria-controls="LocalityPane" data-target="##LocalityPane">
											Location and Collecting Event
										</button>
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<a href="##" role="button" class="btn btn-xs small py-0 anchorFocus" onClick="openEditLocalityDialog(#collection_object_id#,'localityDialog','#guid#',reloadLocality)">
												Add
											</a>
										</cfif>
									</h3>
								</cfif>
							</div>
							<div id="LocalityPane" class="collapse show" aria-labelledby="headingLocality" data-parent="##accordionLocality">
								<div class="card-body px-0 py-1 mb-1 float-left" id="localityCardBody">
									<cfif len(#blocklocality#) gt 60> #blocklocality# <cfelse><ul class="pl-0 mb-0"><li>None</li></ul></cfif>
								</div>
							</div>
						</div>
					</div>
					<!------------------- Collectors and Preparators ---------------------------->
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
							<div class="card-header" id="headingCollectors">
								<cfif len(#blockcollectors#) gt 5>
									<h3 class="h4 my-0">
										<button type="button" data-toggle="collapse" class="w-100 h-100 headerLnk text-left" aria-controls="CollectorsPane" aria-expanded="true" data-target="##CollectorsPane">
											Collectors and Preparators
										</button>
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<a href="##" role="button" class="btn btn-xs small py-0 anchorFocus" onClick="openEditCollectorsDialog(#collection_object_id#,'collectorsDialog','#guid#',reloadCollectors)">
												Edit
											</a>
										</cfif>
									</h3>
								<cfelse>
									<h3 class="h4 my-0">
										<button class="headerLnk w-100 h-100 text-left" aria-expanded="true" type="button" aria-controls="CollectorsPane" data-toggle="collapse" data-target="##CollectorsPane">
											Collectors and Preparators
										</button>
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<a href="##" role="button" class="btn btn-xs small py-0 anchorFocus" onClick="openEditCollectorsDialog(#collection_object_id#,'collectorsDialog','#guid#',reloadCollectors)">
												Add
											</a>
										</cfif>
									</h3>
								</cfif>
							</div>
							<div id="CollectorsPane" class="collapse show" aria-labelledby="headingCollectors" data-parent="##accordionCollectors">
								<div class="card-body py-1 mb-1 float-left" id="collectorsCardBody">
									<cfif len(#blockcollectors#) gt 60> #blockcollectors# <cfelse><ul class="pl-0 mb-0"><li>None</li></ul></cfif>
								</div>
							</div>
						</div>
					</div>
					<!------------------------------ tranactions  --------------------------------->
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
								<h3 class="h4 my-0">
									<button type="button" aria-controls="TransactionsPane" class="w-100 h-100 text-left headerLnk" aria-expanded="true" data-toggle="collapse" data-target="##TransactionsPane">
										Transactions
									</button>
									<cfif listcontainsnocase(session.roles,"manage_specimens")>
										<a role="button" href="##" class="btn btn-xs small py-0 anchorFocus" onClick="openEditTransactionsDialog(#collection_object_id#,'transactionsDialog','#guid#',reloadTransactions)">
											Edit
										</a>
									</cfif>
								</h3>
							</div>
							<div id="TransactionsPane" class="collapse show" aria-labelledby="headingTransactions" data-parent="##accordionTransactions">
								<div class="card-body py-1 mb-1 float-left" id="transactionsCardBody">
									<cfset block = getTransactionsHTML(collection_object_id = "#collection_object_id#")>
									#block#
								</div>
							</div>
						</div>
					</div>
				</div>
				<!--- end of column 3 --->
				<cfif oneOfUs is 1>
					</div>
					</form>
				</cfif>
			</div>
		</div>
	
</div>
</cfoutput>
