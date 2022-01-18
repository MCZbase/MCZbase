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
	<div class="container">
		<div class="row mx-0 mb-4">
			<h1 class="w-100 mt-45 px-2 mt-5 text-center">MCZ Featured Collections of Cataloged Items</h1>
			<div class="col-12 col-md-12 bg-light border rounded px-0 py-2 mb-3 float-left mt-1">
			<div class="col-12 col-md-3 float-left">
				<ul class="list-unstyled text-right px-0 pr-xl-0 pl-xl-3 mb-3 mt-0 bg-light">
					<cfloop query="types">
						<li class="my-3">
							<h3 class="mb-0 w-75 float-right"><a href="/grouping/index.cfm?underscore_collection_type=#types.underscore_collection_type#" class="text-dark">#types.underscore_collection_type#</a></h3>
							<p class="small90 text-muted w-75 float-right">#types.description#</p>
						</li>
					</cfloop>
					<div class="input-group w-auto float-right mt-2">
						<div class="form-outline">
							<input type="search" id="form1" class="data-entry-input" />
						</div>
						<button type="button" class="btn btn-xs btn-primary py-1"><i class="fas fa-search"></i></button>
					</div>
					<li class="mt-5 pt-3">
						<p class="font-italic text-dark w-75 mt-3 float-right">
							Placeholder text for overview of page....
						</p>
					</li>
				</ul>
			</div>
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
				<cfif len(#namedGroups.description#)gt 0>
					<div class="col-12 col-md-9 float-right my-2">
						<div class="border rounded bg-white py-3 col-12 px-3 float-left">
							<div class="row mx-0">
								<cfif len(images.media_id) gt 0>
									<cfset mediablock= getMediaBlockHtml(media_id="#images.media_id#",size="350",displayAs="thumbLg")>
									<div class="col-12 col-md-3 col-xl-2 float-left py-2 bg-light border rounded" id="mediaBlock#images.media_id#">
									#mediablock#
									</div>
<!---								<cfelse>
									<div class="col-12 col-md-3 col-xl-2 py-2 float-left bg-light border rounded">
										<a href="" class="d-block my-0 w-100 active text-center">
											<img src = "/shared/images/Image-x-generic.svg" class="mx-auto w-75">
										</a>
									</div>--->
								</cfif>
								<div class="col-12 col-md-9 col-xl-10 float-left mt-2">
									<h3><a href="/grouping/showNamedCollection.cfm?underscore_collection_id=#namedGroups.underscore_collection_id#">#namedGroups.collection_name#</a></h3>
									<p><cfif len(namedGroups.description) GT 50>
											<cfset namedGroups.description = "#left(namedGroups.description,50)#..." >
										</cfif>
									</p>
									<p>Includes #namedGroups.ct# Cataloged Items</p>
									<p class="font-italic text-capitalize">Collection Type: #namedGroups.underscore_collection_type#</p>
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
