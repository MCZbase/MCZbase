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
<cfquery name="namedGroups" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT 
				underscore_collection_id, mask_fg
			FROM
				underscore_collection
			WHERE mask_fg = 0
</cfquery>

<cfoutput>
	<main class="container">
		<div class="row">
			<div class="col-12 col-md-6 mt-4">
				<h1 class="h2">MCZ Featured Collections of Cataloged Items</h1>
				<ul>
					<cfloop query="namedGroups">
						<cfset mask="">
						<cfif isdefined("session.roles") AND listfindnocase(session.roles,"coldfusion_user") GT 0>
							<cfif namedGroups.mask_fg EQ 1>
								<cfset mask=" [Hidden]">
							</cfif>
						</cfif>
						<li><a href="/grouping/showNamedCollection.cfm?underscore_collection_id=#underscore_collection_id#">#collection_name#</a> (#ct#)#mask#</li>
						<div class="row">
								
								<div class="col-12 col-sm-6 col-md-4 col-xl-3">
									<cfset namedgroupblock= getNamedGroupBlockHtml(underscore_id="#underscore_collection_id#",size="400")>
									<div id="namedGroupBlock#underscore_collection_id#">
									#namedgroupblock#
									</div>
								</div>
						</div>
					</cfloop>
				</ul>
			</div>
		</div>
	</main>
</cfoutput>

<cfinclude template = "/shared/_footer.cfm">
