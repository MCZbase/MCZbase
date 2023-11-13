<cfset pageTitle = "MCZbase Holdings">
<!--
/collections/index.cfm

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
<script src="/lib/misc/sorttable.js"></script>

<cfquery name="colls" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="colls_result">
	select
		collection.collection,
		collection.collection_id,
		descr,
		web_link,
		web_link_text,
		loan_policy_url
	from
		collection 
	where
		collection.collection_id is not null
	order by collection.collection
</cfquery>
<cfoutput>
	<main class="container-lg mx-auto my-3" id="content">
		<section class="row" >
			<div class="col-12 mt-3">
				<h1 class="h2 px-2">MCZbase Holdings</h1>
				<table class="table table-responsive table-striped d-lg-table sortable" id="t">
					<thead>
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
								<strong>Collection Policies</strong>
							</th>
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
								<th>
									<strong>Cataloged Items</strong>
								</th>
								<th>
									<strong>Accessible to Public</strong>
								</th>
								<th>
									<strong>Encumbered</strong>
								</th>
							<cfelse>
								<th>
									<strong>Cataloged Items</strong>
								</th>
							</cfif>
						</tr>
					</thead>
					<cfset totalinternal = 0>
					<cfset totalpublic = 0>
					<tbody>
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
										<a href="#loan_policy_url#" target="_blank">Collection Policies</a>
									<cfelse>
										&nbsp;
									</cfif>
								</td>
								<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
									<cfquery name="caticount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="colls_result">
										select count(*) as internal_count from flat where collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#colls.collection_id#">
									</cfquery>
									<cfset icount = caticount.internal_count>
									<cfset totalinternal = totalinternal + icount>
									<td><a href="/Specimens.cfm?execute=true&action=fixedSearch&collection_id=#collection_id#">#icount#</a></td>
	
									<cfquery name="catcount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="colls_result">
										select count(*) as cnt from filtered_flat where collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#colls.collection_id#">
									</cfquery>
									<cfset pcount = catcount.cnt>
									<cfset totalpublic = totalpublic + pcount>
									<td><a href="/Specimens.cfm?execute=true&action=fixedSearch&collection_id=#collection_id#">#pcount#</a></td>
	
									<td>#icount-pcount#</td>
								<cfelse>
									<cfquery name="catcount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="colls_result">
										select count(*) as cnt from filtered_flat where collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#colls.collection_id#">
									</cfquery>
									<td><a href="/Specimens.cfm?execute=true&action=fixedSearch&collection_id=#collection_id#">#catcount.cnt#</a></td>
									<cfset totalpublic = totalpublic + catcount.cnt>
								</cfif>
							</tr>
						</cfloop>
					</tbody>
					<tfoot>
						<tr>
							<td>&nbsp;</td>
							<td>&nbsp;</td>
							<td>&nbsp;</td>
							<td>Total</td>
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
								<td>#totalinternal#</td>
								<td>#totalpublic#</td>
								<td>#totalinternal-totalpublic#</td>
							<cfelse>
								<td>#totalpublic#</td>
							</cfif>
						</tr>
					</tfoot>
				</table>
			</div>
			<div class="col-12">
				<p class="px-2">All names in MCZbase are disclaimed for nomenclatural purposes.</p>
			</div>
		</section>
	</main>
</cfoutput>

<cfinclude template="/shared/_footer.cfm">
