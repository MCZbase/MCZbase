<!--

* /metrics/metrics.cfm

Copyright 2023 President and Fellows of Harvard College

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

<cfset endDate = "SYSDATE">
<cfset beginDate = "ADD_MONTHS(SYSDATE,-12)">

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
        where co.COLL_OBJECT_ENTERED_DATE < sysdate
        group by f.collection_id, f.collection) h
left join  ( select f.collection_id, f.collection, ts.CATEGORY, count(distinct f.collection_object_id) primaryCatItems, sum(decode(total_parts,null, 1,total_parts)) primarySpecimens
        from coll_object co
        join flat f on co.collection_object_id = f.collection_object_id
        join citation c on f.collection_object_id = c.collection_object_id
        join ctcitation_type_status ts on c.type_status =  ts.type_status
        where ts.CATEGORY in ('Primary')
        and co.COLL_OBJECT_ENTERED_DATE < sysdate
        group by f.collection_id, f.collection, ts.CATEGORY) p on h.collection_id = p.collection_id
left join (select f.collection_id, f.collection, ts.CATEGORY, count(distinct f.collection_object_id) secondaryCatItems, sum(decode(total_parts,null, 1,total_parts)) secondarySpecimens
        from coll_object co
        join flat f on co.collection_object_id = f.collection_object_id
        join citation c on f.collection_object_id = c.collection_object_id
        join ctcitation_type_status ts on c.type_status =  ts.type_status
        where ts.CATEGORY in ('Secondary')
        and co.COLL_OBJECT_ENTERED_DATE < sysdate
        group by f.collection_id, f.collection, ts.CATEGORY) s on h.collection_id = s.collection_id
left join (select f.collection_id, f.collection, count(distinct collection_object_id) receivedCatitems, sum(decode(total_parts,null, 1,total_parts)) receivedSpecimens
    	from flat f
    	join accn a on f.ACCN_ID = a.transaction_id
    	join trans t on a.transaction_id = t.transaction_id
    	where a.received_DATE between #beginDate# and #endDate#
    	group by f.collection_id, f.collection) a 
	on h.collection_id = a.collection_id
left join (select f.collection_id, f.collection, count(distinct f.collection_object_id) enteredCatItems, sum(decode(total_parts,null, 1,total_parts)) enteredSpecimens 
	from flat f
	join coll_object co on f.collection_object_id = co.collection_object_id
	where co.COLL_OBJECT_ENTERED_DATE between #beginDate# and #endDate#
	group by f.collection_id, f.collection) e 
	on e.collection_id = h.collection_id
</cfquery>

<cfdump var="#totals#">		


<cfinclude template="/shared/_footer.cfm">
