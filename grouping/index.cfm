<cfset pageTitle = "Browse Named Groups">
<!--
grouping/index.cfm

Copyright 2021 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

-->
<cfif not isdefined("action")>
	<cfset action="allgroups">
</cfif>
<cfswitch expression="#action#">
	<!--- API note: action and method seem duplicative, action is required and used to determine
			which tab to show, method invokes target backing method in form submission, but when 
			invoking this page with execute=true method does not need to be included in the call
			even though it will be included in the URI parameter list when clicking on the 
			"Link to this search" link.
	--->
		<cfcase value="browseallgroups">
		<cfset pageTitle = "Browse Featured Collections">
		<cfif isdefined("execute")>
			<cfset execute="allgroups">
		</cfif>
	</cfcase>
	<cfcase value="browsecollection">
		<cfset pageTitle = "Browse Collections">
		<cfif isdefined("execute")>
			<cfset execute="collection">
		</cfif>
	</cfcase>
	<cfcase value="browseexpedition">
		<cfset pageTitle = "Browse Expeditions">
		<cfif isdefined("execute")>
			<cfset execute="expedition">
		</cfif>
	</cfcase>
	<cfcase value="browsegrant">
		<cfset pageTitle = "Browse Grants">
		<cfif isdefined("execute")>
			<cfset execute="grant">
		</cfif>
	</cfcase>
	<cfcase value="browseworkflows">
		<cfset pageTitle = "Browse Workflows">
		<cfif isdefined("execute")>
			<cfset execute="workflows">
		</cfif>
	</cfcase>
	<cfdefaultcase>
		<cfset pageTitle = "Browse All Collection Types">
		<cfif isdefined("execute")>
			<cfset execute="allgroups">
		</cfif>
	</cfdefaultcase>
</cfswitch>
<cfinclude template = "/shared/_header.cfm">
<cfinclude template="/grouping/component/search.cfc" runOnce="true">
<cfinclude template="/media/component/search.cfc" runOnce="true">
	<script src="/shared/js/tabs.js"></script>
<style>
	.nav-tabs .nav-link {background-color: #fff;border-color: #fff;border-bottom: 1px solid #f5f5f5;font-weight: 450;}	
	.nav-tabs .nav-link.active {background-color: #f5f5f5;border-color: #f5f5f5; font-weight:550;}
</style>
<cfquery name="types" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT underscore_collection_type, description 
	FROM ctunderscore_collection_type
	WHERE
		<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
			underscore_collection_type is not null
		<cfelse>
			underscore_collection_type <> 'workflow'
		</cfif>
</cfquery>
<cfquery name="namedGroups" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT
		count(FF.collection_object_id) ct, 
		underscore_collection.collection_name, 
		underscore_collection.underscore_collection_id, underscore_collection.mask_fg,
		underscore_collection.description, underscore_collection.underscore_collection_type,
		underscore_collection.displayed_media_id
	FROM
		underscore_collection 
		LEFT JOIN underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
		LEFT JOIN <cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif> FF
			on underscore_relation.collection_object_id = FF.collection_object_id
	WHERE
		underscore_collection.underscore_collection_id IS NOT NULL
		<cfif NOT isdefined("session.roles") OR listfindnocase(session.roles,"coldfusion_user") EQ 0>
			AND underscore_collection.mask_fg = 0
		</cfif>
		<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
			AND underscore_collection_type is not null
		<cfelse>
			AND underscore_collection.underscore_collection_type <> 'workflow'
		</cfif>
	GROUP BY
		underscore_collection.collection_name, 
		underscore_collection.underscore_collection_id, underscore_collection.mask_fg,
		underscore_collection.description, underscore_collection.underscore_collection_type,
		underscore_collection.displayed_media_id
	ORDER BY upper(collection_name)
</cfquery>
<cfoutput>
	<div class="w-100">
		<h1 class="px-2 mt-5 mb-0 text-center h2">MCZ Featured Collections of Cataloged Items</h1>		
	</div>
	<div class="container-fluid container-wide pb-5">
		<div class="row mb-4">

			<main class="col-12 py-2 float-left mt-0">
				<div class="mx-0 mx-md-5 px-0 mt-0">
					<p class="text-dark mt-1 text-justified small90 px-3 mb-2">The Museum of Comparative Zoology (MCZ) contains over 21-million specimens in ten research collections that comprise one of the world&apos;s richest and most varied resources for studying the diversity of life. The museum serves as the primary repository for zoological specimens collected by past and present Harvard faculty-curators, staff, and associates conducting research around the world. The public can see a small percentage of our holdings on display at the Harvard Museum of Natural History, but visitors can also browse MCZ specimens and metadata online via our Featured Collections.</p>
					<div class="tabs card-header tab-card-header px-2 pt-3">
						<cfswitch expression="#action#">
							<cfcase value="browseallgroups">
								<cfset allgroupsTabActive = "active">
								<cfset allgroupsTabShow = "">
								<cfset collectionTabActive = "">
								<cfset collectionTabShow = "hidden">
								<cfset expeditionTabActive = "">
								<cfset expeditionTabShow = "hidden">
								<cfset grantTabActive = "">
								<cfset grantTabShow = "hidden">
								<cfset workflowTabActive = "">
								<cfset workflowTabShow = "hidden">
								<cfset allgroupsTabAria = "aria-selected=""true"" tabindex=""0"" ">
								<cfset collectionTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset expeditionTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset grantTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset workflowTabAria = "aria-selected=""false"" tabindex=""-1"" ">
							</cfcase>
							<cfcase value="browsecollection">
								<cfset collectionTabActive = "active">
								<cfset collectionTabShow = "">
								<cfset allgroupsTabActive = "">
								<cfset allgroupsTabShow = "hidden">
								<cfset expeditionTabActive = "">
								<cfset expeditionTabShow = "hidden">
								<cfset grantTabActive = "">
								<cfset grantTabShow = "hidden">
								<cfset workflowTabActive = "">
								<cfset workflowTabShow = "hidden">
								<cfset allgroupsTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset collectionTabAria = "aria-selected=""true"" tabindex=""0"" ">
								<cfset expeditionTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset grantTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset workflowTabAria = "aria-selected=""false"" tabindex=""-1"" ">
							</cfcase>
							<cfcase value="browseexpedition">
								<cfset allgroupsTabActive = "">
								<cfset allgroupsTabShow = "hidden">
								<cfset collectionTabActive = "">
								<cfset collectionTabShow = "hidden">
								<cfset expeditionTabActive = "active">
								<cfset expeditionTabShow = "">
								<cfset workflowTabActive = "">
								<cfset workflowTabShow = "hidden">
								<cfset grantTabActive = "">
								<cfset grantTabShow = "hidden">
								<cfset allgroupsTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset collectionTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset expeditionTabAria = "aria-selected=""true"" tabindex=""0"" ">
								<cfset grantTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset workflowTabAria = "aria-selected=""false"" tabindex=""-1"" ">
							</cfcase>
							<cfcase value="browsegrant">
								<cfset allgroupsTabActive = "">
								<cfset allgroupsTabShow = "hidden">
								<cfset collectionTabActive = "">
								<cfset collectionTabShow = "hidden">
								<cfset expeditionTabActive = "">
								<cfset expeditionTabShow = "hidden">
								<cfset workflowTabActive = "">
								<cfset workflowTabShow = "hidden">
								<cfset grantTabActive = "active">
								<cfset grantTabShow = "">
								<cfset allgroupsTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset collectionTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset expeditionTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset workflowTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset grantTabAria = "aria-selected=""true"" tabindex=""0"" ">
							</cfcase>
							<cfcase value="browseworkflow">
								<cfset collectionTabActive = "">
								<cfset collectionTabShow = "hidden">
								<cfset collectionTabActive = "">
								<cfset collectionTabShow = "hidden">
								<cfset expeditionTabActive = "">
								<cfset expeditionTabShow = "hidden">
								<cfset grantTabActive = "">
								<cfset grantTabShow = "hidden">
								<cfset workflowTabActive = "active">
								<cfset workflowTabShow = "">
								<cfset collectionTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset expeditionTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset grantTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset workflowTabAria = "aria-selected=""true"" tabindex=""0"" ">
							</cfcase>			
							<cfdefaultcase>
								<cfset allgroupsTabActive = "active">
								<cfset allgroupsTabShow = "">
								<cfset collectionTabActive = "">
								<cfset collectionTabShow = "hidden">
								<cfset expeditionTabActive = "">
								<cfset expeditionTabShow = "hidden">
								<cfset grantTabActive = "">
								<cfset grantTabShow = "hidden">
								<cfset workflowTabActive = "">
								<cfset workflowTabShow = "hidden">
								<cfset allgroupsTabAria = "aria-selected=""true"" tabindex=""0"" ">
								<cfset collectionTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset grantTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset expeditionTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset workflowTabAria = "aria-selected=""false"" tabindex=""-1"" ">
							</cfdefaultcase>
						</cfswitch>
						<!-- Nav tabs -->
						<div class="tab-headers tabList" role="tablist" aria-label="browse collections types">
							<button class="col-12 col-md-auto px-md-4 px-xl-5 my-1 my-md-0 #allgroupsTabActive#" id="1" role="tab" aria-controls="allgroupsPanel" #allgroupsTabAria# aria-label="Browse All Collections">All</button>
							<button class="col-12 col-md-auto px-md-3 px-xl-5 my-1 my-md-0 #collectionTabActive#" id="2" role="tab" aria-controls="collectionPanel" #collectionTabAria# aria-label="Browse Collections"><img src="/shared/images/filter-3-line.svg" width="14">  Collections</button>
							<button class="col-12 col-md-auto px-md-3 px-xl-5 my-1 my-md-0 #expeditionTabActive#" id="3" role="tab" aria-controls="expeditionPanel" #expeditionTabAria# aria-label="Browse Expeditions"><img src="/shared/images/filter-3-line.svg" width="14"> Expeditions</button>
							<button class="col-12 col-md-auto px-md-3 px-xl-5 my-1 my-md-0 #grantTabActive#" id="4" role="tab" aria-controls="grantPanel" #grantTabAria# aria-label="Browse Grants"><img src="/shared/images/filter-3-line.svg" width="14"></i> Grants</button>
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
							<button class="col-12 col-md-auto px-md-3 px-xl-5 my-1 my-md-0 #workflowTabActive#" id="5" role="tab" aria-controls="workflowPanel" #workflowTabAria# aria-label="Browse Workflow"><img src="/shared/images/filter-3-line.svg" width="14"> Workflows</button>
							</cfif>
						</div>
						<div class="tab-content flex-wrap d-flex mb-1">
							<!---Fixed Search tab panel--->
							<div id="allgroupsPanel" role="tabpanel" aria-labelledby="1" tabindex="0" class="col-12 px-0 mx-0 #allgroupsTabActive# unfocus"  #allgroupsTabShow#>
								<h3 class="px-2">All</h3>
								<cfloop query="namedGroups">
									<div class="col-12 col-sm-6 col-md-6 col-xl-4 float-left px-1 mt-1 mb-1">
										<div class="border rounded bg-white p-2 col-12 float-left" style="height:117px">
											<div class="row h-25 mx-0">
												<div class="col text-truncate1 float-right px-2 pl-md-2 pr-md-0 mt-md-1">
													<cfset showTitleText = trim(collection_name)>
													<h3 class="h5 mb-1 pr-1">
														<a href="/grouping/showNamedCollection.cfm?underscore_collection_id=#namedGroups.underscore_collection_id#">
														#showTitleText#
														</a>
													</h3>
													<p class="mb-1 small">#namedGroups.ct# Cataloged Items</p>
													<p class="font-italic text-capitalize mb-0 smaller">Type: #namedGroups.underscore_collection_type#</p>
													<cfif namedGroups.mask_fg EQ 1>
														<!--- Users must be notified when hidden named groups are visible to them, otherwise they will think private information is public --->
														<p class="smaller">[Hidden]</p>
													</cfif>
												</div>
												<cfif len(namedGroups.displayed_media_id) gt 0>
													<cfset mediablock= getMediaBlockHtml(media_id="#namedGroups.displayed_media_id#",displayAs="fixedSmallThumb",background_color="white",size="100",captionAs="textNone")>
													<div class="float-right" id="mediaBlock#namedGroups.displayed_media_id#">
														#mediablock#
													</div>
												</cfif>
											</div>
										</div>
									</div>
								</cfloop>
							</div>
							<div id="collectionPanel" role="tabpanel" aria-labelledby="2" tabindex="-1" class="col-12 px-0 mx-0 #collectionTabActive# unfocus"  #collectionTabShow#>
								<h3 class="px-2">Collections</h3>
								<p class="px-2">Collections highlight specimens that are linked via their shared history and includes collections assembled by famous naturalists, histological slide collections, and acquisitions or exchanges from other museums.</p>
								<cfloop query="namedGroups">
									<cfif #namedGroups.underscore_collection_type# eq 'collection'>
										<div class="col-12 col-sm-6 col-md-6 col-xl-4 float-left px-1 mt-1 mb-1">
											<div class="border rounded bg-white p-2 col-12 float-left" style="min-height:117px">
												<div class="row h-25 mx-0">
													<div class="col text-truncate1 float-right px-2 pl-md-2 pr-md-0 mt-md-1">
														<cfset showTitleText = trim(collection_name)>
														<h3 class="h5 mb-1 pr-1">
															<a href="/grouping/showNamedCollection.cfm?underscore_collection_id=#namedGroups.underscore_collection_id#">
															#showTitleText#
															</a>
														</h3>
														<p class="mb-1 small">#namedGroups.ct# Cataloged Items</p>
														<p class="font-italic text-capitalize mb-0 smaller">Type: #namedGroups.underscore_collection_type# 	<cfif namedGroups.mask_fg EQ 1>
															[Hidden]
														</cfif>
														</p>
													</div>
													<cfif len(namedGroups.displayed_media_id) gt 0>
														<cfset mediablock= getMediaBlockHtml(media_id="#namedGroups.displayed_media_id#",displayAs="fixedSmallThumb",background_color="white",size="100",captionAs="textNone")>
														<div class="float-left" id="mediaBlock#namedGroups.displayed_media_id#">
															#mediablock#
														</div>
													</cfif>
												</div>
											</div>
										</div>
									</cfif>
								</cfloop>
							</div>
							<div id="expeditionPanel" role="tabpanel" aria-labelledby="3" tabindex="-1" class="col-12 px-0 mx-0 #expeditionTabActive# unfocus"  #expeditionTabShow#>
								<h3 class="px-2">Expeditions</h3>
								<p class="px-2">Expeditions feature specimens collected during specific voyages undertaken for the purpose of scientific exploration.</p>
								<cfloop query="namedGroups">
									<cfif #namedGroups.underscore_collection_type# eq 'expedition'>
										<div class="col-12 col-sm-6 col-md-6 col-xl-4 float-left px-1 mt-1 mb-1">
											<div class="border rounded bg-white p-2 col-12 float-left" style="min-height:117px">
												<div class="row h-25 mx-0">
													<div class="col text-truncate1 float-right px-2 px-md-2 mt-md-1">
														<cfset showTitleText = trim(collection_name)>
														<h3 class="h5 mb-1 pr-1">
															<a href="/grouping/showNamedCollection.cfm?underscore_collection_id=#namedGroups.underscore_collection_id#">
															#showTitleText#
															</a>
														</h3>
														<p class="mb-1 small">#namedGroups.ct# Cataloged Items</p>
														<p class="font-italic text-capitalize mb-0 smaller">Type: #namedGroups.underscore_collection_type# 	<cfif namedGroups.mask_fg EQ 1>
															[Hidden]
														</cfif>
														</p>
													</div>
													<cfif len(namedGroups.displayed_media_id) gt 0>
														<cfset mediablock= getMediaBlockHtml(media_id="#namedGroups.displayed_media_id#",displayAs="fixedSmallThumb",background_color="white",size="100",captionAs="textNone")>
														<div class="float-right" id="mediaBlock#namedGroups.displayed_media_id#">
															#mediablock#
														</div>
													</cfif>
												</div>
											</div>
										</div>
									</cfif>
								</cfloop>
							</div>
							<div id="grantPanel" role="tabpanel" aria-labelledby="4" tabindex="-1" class="col-12 px-0 mx-0 #grantTabActive# unfocus"  #grantTabShow#>
								<h3 class="px-2">Grants</h3>
								<p class="px-2">Grants showcase specimens used in funded work and includes digitization projects that enrich digital specimen data and make MCZ holdings more accessible to researchers around the world.</p>
								<cfloop query="namedGroups">
									<cfif #namedGroups.underscore_collection_type# eq 'grant'>
										<div class="col-12 col-sm-6 col-md-6 col-xl-4 float-left px-1 mt-1 mb-1">
											<div class="border rounded bg-white p-2 col-12 float-left" style="min-height:117px">
												<div class="row h-25 mx-0">
													<div class="col text-truncate1 float-right px-2 px-md-2 mt-md-1">
														<cfset showTitleText = trim(collection_name)>
														<h3 class="h5 mb-1 pr-1">
															<a href="/grouping/showNamedCollection.cfm?underscore_collection_id=#namedGroups.underscore_collection_id#">
															#showTitleText#
															</a>
														</h3>
														<p class="mb-1 small">#namedGroups.ct# Cataloged Items</p>
														<p class="font-italic text-capitalize mb-0 smaller">Type: #namedGroups.underscore_collection_type# 	<cfif namedGroups.mask_fg EQ 1>
														[Hidden]
														</cfif>
														</p>
													</div>
													<cfif len(namedGroups.displayed_media_id) gt 0>
														<cfset mediablock= getMediaBlockHtml(media_id="#namedGroups.displayed_media_id#",displayAs="fixedSmallThumb",background_color="white",size="100",captionAs="textNone")>
														<div class="float-right" id="mediaBlock#namedGroups.displayed_media_id#">
															#mediablock#
														</div>
													</cfif>
												</div>
											</div>
										</div>
									</cfif>
								</cfloop>
							</div>
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
								<div id="workflowPanel" role="tabpanel" aria-labelledby="5" tabindex="-1" class="col-12 px-0 mx-0 #workflowTabActive# unfocus"  #workflowTabShow#>
									<h3 class="px-2">Workflow</h3>
									<cfloop query="namedGroups">
										<cfif #namedGroups.underscore_collection_type# eq 'workflow'>
											<div class="col-12 col-sm-6 col-md-6 col-xl-4 float-left px-1 mt-1 mb-1">
												<div class="border rounded bg-white py-2 col-12 px-2 float-left" style="min-height:117px">
													<div class="row h-25 mx-0">
														<div class="col text-truncate1 float-right px-2 px-md-2 mt-md-1">
															<cfset showTitleText = trim(collection_name)>
															<h3 class="h5 mb-1 pr-1">
																<a href="/grouping/showNamedCollection.cfm?underscore_collection_id=#namedGroups.underscore_collection_id#">
																#showTitleText#
																</a>
															</h3>
															<p class="mb-1 small">#namedGroups.ct# Cataloged Items</p>
															<p class="font-italic text-capitalize mb-0 smaller">Type: #namedGroups.underscore_collection_type# <cfif namedGroups.mask_fg EQ 1>[Hidden]</cfif>
															</p>
														</div>
														<cfif len(namedGroups.displayed_media_id) gt 1>
															<cfset mediablock= getMediaBlockHtml(media_id="#namedGroups.displayed_media_id#",displayAs="fixedSmallThumb", background_color="white", size="100",captionAs="textNone")>
															<div class="float-right" id="mediaBlock#namedGroups.displayed_media_id#">
																#mediablock#
															</div>
														</cfif>
													</div>
												</div>
											</div>
										</cfif>	
									</cfloop>
								</div>
							</cfif>
						</div>
					</div>
				</div>
			</main>
		</div>
	</div>
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
