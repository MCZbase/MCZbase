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
		count(cat_num) as cnt
	from
		collection,
		cataloged_item
	where
		collection.collection_id = cataloged_item.collection_id
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
	<main class=”container” id=”content”>
		<section class=”row” >
			<h1 class="h2">MCZbase Holdings</h1>
				<table border id="t" class="sortable">
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
						<th>
							<strong>Cataloged Items</strong>
						</th>
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
							<td><a href="/SpecimenSearch.cfm?collection_id=#collection_id#">#cnt#</a></td>
						</tr>
					</cfloop>
				</table>
		</section>
	</main>
</cfoutput>

<cfinclude template="/shared/_footer.cfm">
