<!---
info/queryStats.cfm

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2026 President and Fellows of Harvard College

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
<!--- Historical counts of specimen and taxonomy searches, from uam_query.query_stats, which
	sys.SP_GET_QUERYSTATS filled from the legacy searches' result tables; it is no longer filled,
	so the page shows how current the numbers are. --->
<!----
create unique index u_query_stats_q_id on uam_query.query_stats (QUERY_ID) tablespace uam_idx_1;
create index query_stats_coll_q_id on uam_query.query_stats_coll (QUERY_ID) tablespace uam_idx_1;
create index query_stats_coll_coll_id on uam_query.query_stats_coll (collection_id) tablespace uam_idx_1;
create index query_stats_coll_c_date on uam_query.query_stats (create_date) tablespace uam_idx_1;

uam_query.query_stats: QUERY_ID, QUERY_TYPE VARCHAR2(10), CREATE_DATE, SUM_COUNT, USERNAME
uam_query.query_stats_coll: QUERY_ID, REC_COUNT, COLLECTION_ID
---->
<cfset pageTitle = "Query Statistics">
<cfinclude template="/shared/_header.cfm">
<!--- Each query is listed with the username that ran it, so this is for collection operations and administrators only. --->
<cfset variables.QUERY_STATS_ROLES = "collops,curatorial_associate,global_admin">
<!--- The table of individual queries is limited to this many rows, the most recent first. --->
<cfset variables.MAX_QUERY_ROWS = 5000>
<cfset variables.canSeeQueryStats = false>
<cfif isdefined("session.roles")>
	<cfloop list="#variables.QUERY_STATS_ROLES#" index="allowedRole">
		<cfif listfindnocase(session.roles, allowedRole)>
			<cfset variables.canSeeQueryStats = true>
		</cfif>
	</cfloop>
</cfif>
<cfif NOT variables.canSeeQueryStats>
	<cflocation url="/errors/forbidden.cfm" addtoken="false">
</cfif>
<!--- The search form posts to this page, as before this minimal redesign, rather than offering the GET
	parameters with execute=true that redesigned search pages take. --->
<cfparam name="form.action" default="nothing">
<cfparam name="form.query_type" default="">
<cfparam name="form.collection_id" default="">
<cfparam name="form.bdate" default="">
<cfparam name="form.edate" default="">
<cfset variables.action = form.action>
<cfset variables.query_type = form.query_type>
<cfset variables.collection_id = form.collection_id>
<cfset variables.bdate = form.bdate>
<cfset variables.edate = form.edate>
<cfif len(variables.bdate) GT 0 AND len(variables.edate) EQ 0>
	<cfset variables.edate = variables.bdate>
</cfif>

<cfquery name="dataRange" datasource="uam_god" result="dataRange_result">
	SELECT
		query_type,
		MIN(create_date) first_query,
		MAX(create_date) last_query,
		COUNT(*) query_count
	FROM uam_query.query_stats
	GROUP BY query_type
	ORDER BY query_type
</cfquery>

<cfoutput>
<main class="container-fluid" id="content">
	<cfif variables.action NEQ "showTable">
		<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="ctcollection_result">
			SELECT collection_id, collection
			FROM collection
			ORDER BY collection
		</cfquery>
		<section role="search">
			<div class="row mx-0 mb-2">
				<div class="search-box col-12 px-0">
					<div class="search-box-header">
						<h1 class="h3 text-white">Query Statistics</h1>
					</div>
					<div class="col-12 my-2">
						<form name="queryStatsForm" id="queryStatsForm" method="post" action="/info/queryStats.cfm">
							<input type="hidden" name="action" value="showTable">
							<div class="form-row">
								<div class="col-12 col-md-2">
									<label for="query_type" class="data-entry-label">Type</label>
									<select name="query_type" id="query_type" class="data-entry-select">
										<option value=""></option>
										<option value="specimen">specimen</option>
										<option value="taxa">taxonomy</option>
									</select>
								</div>
								<div class="col-12 col-md-4">
									<label for="collection_id" class="data-entry-label">Collection</label>
									<select name="collection_id" id="collection_id" class="data-entry-select" multiple="multiple" size="5">
										<cfloop query="ctcollection">
											<option value="#encodeForHtmlAttribute(ctcollection.collection_id)#">#encodeForHtml(ctcollection.collection)#</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 col-md-3">
									<label for="bdate" class="data-entry-label">Begin Date</label>
									<input type="text" name="bdate" id="bdate" class="data-entry-input" placeholder="yyyy-mm-dd">
								</div>
								<div class="col-12 col-md-3">
									<label for="edate" class="data-entry-label">End Date</label>
									<input type="text" name="edate" id="edate" class="data-entry-input" placeholder="yyyy-mm-dd">
								</div>
							</div>
							<div class="pt-2">
								<button type="submit" class="btn btn-xs btn-primary">Search</button>
								<button type="reset" class="btn btn-xs btn-warning">Reset</button>
							</div>
						</form>
						<script>
							$(document).ready(function() {
								$("##bdate").datepicker({ dateFormat: "yy-mm-dd" });
								$("##edate").datepicker({ dateFormat: "yy-mm-dd" });
							});
						</script>
					</div>
				</div>
			</div>
		</section>
	<cfelse>
		<cfquery name="summary" datasource="uam_god" result="summary_result">
			SELECT
				GROUPING(collection.collection) is_total,
				collection.collection,
				COUNT(*) query_count,
				SUM(uam_query.query_stats.sum_count) total_records,
				AVG(uam_query.query_stats.sum_count) mean_records,
				MIN(uam_query.query_stats.sum_count) min_records,
				MAX(uam_query.query_stats.sum_count) max_records
			FROM
				uam_query.query_stats
				LEFT JOIN uam_query.query_stats_coll ON uam_query.query_stats.query_id = uam_query.query_stats_coll.query_id
				LEFT JOIN collection ON uam_query.query_stats_coll.collection_id = collection.collection_id
			WHERE
				1 = 1
				<cfif len(variables.query_type) GT 0>
					AND uam_query.query_stats.query_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.query_type#">
				</cfif>
				<cfif len(variables.collection_id) GT 0>
					AND uam_query.query_stats_coll.collection_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_id#" list="yes">)
				</cfif>
				<cfif isDate(variables.bdate) AND isDate(variables.edate)>
					AND uam_query.query_stats.create_date >= to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#dateformat(variables.bdate,'yyyy-mm-dd')#">,'yyyy-mm-dd')
					AND uam_query.query_stats.create_date < to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#dateformat(variables.edate,'yyyy-mm-dd')#">,'yyyy-mm-dd') + 1
				</cfif>
			GROUP BY ROLLUP(collection.collection)
			ORDER BY GROUPING(collection.collection) DESC, collection.collection
		</cfquery>
		<cfquery name="queries" datasource="uam_god" result="queries_result">
			SELECT * FROM (
				SELECT
					uam_query.query_stats.query_id,
					uam_query.query_stats.username,
					uam_query.query_stats.query_type,
					uam_query.query_stats.create_date,
					uam_query.query_stats.sum_count,
					collection.collection,
					uam_query.query_stats_coll.rec_count
				FROM
					uam_query.query_stats
					LEFT JOIN uam_query.query_stats_coll ON uam_query.query_stats.query_id = uam_query.query_stats_coll.query_id
					LEFT JOIN collection ON uam_query.query_stats_coll.collection_id = collection.collection_id
				WHERE
					1 = 1
					<cfif len(variables.query_type) GT 0>
						AND uam_query.query_stats.query_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.query_type#">
					</cfif>
					<cfif len(variables.collection_id) GT 0>
						AND uam_query.query_stats_coll.collection_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_id#" list="yes">)
					</cfif>
					<cfif isDate(variables.bdate) AND isDate(variables.edate)>
						AND uam_query.query_stats.create_date >= to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#dateformat(variables.bdate,'yyyy-mm-dd')#">,'yyyy-mm-dd')
						AND uam_query.query_stats.create_date < to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#dateformat(variables.edate,'yyyy-mm-dd')#">,'yyyy-mm-dd') + 1
					</cfif>
				ORDER BY uam_query.query_stats.create_date DESC, uam_query.query_stats.query_id DESC
			)
			WHERE rownum <= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.MAX_QUERY_ROWS#">
		</cfquery>
		<section class="row mx-0 my-2">
			<div class="col-12">
				<h1 class="h2">Query Statistics</h1>
				<a href="/info/queryStats.cfm" class="btn btn-xs btn-warning">Back to the search form</a>
				<p class="mt-2 mb-0">
					<cfif len(variables.query_type) GT 0>Type: #encodeForHtml(variables.query_type)#.<cfelse>All types.</cfif>
					<cfif len(variables.collection_id) GT 0>Selected collections only.<cfelse>All collections.</cfif>
					<cfif isDate(variables.bdate) AND isDate(variables.edate)>
						From #dateformat(variables.bdate,'yyyy-mm-dd')# to #dateformat(variables.edate,'yyyy-mm-dd')#.
					<cfelse>
						All dates.
					</cfif>
				</p>
			</div>
		</section>
		<section class="row mx-0 my-2">
			<div class="col-12">
				<h2 class="h3">Summary</h2>
				<p class="small mb-1">A query searching more than one collection is counted once for each collection.</p>
				<table class="sortable table table-responsive d-xl-table table-striped">
					<thead class="thead-light">
						<tr>
							<th scope="col">Collection</th>
							<th scope="col">Queries</th>
							<th scope="col">Total records</th>
							<th scope="col">Mean records/query</th>
							<th scope="col">Minimum records/query</th>
							<th scope="col">Maximum records/query</th>
						</tr>
					</thead>
					<tbody>
						<cfloop query="summary">
							<cfif summary.is_total EQ 1>
								<cfset variables.collectionLabel = "All">
							<cfelseif len(summary.collection) EQ 0>
								<cfset variables.collectionLabel = "(no collection)">
							<cfelse>
								<cfset variables.collectionLabel = summary.collection>
							</cfif>
							<tr>
								<td>#encodeForHtml(variables.collectionLabel)#</td>
								<td>#numberFormat(summary.query_count)#</td>
								<td>#numberFormat(val(summary.total_records))#</td>
								<td>#numberFormat(round(val(summary.mean_records)))#</td>
								<td>#numberFormat(val(summary.min_records))#</td>
								<td>#numberFormat(val(summary.max_records))#</td>
							</tr>
						</cfloop>
					</tbody>
				</table>
			</div>
		</section>
		<section class="row mx-0 my-2">
			<div class="col-12">
				<h2 class="h3">Queries</h2>
				<p class="small mb-1">The #numberFormat(variables.MAX_QUERY_ROWS)# most recent rows at most; #numberFormat(queries.recordcount)# shown.</p>
				<table class="sortable table table-responsive d-xl-table table-striped">
					<thead class="thead-light">
						<tr>
							<th scope="col">ID</th>
							<th scope="col">Username</th>
							<th scope="col">Type</th>
							<th scope="col">Date</th>
							<th scope="col">Total</th>
							<th scope="col">Collection</th>
							<th scope="col">Collection Count</th>
						</tr>
					</thead>
					<tbody>
						<cfloop query="queries">
							<tr>
								<td>#encodeForHtml(queries.query_id)#</td>
								<td>#encodeForHtml(queries.username)#</td>
								<td>#encodeForHtml(queries.query_type)#</td>
								<td>#dateformat(queries.create_date,"yyyy-mm-dd")#</td>
								<td>#encodeForHtml(queries.sum_count)#</td>
								<td>#encodeForHtml(queries.collection)#</td>
								<td>#encodeForHtml(queries.rec_count)#</td>
							</tr>
						</cfloop>
					</tbody>
				</table>
			</div>
		</section>
	</cfif>
	<section class="row mx-0 mt-2 mb-4">
		<div class="col-12">
			<h2 class="h3">Data Available</h2>
			<p class="small mb-1">Query statistics are no longer being recorded; these are the dates of the first and last recorded queries.</p>
			<table class="table table-responsive d-xl-table">
				<thead class="thead-light">
					<tr>
						<th scope="col">Type</th>
						<th scope="col">First Query</th>
						<th scope="col">Last Query</th>
						<th scope="col">Queries</th>
					</tr>
				</thead>
				<tbody>
					<cfloop query="dataRange">
						<tr>
							<td>#encodeForHtml(dataRange.query_type)#</td>
							<td>#dateformat(dataRange.first_query,"yyyy-mm-dd")#</td>
							<td>#dateformat(dataRange.last_query,"yyyy-mm-dd")#</td>
							<td>#numberFormat(dataRange.query_count)#</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</div>
	</section>
</main>
<script src="/lib/misc/sorttable.js"></script>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
