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
	<cfset action="fixedSearch">
</cfif>
<cfswitch expression="#action#">
	<cfcase value="fixedSearch">
		<cfset pageTitle = "Collections Featured">
		<cfif isdefined("execute")>
			<cfset execute="fixed">
		</cfif>
	</cfcase>
	<cfcase value="keywordSearch">
		<cfset pageTitle = "Specimen Search by Keyword">
		<cfif isdefined("execute")>
			<cfset execute="keyword">
		</cfif>
	</cfcase>
	<cfcase value="builderSearch">
		<cfset pageTitle = "Specimen Search Builder">
		<cfif isdefined("execute")>
			<cfset execute="builder">
		</cfif>
	</cfcase>
	<cfdefaultcase>
		<cfset pageTitle = "Basic Specimen Search">
		<cfif isdefined("execute")>
			<cfset execute="fixed">
		</cfif>
	</cfdefaultcase>
</cfswitch>
<cfinclude template = "/shared/_header.cfm">
<cfinclude template="/grouping/component/search.cfc" runOnce="true">
<cfinclude template="/media/component/search.cfc" runOnce="true">
<cfoutput>
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
	<div class="w-100">
		<h1 class="px-2 mt-4 mb-2 text-center">MCZ Featured Collections of Cataloged Items</h1>		
	</div>

	<div class="container-fluid">
		<div class="row mx-0 mb-4">
			<p class="font-italic text-dark w-75 mt-3 text-center">Placeholder text for overview of page....</p>
			<cfoutput>
			<main class="col-12 col-md-12 bg-light border rounded px-2 py-2 mb-3 float-left mt-1">
					<div class="tabs card-header tab-card-header px-2 pt-3">
						<cfswitch expression="#action#">
							<cfcase value="fixedSearch">
								<cfset fixedTabActive = "active">
								<cfset fixedTabShow = "">
								<cfset keywordTabActive = "">
								<cfset keywordTabShow = "hidden">
								<cfset builderTabActive = "">
								<cfset builderTabShow = "hidden">
								<cfset fixedTabAria = "aria-selected=""true"" tabindex=""0"" ">
								<cfset keywordTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset builderTabAria = "aria-selected=""false"" tabindex=""-1"" ">
							</cfcase>
							<cfcase value="keywordSearch">
								<cfset fixedTabActive = "">
								<cfset fixedTabShow = "hidden">
								<cfset keywordTabActive = "active">
								<cfset keywordTabShow = "">
								<cfset builderTabActive = "">
								<cfset builderTabShow = "hidden">
								<cfset fixedTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset keywordTabAria = "aria-selected=""true"" tabindex=""0"" ">
								<cfset builderTabAria = "aria-selected=""false"" tabindex=""-1"" ">
							</cfcase>
							<cfcase value="builderSearch">
								<cfset fixedTabActive = "">
								<cfset fixedTabShow = "hidden">
								<cfset keywordTabActive = "">
								<cfset keywordTabShow = "hidden">
								<cfset builderTabActive = "active">
								<cfset builderTabShow = "">
								<cfset fixedTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset keywordTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset builderTabAria = "aria-selected=""true"" tabindex=""0"" ">
							</cfcase>
							<cfdefaultcase>
								<cfset fixedTabActive = "active">
								<cfset fixedTabShow = "">
								<cfset keywordTabActive = "">
								<cfset keywordTabShow = "hidden">
								<cfset builderTabActive = "">
								<cfset builderTabShow = "hidden">
								<cfset fixedTabAria = "aria-selected=""true"" tabindex=""0"" ">
								<cfset builderTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset keywordTabAria = "aria-selected=""false"" tabindex=""-1"" ">
							</cfdefaultcase>
						</cfswitch>
						<div class="tab-headers tabList" role="tablist" aria-label="search panel tabs">
							<button class="col-12 col-md-auto px-md-5 my-1 my-md-0 #fixedTabActive#" id="1" role="tab" aria-controls="fixedSearchPanel" #fixedTabAria#>Basic Search</button>
							<button class="col-12 col-md-auto px-md-5 my-1 my-md-0 #keywordTabActive#" id="2" role="tab" aria-controls="keywordSearchPanel" #keywordTabAria# >Keyword Search</button>
							<button class="col-12 col-md-auto px-md-5 my-1 my-md-0 #builderTabActive#" id="3" role="tab" aria-controls="builderSearchPanel" #builderTabAria# aria-label="search builder tab">Search Builder</button>
						</div>
						<div class="tab-content">
							<!---Fixed Search tab panel--->
							<div id="fixedSearchPanel" role="tabpanel" aria-labelledby="1" tabindex="0" class="mx-0 #fixedTabActive# unfocus"  #fixedTabShow#>
								<section  class="container-fluid">
									one
								</section>
						
							</div><!--- end fixed search tab --->
	
							<!---Keyword Search/results tab panel--->
							<div id="keywordSearchPanel" role="tabpanel" aria-labelledby="2" tabindex="-1" class="unfocus mx-0 #keywordTabActive#" #keywordTabShow#>
								
								<section  class="container-fluid">
								two
								
								</section>
			
							</div><!--- end keyword search/results panel --->
	
								<!---Query Builder tab panel--->
							<div id="builderSearchPanel" role="tabpanel" aria-labelledby="3" tabindex="-1" class="mx-0 #builderTabActive# unfocus"  #builderTabShow#>
								<section  class="container-fluid">
									three
								</section>
								<!--- results for search builder search --->
						
							</div><!--- end search builder tab --->
						</div>
					</div>
				</div>
			</div>
		</main>
</cfoutput>
		</div>
	</div>
<!---				<nav class="col-12 col-md-12 float-left w-100">
						<div class="input-group w-auto mt-2 position-absolute" style="right:.5rem;">
							<div class="form-outline">
								<input type="search" id="form1" class="data-entry-input py-1" />
							</div>
							<button type="button" class="btn btn-xs btn-primary py-0"><i class="fas fa-search"></i></button>
						</div>
					<ul class="nav nav-tabs w-100" id="NamedGroupTabs" role="tablist">
						<li class="nav-item mr-2" role="presentation">
							<a href="##collection" id="collection" data-bs-toggle="tab" data-bs-target="##collection" type="button" role="tab" aria-controls="collection" aria-selected="true" class="nav-link active h3">Collection</a>
						</li>
						<li class="nav-item mr-2" role="presentation">
							<a href="##expedition" id="expedition" data-bs-toggle="tab" data-bs-target="##expedition" type="button" role="tab" aria-controls="expedition" aria-selected="false" class="nav-link h3">Expedition</a>
						</li>
						<li class="nav-item mr-2" role="presentation">
							<a href="##grant" id="grant" data-bs-toggle="tab" data-bs-target="##grant" type="button" role="tab" aria-controls="grant" aria-selected="false" class="nav-link h3">Grant</a>
						</li>
						<li class="nav-item mr-2" role="presentation">
							<a id="workflow-tab" data-bs-toggle="tab" data-bs-target="##workflow" type="button" role="tab" aria-controls="workflow" aria-selected="false" class="nav-link h3">Workflow</button>
						</li>
					</ul>

				</nav>
				<section class="tab-content" id="NamedGroupTabContent">
					<div id="collection" class="tab-pane fade show active" role="tabpanel" aria-labelledby="collection-tab">
						<cfset underscorecollectiontype='collection'>
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
								<div class="col-12 col-md-3 float-left d-flex flex-wrap px-1 mt-2 mb-1">
									<div class="border rounded bg-white py-2 col-12 px-2 float-left">
										<div class="row h-25 mx-0">
											<cfif len(images.media_id) gt 0>
												<cfset mediablock= getMediaBlockHtml(media_id="#images.media_id#",size="105",displayAs="thumbTiny")>
												<div class="px-1 float-left py-1 bg-light border rounded" id="mediaBlock#images.media_id#" style="width: 100px;">
												#mediablock#
												</div>
											</cfif>
											<div class="col float-left mt-2">
												<h3 class="h5"><a href="/grouping/showNamedCollection.cfm?underscore_collection_id=#namedGroups.underscore_collection_id#">#namedGroups.collection_name#</a></h3>
												<p>#namedGroups.description#</p>
												<p class="mb-1 small">Includes #namedGroups.ct# Cataloged Items</p>
												<p class="font-italic text-capitalize mb-0 small">Collection Type: #namedGroups.underscore_collection_type#</p>
											</div>
										</div>
									</div>
								</div>
							</cfif>
						</cfloop>
					</div>
					<div id="expedition" class="tab-pane fade" role="tabpanel" aria-labelledby="expedition-tab">
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
								<div class="col-12 col-md-3 float-left d-flex flex-wrap px-1 mt-2 mb-1">
									<div class="border rounded bg-white py-2 col-12 px-2 float-left">
										<div class="row h-25 mx-0">
											<cfif len(images.media_id) gt 0>
												<cfset mediablock= getMediaBlockHtml(media_id="#images.media_id#",size="105",displayAs="thumbTiny")>
												<div class="px-1 float-left py-1 bg-light border rounded" id="mediaBlock#images.media_id#" style="width: 100px;">
												#mediablock#
												</div>
											</cfif>
											<div class="col float-left mt-2">
												<h3 class="h5"><a href="/grouping/showNamedCollection.cfm?underscore_collection_id=#namedGroups.underscore_collection_id#">#namedGroups.collection_name#</a></h3>
												<p>#namedGroups.description#</p>
												<p class="mb-1 small">Includes #namedGroups.ct# Cataloged Items</p>
												<p class="font-italic text-capitalize mb-0 small">Collection Type: #namedGroups.underscore_collection_type#</p>
											</div>
										</div>
									</div>
								</div>
							</cfif>
						</cfloop>
					</div>
					<div id="grant" class="tab-pane fade" role="tabpanel" aria-labelledby="grant-tab">
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
								<div class="col-12 col-md-3 float-left d-flex flex-wrap px-1 mt-2 mb-1">
									<div class="border rounded bg-white py-2 col-12 px-2 float-left" style="min-height:110">
										<div class="row h-25 mx-0">
											<cfif len(images.media_id) gt 0>
												<cfset mediablock= getMediaBlockHtml(media_id="#images.media_id#",size="105",displayAs="thumbTiny")>
												<div class="px-1 float-left py-1 bg-light border rounded" id="mediaBlock#images.media_id#" style="width: 100px;">
												#mediablock#
												</div>
											</cfif>
											<div class="col float-left mt-2">
												<h3 class="h5"><a href="/grouping/showNamedCollection.cfm?underscore_collection_id=#namedGroups.underscore_collection_id#">#namedGroups.collection_name#</a></h3>
												<p class="mb-1 small">Includes #namedGroups.ct# Cataloged Items</p>
												<p class="font-italic text-capitalize mb-0 small">Collection Type: #namedGroups.underscore_collection_type#</p>
											</div>
										</div>
									</div>
								</div>
							</cfif>
						</cfloop>
					</div>
					<div id="workflow" class="tab-content" class="tab-pane fade" role="tabpanel" aria-labelledby="workflow-tab">
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
								<div class="col-12 col-md-3 float-left d-flex flex-wrap px-1 mt-2 mb-1">
									<div class="border rounded bg-white py-2 col-12 px-2 float-left">
										<div class="row h-25 mx-0">
											<cfif len(images.media_id) gt 0>
												<cfset mediablock= getMediaBlockHtml(media_id="#images.media_id#",size="105",displayAs="thumbTiny")>
												<div class="px-1 float-left py-1 bg-light border rounded" id="mediaBlock#images.media_id#" style="width: 100px;">
												#mediablock#
												</div>
											</cfif>
											<div class="col float-left mt-2">
												<h3 class="h5"><a href="/grouping/showNamedCollection.cfm?underscore_collection_id=#namedGroups.underscore_collection_id#">#namedGroups.collection_name#</a></h3>
											
												<p class="mb-1 small">Includes #namedGroups.ct# Cataloged Items</p>
												<p class="font-italic text-capitalize mb-0 small">Collection Type: #namedGroups.underscore_collection_type#</p>
											</div>
										</div>
									</div>
								</div>
							</cfif>	
						</cfloop>
					</div>
				</section>
			</main>--->

<cfinclude template = "/shared/_footer.cfm">
