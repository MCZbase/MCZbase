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
			<main class="col-12 col-md-12 bg-light border rounded px-2 py-2 mb-3 float-left mt-1">
<ul class="nav nav-tabs" id="myTab" role="tablist">
  <li class="nav-item" role="presentation">
    <button class="nav-link active" id="home-tab" data-bs-toggle="tab" data-bs-target="##home" type="button" role="tab" aria-controls="home" aria-selected="true">Home</button>
  </li>
  <li class="nav-item" role="presentation">
    <button class="nav-link" id="profile-tab" data-bs-toggle="tab" data-bs-target="##profile" type="button" role="tab" aria-controls="profile" aria-selected="false">Profile</button>
  </li>
  <li class="nav-item" role="presentation">
    <button class="nav-link" id="messages-tab" data-bs-toggle="tab" data-bs-target="##messages" type="button" role="tab" aria-controls="messages" aria-selected="false">Messages</button>
  </li>
  <li class="nav-item" role="presentation">
    <button class="nav-link" id="settings-tab" data-bs-toggle="tab" data-bs-target="##settings" type="button" role="tab" aria-controls="settings" aria-selected="false">Settings</button>
  </li>
</ul>

<div class="tab-content">
  <div class="tab-pane active" id="home" role="tabpanel" aria-labelledby="home-tab">...</div>
  <div class="tab-pane" id="profile" role="tabpanel" aria-labelledby="profile-tab">...</div>
  <div class="tab-pane" id="messages" role="tabpanel" aria-labelledby="messages-tab">...</div>
  <div class="tab-pane" id="settings" role="tabpanel" aria-labelledby="settings-tab">...</div>
</div>

<script>
  var firstTabEl = document.querySelector('#myTab li:last-child a')
  var firstTab = new bootstrap.Tab(firstTabEl)

  firstTab.show()
</script>
				<nav class="col-12 col-md-12 float-left w-100">
						<div class="input-group w-auto mt-2 position-absolute" style="right:.5rem;">
							<div class="form-outline">
								<input type="search" id="form1" class="data-entry-input py-1" />
							</div>
							<button type="button" class="btn btn-xs btn-primary py-0"><i class="fas fa-search"></i></button>
						</div>
					<ul class="nav nav-tabs w-100" id="NamedGroupTabs" role="tablist">
						<li class="nav-item mr-2" role="presentation">
							<button id="collection-tab" data-bs-toggle="tab" data-bs-target="##collection" type="button" role="tab" aria-controls="collection" aria-selected="true" class="nav-link active h3">Collection</button>
						</li>
						<li class="nav-item mr-2" role="presentation">
							<button id="expedition-tab" data-bs-toggle="tab" data-bs-target="##expedition" type="button" role="tab" aria-controls="expedition" aria-selected="false" class="nav-link h3">Expedition</button>
						</li>
						<li class="nav-item mr-2" role="presentation">
							<button id="grant-tab" data-bs-toggle="tab" data-bs-target="##grant" type="button" role="tab" aria-controls="grant" aria-selected="false" class="nav-link h3">Grant</button>
						</li>
						<li class="nav-item mr-2" role="presentation">
							<button id="workflow-tab" data-bs-toggle="tab" data-bs-target="##workflow" type="button" role="tab" aria-controls="workflow" aria-selected="false" class="nav-link h3">Workflow</button>
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
											<!---	<p>#namedGroups.description#</p>--->
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
											<!---	<p>#namedGroups.description#</p>--->
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
											<!---	<p>#namedGroups.description#</p>--->
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
			</main>
		</div>
	</div>
</cfoutput>
<script>
var triggerTabList = [].slice.call(document.querySelectorAll('#NamedGroupTabs a'))
triggerTabList.forEach(function (triggerEl) {
  var tabTrigger = new bootstrap.Tab(triggerEl)

  triggerEl.addEventListener('click', function (event) {
    event.preventDefault()
    tabTrigger.show()
  })
})	
var triggerFirstTabEl = document.querySelector('#NamedGroupTabs li:first-child a')
bootstrap.Tab.getInstance(triggerFirstTabEl).show() // Select first tab
</script>
<cfinclude template = "/shared/_footer.cfm">
