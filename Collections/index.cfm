<cfset pageTitle = "MCZbase Holdings">
<!--
/Collections/index.cfm

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2021 President and Fellows of Harvard College

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
<cfset metaDesc="Links to individual collections web pages and loan policy.">
<cfinclude template = "/shared/_header.cfm">
<script src="/includes/sorttable.js"></script>

<cfquery name="colls" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="colls_result">
	select
		collection.collection,
		collection.collection_id,
		descr,
		web_link,
		web_link_text,
		loan_policy_url,
		count(filtered_flat.collection_object_id) as cnt
		<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
			,count(flat.collection_object_id) as internal_count
		</cfif>
	from
		collection 
		left join filtered_flat on collection.collection_id = filtered_flat.collection_id
		<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
			left join filtered_flat on collection.collection_id = filtered_flat.collection_id
		</cfif>
	where
		collection.collection_id is not null
	group by
		collection.collection,
		collection.collection_id,
		descr,
		web_link,
		web_link_text,
		loan_policy_url
	order by collection.collection
</cfquery>
<cfoutput>
	<main class="container my-3" id="content">
		<section class="row" >
			<div class="col-12">
				<h1 class="h2">MCZbase Holdings</h1>
				<table class="table table-responsive table-striped d-lg-table sortable" id="t">
					<tr>
						<th>
							<strong>Collection</strong>
						</th>
						<th>
							<strong>Description</strong>
						</th>
						<th>
							<strong>Website</strong>
						</th>
						<th>
							<strong>Loan Policy</strong>
						</th>
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
							<th>
								<strong>Cataloged Items</strong>
							</th>
							<th>
								<strong>Accessible to Public</strong>
							</th>
						<cfelse>
							<th>
								<strong>Cataloged Items</strong>
							</th>
						</cfif>
					</tr>
					<cfloop query="colls">
						<tr>
							<td>#COLLECTION#</td>
							<td>#DESCR#</td>
							<td>
								<cfif len(#WEB_LINK#) gt 0 and len(#WEB_LINK_TEXT#) gt 0>
									<a href="#WEB_LINK#" target="_blank">#WEB_LINK_TEXT#</a>
								<cfelse>
									<a href="https://mcz.harvard.edu/" target="_blank">MCZ</a>
								</cfif>
							</td>
							<td>
								<cfif len(#loan_policy_url#) gt 0 and len(#loan_policy_url#) gt 0>
									<a href="#loan_policy_url#" target="_blank">Loan Policy</a>
								<cfelse>
									Inquire
								</cfif>
							</td>
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
								<td><a href="/SpecimenSearch.cfm?collection_id=#collection_id#">#internal_count#</a></td>
								<td><a href="/SpecimenSearch.cfm?collection_id=#collection_id#">#cnt#</a></td>
							<cfelse>
								<td><a href="/SpecimenSearch.cfm?collection_id=#collection_id#">#cnt#</a></td>
							</cfif>
						</tr>
					</cfloop>
				</table>
			</div>
		</section>
	</main>
</cfoutput>

<cfinclude template="/shared/_footer.cfm">
