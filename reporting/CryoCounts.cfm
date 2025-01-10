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
<cfset pageTitle = "Cryogenic Collection Object Counts">
<cfinclude template="/shared/_header.cfm">

<script src="/lib/misc/sorttable.js"></script>
<cfoutput>
	<cfquery name="dp" datasource="uam_god">
		select decode(f.collection, 'Cryogenic', a.attribute_value,f.collection) as "Collection",count(distinct f.collection_object_id) as "number_of_cataloged_items",
		count(distinct co.collection_object_id) as "number_of_tissues_vials", sum(co.lot_count) as "sum_of_part_counts" 
		from flat f, specimen_part sp, coll_obj_cont_hist ch, coll_object co, 
		(select * from attributes a where attribute_type = 'Associated MCZ Collection') a, CTSPECIMEN_PART_NAME pn, 
		(select container.container_id, container.container_type, container.label, container.description, p.barcode, container.container_remarks 
		from container, container p 
		where container.parent_container_id=p.container_id (+) and container.container_type='collection object' 
		start with container.label like 'Cryovat%' 
		or container.label = 'Cryo_refrigerator-1'
		connect by container.parent_container_id = prior container.container_id) b where b.container_id = ch.container_id 
		and ch.collection_object_id = sp.collection_object_id and sp.DERIVED_FROM_CAT_ITEM = f.collection_object_id and sp.collection_object_id = co.collection_object_id 
		and sp.part_name = pn.part_name and f.collection_cde = pn.collection_cde and pn.is_tissue = 1 and f.collection_object_id = a.collection_object_id(+) 
		group by decode(f.collection, 'Cryogenic', a.attribute_value,f.collection) order by decode(f.collection, 'Cryogenic', a.attribute_value,f.collection)
	</cfquery>

	<main class="container" id="content">
		<section class="row"> 
			<div class="col-12">
				<h2 class="h3 mt-4 mx-2">Cryogenic Collection Count Summary</h2>
			</div>
			<div class="col-12">
				<table border id="t" class="sortable table table-responsive d-xl-table">
					<thead class="thead-light">
						<tr>
							<th>Collection</th>
							<th>Number of Cataloged Items</th>
							<th>Number of Tissue Vials</th>
							<th>Sum of Part Counts</th>
						</tr>
					</thead>
					<cfloop query="dp">
						<tbody>
							<tr>
								<td>#Collection#</td>
								<td>#number_of_cataloged_items#</td>
								<td>#number_of_tissues_vials#</td>
								<td>#sum_of_part_counts#</td>
							</tr>
						</tbody>
					</cfloop>
				</table>
			</div>
		</section>
	</main>
</cfoutput>

<cfinclude template="/shared/_footer.cfm">
