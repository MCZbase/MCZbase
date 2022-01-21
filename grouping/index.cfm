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
	<cfset action="collection">
</cfif>
<cfswitch expression="#action#">
	<!--- API note: action and method seem duplicative, action is required and used to determine
			which tab to show, method invokes target backing method in form submission, but when 
			invoking this page with execute=true method does not need to be included in the call
			even though it will be included in the URI parameter list when clicking on the 
			"Link to this search" link.
	--->
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
		<cfset pageTitle = "Browse Collections">
		<cfif isdefined("execute")>
			<cfset execute="collection">
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
	ORDER BY underscore_collection_type, collection_name
</cfquery>
<cfoutput>
	<div class="w-100">
		<h1 class="px-2 mt-5 mb-0 text-center h2">MCZ Featured Collections of Cataloged Items</h1>		
	</div>
	<div class="container-fluid">
		<div class="row mb-4">

			<main class="col-12 col-md-12 px-0 py-2 mb-3 float-left mt-1">
				<div class="container px-0 mt-2">
					<p class="text-dark mt-1 text-justified small90 mb-1">The Museum of Comparative Zoology (MCZ) contains over 21-million specimens in ten research collections that comprise one of the world's richest and most varied resources for studying the diversity of life. The museum serves as the primary repository for zoological specimens collected by past and present Harvard faculty-curators, staff, and associates conducting research around the world. The public can see a small percentage of our holdings on display at the Harvard Museum of Natural History, but visitors can also browse MCZ specimens and metadata online via our Featured Collections.</p>
					<div class="tabs card-header tab-card-header px-2 pt-3">
						<cfswitch expression="#action#">
							<cfcase value="browsecollection">
								<cfset collectionTabActive = "active">
								<cfset collectionTabShow = "">
								<cfset expeditionTabActive = "">
								<cfset expeditionTabShow = "hidden">
								<cfset grantTabActive = "">
								<cfset grantTabShow = "hidden">
								<cfset workflowTabActive = "">
								<cfset workflowTabShow = "hidden">
								<cfset collectionTabAria = "aria-selected=""true"" tabindex=""0"" ">
								<cfset expeditionTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset grantTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset workflowTabAria = "aria-selected=""false"" tabindex=""-1"" ">
							</cfcase>
							<cfcase value="browseexpedition">
								<cfset collectionTabActive = "">
								<cfset collectionTabShow = "hidden">
								<cfset expeditionTabActive = "active">
								<cfset expeditionTabShow = "">
								<cfset workflowTabActive = "">
								<cfset workflowTabShow = "hidden">
								<cfset grantTabActive = "">
								<cfset grantTabShow = "hidden">
								<cfset collectionTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset expeditionTabAria = "aria-selected=""true"" tabindex=""0"" ">
								<cfset grantTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset workflowTabAria = "aria-selected=""false"" tabindex=""-1"" ">
							</cfcase>
							<cfcase value="browsegrant">
								<cfset collectionTabActive = "">
								<cfset collectionTabShow = "hidden">
								<cfset expeditionTabActive = "">
								<cfset expeditionTabShow = "hidden">
								<cfset workflowTabActive = "">
								<cfset workflowTabShow = "hidden">
								<cfset grantTabActive = "active">
								<cfset grantTabShow = "">
								<cfset collectionTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset expeditionTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset workflowTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset grantTabAria = "aria-selected=""true"" tabindex=""0"" ">
							</cfcase>
							<cfcase value="browseworkflow">
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
								<cfset collectionTabActive = "active">
								<cfset collectionTabShow = "">
								<cfset expeditionTabActive = "">
								<cfset expeditionTabShow = "hidden">
								<cfset grantTabActive = "">
								<cfset grantTabShow = "hidden">
								<cfset workflowTabActive = "">
								<cfset workflowTabShow = "hidden">
								<cfset collectionTabAria = "aria-selected=""true"" tabindex=""0"" ">
								<cfset grantTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset expeditionTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset workflowTabAria = "aria-selected=""false"" tabindex=""-1"" ">
							</cfdefaultcase>
						</cfswitch>
						<!-- Nav tabs -->
						<div class="tab-headers tabList" role="tablist" aria-label="browse collections types">
							<button class="col-12 col-md-auto px-md-5 my-1 my-md-0 #collectionTabActive#" id="1" role="tab" aria-controls="collectionPanel" #collectionTabAria# aria-label="Browse Collections">Collections</button>
							<button class="col-12 col-md-auto px-md-5 my-1 my-md-0 #expeditionTabActive#" id="2" role="tab" aria-controls="expeditionPanel" #expeditionTabAria# aria-label="Browse Expeditions">Expeditions</button>
							<button class="col-12 col-md-auto px-md-5 my-1 my-md-0 #grantTabActive#" id="3" role="tab" aria-controls="grantPanel" #grantTabAria# aria-label="Browse Grants">Grants</button>
							<button class="col-12 col-md-auto px-md-5 my-1 my-md-0 #workflowTabActive#" id="4" role="tab" aria-controls="workflowPanel" #workflowTabAria# aria-label="Browse Workflow">Workflows</button>
						</div>
						<div class="tab-content flex-wrap d-flex mb-1">
							<!---Fixed Search tab panel--->
							<div id="collectionPanel" role="tabpanel" aria-labelledby="1" tabindex="0" class="col-12 px-0 mx-0 #collectionTabActive# unfocus"  #collectionTabShow#>
								<h3 class="px-2">Collections</h3>
								<p class="px-2">Collections highlight specimens that are linked via their shared history and includes collections assembled by famous naturalists, histological slide collections, and acquisitions or exchanges from other museums.</p>
								<cfloop query="namedGroups">
									<cfquery name="images" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
										SELECT
											displayed_media_id as media_id, underscore_collection.underscore_collection_type
										FROM
											underscore_relation 
										INNER JOIN underscore_collection
											on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
										WHERE rownum = 1 
										and underscore_relation.underscore_collection_id = #namedGroups.underscore_collection_id#
									</cfquery>
									<cfif #namedGroups.underscore_collection_type# eq 'collection'>
										<div class="col-12 col-md-4 col-xl-3 float-left px-1 mt-1 mb-1">
											<div class="border rounded bg-white p-2 col-12 float-left" style="min-height:116px">
												<div class="row h-25 mx-0">
													<cfif len(images.media_id) gt 0>
														<cfset mediablock= getMediaBlockHtml(media_id="#images.media_id#",size="105",displayAs="thumbTiny")>
														<div class="px-1 float-left py-1 bg-light border rounded" id="mediaBlock#images.media_id#" style="width: 100px;">
														#mediablock#
														</div>
													</cfif>
													<div class="col float-left px-2 pl-md-1 pr-md-0 mt-0">
														<h3 class="h5 mb-1"><a href="/grouping/showNamedCollection.cfm?underscore_collection_id=#namedGroups.underscore_collection_id#">
														<cfif len(namedGroups.collection_name) GT 35>
															<cfset collection_name = "#left(namedGroups.collection_name,35)#..." >
														</cfif>#namedGroups.collection_name#
														</a></h3>
														<p class="mb-1 small">#namedGroups.ct# Cataloged Items</p>
														<p class="font-italic text-capitalize mb-0 smaller">Type: #namedGroups.underscore_collection_type#</p>
													</div>
												</div>
											</div>
										</div>
									</cfif>
								</cfloop>
							</div>
							<div id="expeditionPanel" role="tabpanel" aria-labelledby="2" tabindex="-1" class="col-12 px-0 mx-0 #expeditionTabActive# unfocus"  #expeditionTabShow#>
								<h3 class="px-2">Expeditions</h3>
								<p class="px-2">Expeditions feature specimens collected during specific voyages undertaken for the purpose of scientific exploration.</p>
								<cfloop query="namedGroups">
									<cfquery name="images" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
										SELECT
											displayed_media_id as media_id
										FROM
											underscore_relation 
										INNER JOIN underscore_collection
											on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
										WHERE rownum = 1 
										and underscore_relation.underscore_collection_id = #namedGroups.underscore_collection_id#
									</cfquery>
									<cfif #namedGroups.underscore_collection_type# eq 'expedition'>
										<div class="col-12 col-md-4 col-xl-3 float-left px-1 mt-2 mb-1">
											<div class="border rounded bg-white p-2 col-12 float-left" style="min-height:116px">
												<div class="row h-25 mx-0">
													<cfif len(images.media_id) gt 0>
														<cfset mediablock= getMediaBlockHtml(media_id="#images.media_id#",size="105",displayAs="thumbTiny")>
														<div class="px-1 float-left py-1 bg-light border rounded" id="mediaBlock#images.media_id#" style="width: 100px;">
														#mediablock#
														</div>
													</cfif>
													<div class="col float-left px-2 px-md-1 mt-0">
														<h3 class="h5 mb-1"><a href="/grouping/showNamedCollection.cfm?underscore_collection_id=#namedGroups.underscore_collection_id#">#namedGroups.collection_name#</a></h3>
														<p>#namedGroups.description#</p>
														<p class="mb-1 small">#namedGroups.ct# Cataloged Items</p>
														<p class="font-italic text-capitalize mb-0 smaller">Type: #namedGroups.underscore_collection_type#</p>
													</div>
												</div>
											</div>
										</div>
									</cfif>
								</cfloop>
							</div>
							<div id="grantPanel" role="tabpanel" aria-labelledby="3" tabindex="-1" class="col-12 px-0 mx-0 #grantTabActive# unfocus"  #grantTabShow#>
								<h3 class="px-2">Grants</h3>
								<p class="px-2">Grants showcase specimens used in funded work and includes digitization projects that enrich digital specimen data and make MCZ holdings more accessible to researchers around the world.</p>
								<cfloop query="namedGroups">
								<cfquery name="images" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									SELECT
										displayed_media_id as media_id
									FROM
										underscore_relation 
									INNER JOIN underscore_collection
										on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
									WHERE rownum = 1 
									and underscore_relation.underscore_collection_id = #namedGroups.underscore_collection_id#
								</cfquery>
								<cfif #namedGroups.underscore_collection_type# eq 'grant'>
									<div class="col-12 col-md-4 col-xl-3 float-left px-1 mt-2 mb-1">
										<div class="border rounded bg-white p-2 col-12 float-left" style="min-height:116px">
											<div class="row h-25 mx-0">
												<cfif len(images.media_id) gt 0>
													<cfset mediablock= getMediaBlockHtml(media_id="#images.media_id#",size="105",displayAs="thumbTiny")>
													<div class="px-1 float-left py-1 bg-light border rounded" id="mediaBlock#images.media_id#" style="width: 100px;">
													#mediablock#
													</div>
												</cfif>
												<div class="col float-left px-2 px-md-1 mt-0">
													<h3 class="h5 mb-1"><a href="/grouping/showNamedCollection.cfm?underscore_collection_id=#namedGroups.underscore_collection_id#">#namedGroups.collection_name#</a></h3>
													<p class="mb-1 small">#namedGroups.ct# Cataloged Items</p>
													<p class="font-italic text-capitalize mb-0 smaller">Type: #namedGroups.underscore_collection_type#</p>
												</div>
											</div>
										</div>
									</div>
								</cfif>
							</cfloop>
							</div>
							<div id="workflowPanel" role="tabpanel" aria-labelledby="4" tabindex="-1" class="col-12 px-0 mx-0 #workflowTabActive# unfocus"  #workflowTabShow#>
								<h3 class="px-2">Workflow</h3>
								<cfloop query="namedGroups">
								<cfquery name="images" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									SELECT
										displayed_media_id as media_id
									FROM
										underscore_relation 
									INNER JOIN underscore_collection
										on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
									WHERE rownum = 1 
									and underscore_relation.underscore_collection_id = #namedGroups.underscore_collection_id#
								</cfquery>
								<cfif #namedGroups.underscore_collection_type# eq 'workflow'>
									<div class="col-12 col-md-4 col-xl-3 float-left px-1 mt-2 mb-1">
										<div class="border rounded bg-white py-2 col-12 px-2 float-left">
											<div class="row h-25 mx-0">
												<cfif len(images.media_id) gt 0>
													<cfset mediablock= getMediaBlockHtml(media_id="#images.media_id#",size="105",displayAs="thumbTiny")>
													<div class="px-1 float-left py-1 bg-light border rounded" id="mediaBlock#images.media_id#" style="width: 100px;">
													#mediablock#
													</div>
												</cfif>
												<div class="col float-left px-2 px-md-1 mt-0">
													<h3 class="h5 mb-1"><a href="/grouping/showNamedCollection.cfm?underscore_collection_id=#namedGroups.underscore_collection_id#">#namedGroups.collection_name#</a></h3>

													<p class="mb-1 small">#namedGroups.ct# Cataloged Items</p>
													<p class="font-italic text-capitalize mb-0 smaller">Type: #namedGroups.underscore_collection_type#</p>
												</div>
											</div>
										</div>
									</div>
								</cfif>	
							</cfloop>
							</div>
						</div>
					</div>
				</div>
			</main>
		</div>
	</div>
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
