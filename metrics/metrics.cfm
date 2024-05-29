<!--

* /metrics/metrics.cfm

Copyright 2024 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

* Basic annual report/date range metrics for collections/grants/etc.

-->
<cfset pageTitle="Basic Metrics">
<cfinclude template="/shared/_header.cfm">
<cfinclude template = "/shared/component/functions.cfc">

<!-- code goes here -->
<!-- set default time frame to the past 12 months -->

<!-- cfset endDate = "SYSDATE" -->
<!-- cfset beginDate = "ADD_MONTHS(SYSDATE,-12)" -->

<cfset endDate = "2023-07-01">
<cfset beginDate = "2022-06-30">

<!-- annual report queries -->
<cfquery name="totals" datasource="uam_god">
select 
	h.collection, 
	h.catalogeditems, 
	h.specimens, 
	p.primaryCatItems, 
	p.primaryspecimens, 
	s.secondaryCatItems, 
	s.secondarySpecimens, 
	a.receivedCatItems,
	a.receivedSpecimens,
	e.enteredCatItems,
	e.enteredSpecimens
	  
from 
(select f.collection_id, f.collection, count(distinct f.collection_object_id) catalogeditems, sum(decode(total_parts,null, 1,total_parts)) specimens
        from flat f
        join coll_object co on f.collection_object_id = co.collection_object_id
        where co.COLL_OBJECT_ENTERED_DATE < to_date('#endDate#', 'YYYY-MM-DD')
        group by f.collection_id, f.collection) h
left join  ( select f.collection_id, f.collection, ts.CATEGORY, count(distinct f.collection_object_id) primaryCatItems, sum(decode(total_parts,null, 1,total_parts)) primarySpecimens
        from coll_object co
        join flat f on co.collection_object_id = f.collection_object_id
        join citation c on f.collection_object_id = c.collection_object_id
        join ctcitation_type_status ts on c.type_status =  ts.type_status
        where ts.CATEGORY in ('Primary')
        and co.COLL_OBJECT_ENTERED_DATE <  to_date('#endDate#', 'YYYY-MM-DD')
        group by f.collection_id, f.collection, ts.CATEGORY) p on h.collection_id = p.collection_id
left join (select f.collection_id, f.collection, ts.CATEGORY, count(distinct f.collection_object_id) secondaryCatItems, sum(decode(total_parts,null, 1,total_parts)) secondarySpecimens
        from coll_object co
        join flat f on co.collection_object_id = f.collection_object_id
        join citation c on f.collection_object_id = c.collection_object_id
        join ctcitation_type_status ts on c.type_status =  ts.type_status
        where ts.CATEGORY in ('Secondary')
        and co.COLL_OBJECT_ENTERED_DATE <  to_date('#endDate#', 'YYYY-MM-DD')
        group by f.collection_id, f.collection, ts.CATEGORY) s on h.collection_id = s.collection_id
left join (select f.collection_id, f.collection, count(distinct collection_object_id) receivedCatitems, sum(decode(total_parts,null, 1,total_parts)) receivedSpecimens
    	from flat f
    	join accn a on f.ACCN_ID = a.transaction_id
    	join trans t on a.transaction_id = t.transaction_id
    	where a.received_DATE between  to_date('#beginDate#', 'YYYY-MM-DD') and  to_date('#endDate#', 'YYYY-MM-DD')
    	group by f.collection_id, f.collection) a 
	on h.collection_id = a.collection_id
left join (select f.collection_id, f.collection, count(distinct f.collection_object_id) enteredCatItems, sum(decode(total_parts,null, 1,total_parts)) enteredSpecimens 
	from flat f
	join coll_object co on f.collection_object_id = co.collection_object_id
	where co.COLL_OBJECT_ENTERED_DATE between to_date('#beginDate#', 'YYYY-MM-DD') and  to_date('#endDate#', 'YYYY-MM-DD')
	group by f.collection_id, f.collection) e 
	on e.collection_id = h.collection_id
order by collection
</cfquery>

<!-- output formatted data -->

<cfoutput>
	<main class="container-lg mx-auto my-3" id="content">
		<section class="row" >
			<div class="col-12 mt-3">
				<h1 class="h2 px-2">Basic Collections Metrics</h1>
				<table class="table table-responsive table-striped d-lg-table" id="t">
					<thead>
						<tr>
							<th>
								<strong>Collection</strong>
							</th>
							<th>
								<strong>Total Holdings</strong>
							</th>
							<th>
								<strong>% of Holdings in MCZbase</strong>
							</th>
							<th>
								<strong>Total Records - Cataloged Items</strong>
							</th>
                                                        <th>
                                                                <strong>Total Records - Specimens</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Primary Types - Cataloged Items</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Primary Types - Specimens</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Secondary Types - Cataloged Items</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Secondary Types - Specimens</strong>
                                                        </th>
						</tr>
					</thead>
					<tbody>
						<cfloop query="totals">
						<tr>
							<td>#collection#</td>
							<td>&nbsp;</td>
							<td>&nbsp;</td>
							<td>#catalogeditems#</td>
							<td>#specimens#</td>
							<td>#primaryCatItems#</td>
							<td>#primarySpecimens#</td>
							<td>#secondaryCatItems#</td>
							<td>#secondarySpecimens#</td>
						</tr>
						</cfloop>
					</tbody>
				</table>
			</div>
		</section>
	</main>
</cfoutput>




<!-- dump query results for testing -->
<!-- cfdump var="#totals#" -->	


<cfinclude template="/shared/_footer.cfm">
