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
<cfoutput>

		<cfquery name="groups" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT
				collection_name, underscore_collection_id, description, underscore_collection_type,displayed_media_id
			FROM
				underscore_collection 
			ORDER BY collection_name
		</cfquery>
	<div class="container">
		<div class="row mx-0 mb-4">
			<h1 class="w-100 mt-45 px-2 mt-5 text-center">MCZ Featured Collections of Cataloged Items</h1>
			
			<div class="col-12 col-md-12 bg-light border px-0 py-2 mb-3 float-left mt-1">
			<div class="col-12 col-md-3 float-left">
				<ul class="list-unstyled text-right px-3 mb-3 mt-2 rounded border bg-light">
					<li class="my-3"><h3>Collections</h3></li>
					<li class="my-3"><h3>Expeditions</h3></li>
					<li class="my-3"><h3>Grants</h3></li>
					<li class="my-3"><h3>Teaching Collections</h3></li>
					<li class="mt-5"><p class="font-italic text-dark">The Museum of Comparative Zoology at Harvard University and Boston Harbor Islands Partnership have collaborated to conduct an All Taxa Biodiversity Inventory (ATBI) of Boston Harbor Islands National and State Park. The project focuses on the "microwilderness" of the islands, namely, insects and other invertebrates. This extremely diverse group of animals is easily sampled, yet often overlooked. Our goal is to combine scientific research with public education, and to foster an appreciation for the amazing biological diversity that exists within Boston Harbor.</p></li>
				</ul>
			</div>
			<cfloop query="groups">
				<cfquery name="images" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						displayed_media_id as media_id
					FROM
						underscore_relation 
					INNER JOIN underscore_collection
						on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
					WHERE rownum = 1 
					and underscore_relation.underscore_collection_id = #groups.underscore_collection_id#
				</cfquery>
				<cfif len(#groups.description#)gt 0>
					<div class="col-12 col-md-9 float-left my-2">
						<div class="border rounded bg-white py-3 col-12 px-3 float-left">
							<div class="row mx-0">
								<cfif len(images.media_id) gt 0>
									<cfset mediablock= getMediaBlockHtml(media_id="#images.media_id#",size="300",displayAs="thumb")>
									<div class="col-12 col-md-3 col-xl-2 float-left py-2 bg-light border rounded" id="mediaBlock#images.media_id#">
									#mediablock#
									</div>
								<cfelse>
									<div class="col-12 col-md-3 col-xl-2 py-2 float-left bg-light border rounded">
										<a href="" class="d-block my-0 w-100 active text-center">
											<img src = "/shared/images/Image-x-generic.svg" class="mx-auto w-75">
										</a>
									</div>
								</cfif>
								<div class="col-12 col-md-9 col-xl-10 float-left mt-2">
									<h3><a href="/grouping/showNamedCollection.cfm?underscore_collection_id=#groups.underscore_collection_id#">#groups.collection_name#</a></h3>
									<p>#groups.description#</p>
									<p><i>Collection Type: #groups.underscore_collection_type#</i></p>
								</div>
							</div>
						</div>
					</div>
				</cfif>
			</cfloop>
			</div>
		</div>
	</div>
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
