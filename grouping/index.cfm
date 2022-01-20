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
<div class="w-100">
<h1 class="px-2 mt-5 mb-0 text-center h2">MCZ Featured Collections of Cataloged Items</h1>		
</div>
<div class="container-fluid">
<div class="row mx-0 mb-4">
	<div class="col-10 mx-auto">
	<p class="text-dark mt-1 text-justified small90 mb-1">The Museum of Comparative Zoology (MCZ) contains over 21-million specimens in ten research collections that comprise one of the world's richest and most varied resources for studying the diversity of life. The museum serves as the primary repository for zoological specimens collected by past and present Harvard faculty-curators, staff, and associates conducting research around the world. The public can see a small percentage of our holdings on display at the Harvard Museum of Natural History, but visitors can also browse MCZ specimens and metadata online via our Featured Collections.</p>
	</div>	
	<cfoutput>
		<main class="col-12 col-md-12 px-2 py-2 mb-3 float-left mt-1">
			<div class="container mt-2">
				<div class="tabs card-header tab-card-header px-2 pt-3">
					<!-- Nav tabs -->
					<ul class="nav nav-tabs">
						<li class="nav-item mr-1">
						<a class="nav-link active" href="##home">Collection</a>
						</li>
						<li class="nav-item mx-1">
						<a class="nav-link" href="##menu1">Expedition</a>
						</li>
						<li class="nav-item mx-1">
						<a class="nav-link" href="##menu2">Grant</a>
						</li>
						<li class="nav-item mx-1">
						<a class="nav-link" href="##menu3">Workflow</a>
						</li>
					</ul>
					<!-- Tab panes -->
					<div class="tab-content border flex-wrap d-flex mb-1">
						<div id="home" class="container-fluid tab-pane active"><br>
							<h3 class="h4 px-2">Collections</h3>
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
									<div class="col-12 col-md-3 float-left float-left px-1 mt-1 mb-1">
										<div class="border rounded bg-white p-2 col-12 float-left" style="min-height:116px">
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
						<div id="menu1" class="container tab-pane fade"><br>
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
									<div class="col-12 col-md-3 float-left d-flex flex-wrap px-1 mt-2 mb-1">
										<div class="border rounded bg-white p-2 col-12 float-left" style="min-height:116px">
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
						<div id="menu2" class="container tab-pane fade"><br>
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
								<div class="col-12 col-md-3 float-left d-flex flex-wrap px-1 mt-2 mb-1">
									<div class="border rounded bg-white p-2 col-12 float-left" style="min-height:116px">
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
						<div id="menu3" class="container tab-pane fade"><br>
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
					</div>
				</div>
			</div>
		</main>
		<script>
		$(document).ready(function(){
		  $(".nav-tabs a").click(function(){
			$(this).tab('show');
		  });
		  $('.nav-tabs a').on('shown.bs.tab', function(event){
			var x = $(event.target).text();         // active tab
			var y = $(event.relatedTarget).text();  // previous tab
			$(".act span").text(x);
			$(".prev span").text(y);
		  });
		});
		</script>
	</cfoutput>
</div>
</div>

<cfinclude template = "/shared/_footer.cfm">
