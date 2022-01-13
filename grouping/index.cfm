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
		<cfquery name="examples" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select distinct media_id from (
				select max(media_id) media_id from media
				group by mime_type, media_type
				union
				select max(media_id) media_id from media_relations
				group by media_relationship
				union
				select max(media_id) media_id from media
				group by media.auto_host
				having count(*) > 50
				union
				select max(media_id) from media_labels
				where media_label = 'height'
				group by label_value
				having count(*) > 1000
			)
		</cfquery>
		<div class="row">
			<cfloop query="examples">
				<div class="col-12 col-sm-6 col-md-4 col-xl-3">
					<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",size="400")>
					<div id="mediaBlock#media_id#">
					#mediablock#
					</div>
				</div>
			</cfloop>
		</div>
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
