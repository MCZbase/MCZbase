<!--
 partusage.cfm

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
<cfset pageTitle = "Part Usage by Type">
<cfinclude template="/shared/_header.cfm">

<script src="/lib/misc/sorttable.js"></script>
<cfoutput>
	<cfquery name="p" datasource="uam_god">
		select
			collection.collection, 
			collection.collection_id, 
			specimen_part.part_name,
			count(distinct(cataloged_item.collection_object_id)) cnt,
			ctspecimen_part_name.is_tissue
		from
			specimen_part
			left outer join ctspecimen_part_name on specimen_part.part_name=ctspecimen_part_name.part_name
			left outer join cataloged_item on specimen_part.derived_from_cat_item=cataloged_item.collection_object_id
			left outer join collection on cataloged_item.collection_id=collection.collection_id 
		where
			specimen_part.part_name is not null
		group by
			collection.collection, 
			collection.collection_id, 
			specimen_part.part_name,
			ctspecimen_part_name.is_tissue
		order by upper(specimen_part.part_name), collection.collection
	</cfquery>
	<cfquery name="dp" dbtype="query">
		select part_name from p group by part_name
	</cfquery>
	<main class="container" id="content">
		<section class="row"> 
			<div class="col-12">
				<h2 class="h3">Distribution of Part name usage by collection.</h2>
				<p>Summary of use of <a href="/vocabularies/ControlledVocabulary.cfm?table=CTSPECIMEN_PART_NAME">Specimen Part Names</a>, with <em>is Tissue</em> codings with counts of part name by collection and links to specimens.</p>
			</div>
			<div class="col-12">
				<table border id="t" class="sortable table table-responsive d-xl-table">
					<tr>
						<th>Part</th>
						<th>is Tissue</th>
						<th>sum</th>
						<th>Used By Collections</th>
					</tr>
					<cfloop query="dp">
						<!--- determine if this part name is consistently, or inconsistently used or not used as a tissue --->
						<cfquery name="it" dbtype="query">
							select is_tissue 
							from p 
							where part_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#dp.part_name#">
							group by is_tissue
						</cfquery>
						<cfif it.recordcount gt 1>
							<cfset tiss='sometimes'>
						<cfelseif it.is_tissue is 1>
							<cfset tiss='yes'>
						<cfelseif it.is_tissue is 0>
							<cfset tiss='no'>
						<cfelse>
							<cfset tiss='FAIL'>
						</cfif>
						<!--- obtain summary by collection counts --->
						<cfquery name="cp" dbtype="query">
							select collection,collection_id,cnt 
							from p 
							where part_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#dp.part_name#">
							group by collection,collection_id,cnt
						</cfquery>
						<cfquery name="tc" dbtype="query">
							select sum(cnt) sc from cp
						</cfquery>
						<tr>
							<td>#part_name#</td>
							<td>#tiss#</td>
							<td>#tc.sc#</td>
							<td>
								<cfloop query="cp">
									<a href="/SpecimenResults.cfm?collection_id=#collection_id#&part_name==#dp.part_name#">#collection#: #cnt#</a><br>
								</cfloop>
							</td>
						</tr>
					</cfloop>
				</table>
			</div>
		</section>
	</main>
</cfoutput>

<cfinclude template="/shared/_footer.cfm">
