<!---
specimens/manageSpecimens.cfm

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

--->
<cfif NOT isdefined("action")>
	<cfset action = "manage">
</cfif>
<cfset pageTitle = "Manage Specimens">
<cfinclude template = "/shared/_header.cfm">

<cfif not isDefined("result_id") OR len(result_id) EQ 0>
	<cfthrow message = "No result_id provided to manage.">
</cfif>

<cfswitch expression="#action#">
	<cfcase value="manage">
		<cfquery name="results" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="results_result">
			SELECT count(distinct collection_object_id) ct
			FROM user_search_table
			WHERE result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
		</cfquery>
		<cfif results.ct EQ 0>
			<cfthrow message = "No results found in user's USER_SEARCH_TABLE for result_id #encodeForHtml(result_id)#.">
		</cfif>
		<cfoutput>
			<div class="container">
				<div class="row mb-4">
					<div class="col-12">
						<h1 class="h2">Manage Specimens [result_id=#encodeForHtml(result_id)#]</h1>
						<p>#results.ct# cataloged item records</p>
						<cfquery name="collections" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="collections_result">
							SELECT count(*) ct, collection_cde, collection_id
							FROM user_search_table
								left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat
							WHERE result_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#result_id#">
							GROUP BY collection_cde, collection_id
						</cfquery>
						<ul>
							<cfloop query="collections">
								<li>#collections.collection_cde# #collections.ct#	
								</li>
							</cfloop>
						</ul>
					</div>
				</div>
			</div>
		</cfoutput>
	</cfcase>
	<!---------------------------------------------------------------------------------------------------->
</cfswitch>

<cfinclude template="/shared/_footer.cfm">
