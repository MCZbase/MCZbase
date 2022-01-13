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
				collection_name, underscore_collection_id
			FROM
				underscore_collection 
		</cfquery>
	<div class="container-fluid">
		<div class="row">
			<div class="col-12">
			<cfloop query="groups">
				<cfquery name="images" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						media_id
					FROM
						underscore_relation 
					INNER JOIN flat 
						on underscore_relation.collection_object_id = flat.collection_object_id
					INNER JOIN media_relations
						on media_relations.related_primary_key = flat.collection_object_id
					WHERE rownum = 1 and underscore_relation.underscore_collection_id = #groups.underscore_collection_id#
				</cfquery>
			
				<div class="col-12 float-left border rounded my-2">
					<cfset mediablock= getMediaBlockHtml(media_id="#images.media_id#",size="200")>
					<div class="col-3 px-0 float-left" id="mediaBlock#images.media_id#">
					#mediablock#
					</div>
					<div class="col-12 px-0"><h3>#groups.collection_name#</h3></div>
				</div>
			</cfloop>
			</div>
		</div>
	</div>
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
