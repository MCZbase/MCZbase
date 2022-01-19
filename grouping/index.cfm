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
				count(flat.collection_object_id) ct, 
				underscore_collection.collection_name, 
				underscore_collection.underscore_collection_id, underscore_collection.mask_fg,
				underscore_collection.description, underscore_collection.underscore_collection_type,
				underscore_collection.displayed_media_id
			FROM
				underscore_collection 
				LEFT JOIN underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
				LEFT JOIN<cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
					on underscore_relation.collection_object_id = flat.collection_object_id
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

				<nav class="col-12 col-md-12 float-left w-100">
						<div class="input-group w-auto mt-2 position-absolute" style="right:.5rem;">
							<div class="form-outline">
								<input type="search" id="form1" class="data-entry-input py-1" />
							</div>
							<button type="button" class="btn btn-xs btn-primary py-0"><i class="fas fa-search"></i></button>
						</div>
					<ul class="nav nav-tabs w-100">
						<cfloop query="types">
							<li class="nav-item mr-2">
								<h2 class="h3 mb-0">
									<a href="/grouping/index.cfm?underscore_collection_type=#types.underscore_collection_type#" class="nav-link active font-capitalize">#types.underscore_collection_type#</a></h2>
							<!---<p class="small90 text-muted w-75 float-right">#types.description#</p>--->
							</li>
						</cfloop>
					</ul>

				</nav>
				<section id="collection">
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
						and underscore_collection.underscore_collection_type = #underscorecollectiontype#
					</cfquery>
						<cfif len(#namedGroups.description#)gt 0>
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
				</section>
<!---				<section id="expedition">
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
							and underscore_collection_type = #expedition#
						</cfquery>
						<cfif len(#namedGroups.description#)gt 0>
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
				</section>
				<section id="grant">
					
				</section>
				<section id="workflow">
					
				</section>--->
			</main>
		</div>
	</div>
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
