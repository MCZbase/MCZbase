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

<cfset endDate = "2024-07-01">
<cfset beginDate = "2023-06-30">

<!-- annual report queries -->
<cfsetting RequestTimeout = "0">
<cfset start = GetTickCount()>
<cfquery name="totals" datasource="uam_god">
select 
	rm.holdings,
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
	e.enteredSpecimens,
	ncbi.ncbiCatItems,
	accn.numAccns
	  
from 
	(select * from collection where collection_cde <> 'MCZ') c
left join (select * from collections_reported_metrics) rm on c.collection_id = rm.collection_id 
left join (select f.collection_id, f.collection, count(distinct f.collection_object_id) catalogeditems, sum(decode(total_parts,null, 1,total_parts)) specimens
        from flat f
        join coll_object co on f.collection_object_id = co.collection_object_id
        where co.COLL_OBJECT_ENTERED_DATE < to_date('#endDate#', 'YYYY-MM-DD')
        group by f.collection_id, f.collection) h on rm.collection_id = h.collection_id
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
left join (select f.collection_id, f.collection, count(distinct f.collection_object_id) ncbiCatItems, sum(total_parts) ncbiSpecimens 
	from COLL_OBJ_OTHER_ID_NUM oid, flat f, COLL_OBJECT CO 
	where OTHER_ID_TYPE like '%NCBI%'
	AND F.COLLECTION_OBJECT_ID = CO.COLLECTIOn_OBJECT_ID
	and co.COLL_OBJECT_ENTERED_DATE < to_date('#endDate#', 'YYYY-MM-DD')
	and oid.collection_object_id = f.collection_object_id
	group by f.collection_id, f.collection) ncbi on h.collection_id = ncbi.collection_id
left join (select c.collection_id, c.collection, count(distinct t.transaction_id) numAccns
	from accn a, trans t, collection c
	where a.transaction_id = t.transaction_id
	and t.collection_id = c.collection_id
	and a.received_date between to_date('#beginDate#', 'YYYY-MM-DD') and  to_date('#endDate#', 'YYYY-MM-DD')
	group by c.collection_id, c.collection) accn on h.collection_id = accn.collection_id
</cfquery>

<!-- get loans data -->
<cfquery name="loans" datasource="uam_god">
select
	c.collection, 
	ol.numOutgoingLoans,
	ol.outgoingCatItems,
	ol.outgoingSpecimens,
	cl.numClosedLoans,
	fy.num5yrLoans,
	ty.num10yrLoans,
	b.numBorrows,
	opL.numOpenLoans,
	open5.numOpenOD5,
	open10.numOpenOD10
from
	(select * from collection where collection_cde <> 'MCZ') c
left join (select c.collection_id, collection, count(distinct l.transaction_id) numOutgoingLoans, count(distinct sp.derived_from_cat_item) outgoingCatItems, sum(co.lot_count) as outgoingSpecimens
	from loan l, trans t, collection c, loan_item li, specimen_part sp, coll_object co
	where l.transaction_id = t.transaction_id
	and t.collection_id = c.collection_id
	and t.transaction_id = li.transaction_id(+)
	and li.collection_object_id = sp.collection_object_id(+)
	and sp.collection_object_id = co.collection_object_id(+)
	and t.TRANS_DATE between to_date('#beginDate#', 'YYYY-MM-DD') and  to_date('#endDate#', 'YYYY-MM-DD')
	group by c.collection_id, c.collection) ol on c.collection_id = ol.collection_id
left join (select c.collection_id, collection, count(distinct l.transaction_id) numClosedLoans
	from loan l, trans t, collection c, loan_item li, specimen_part sp, coll_object co
	where l.transaction_id = t.transaction_id
	and t.collection_id = c.collection_id
	and t.transaction_id = li.transaction_id(+)
	and li.collection_object_id = sp.collection_object_id(+)
	and sp.collection_object_id = co.collection_object_id(+)
	and l.CLOSED_DATE between to_date('#beginDate#', 'YYYY-MM-DD') and  to_date('#endDate#', 'YYYY-MM-DD')
	group by c.collection_id, collection) cl on c.collection_id = cl.collection_id
left join (select c.collection_id, collection_cde, count(*)as num5yrLoans
	from loan l, trans t, collection c
	where l.transaction_id = t.transaction_id
	and t.collection_id = c.collection_id
	and l.CLOSED_DATE between to_date('#beginDate#', 'YYYY-MM-DD') and  to_date('#endDate#', 'YYYY-MM-DD')
	and l.closed_date -l.return_due_date > (365*5)
	group by c.collection_id, collection_cde) fy on c.collection_id = fy.collection_id
left join (select c.collection_id, collection_cde, count(*) as num10yrLoans
        from loan l, trans t, collection c
        where l.transaction_id = t.transaction_id
        and t.collection_id = c.collection_id
        and l.CLOSED_DATE between to_date('#beginDate#', 'YYYY-MM-DD') and  to_date('#endDate#', 'YYYY-MM-DD')
        and l.closed_date -l.return_due_date > (365*10)
        group by c.collection_id, collection_cde) ty on c.collection_id = ty.collection_id
left join (select c.collection_id, collection, count(*) as numBorrows 
	from borrow l, trans t, collection c
	where l.transaction_id = t.transaction_id
	and t.collection_id = c.collection_id
	and l.RECEIVED_DATE between to_date('#beginDate#', 'YYYY-MM-DD') and  to_date('#endDate#', 'YYYY-MM-DD')
	group by c.collection_id, collection) b on c.collection_id = b.collection_id
left join (select c.collection_id, collection_cde, count(*) as numOpenLoans 
	from loan l, trans t, collection c
	where l.transaction_id = t.transaction_id
	and t.collection_id = c.collection_id
	and (loan_status like '%open%' or closed_date > to_date('#endDate#', 'YYYY-MM-DD'))
	and t.trans_date <  to_date('#endDate#', 'YYYY-MM-DD')
	group by c.collection_id, collection_cde) opL on c.collection_id = opL.collection_id
left join (select c.collection_id, collection, count(*) numOpenOD5 
	from loan l, trans t, collection c
	where l.transaction_id = t.transaction_id
	and t.collection_id = c.collection_id
	and (loan_status like '%open%' or closed_date > to_date('#endDate#', 'YYYY-MM-DD'))
	and t.trans_date < to_date('#endDate#', 'YYYY-MM-DD')
	and to_date('#endDate#', 'YYYY-MM-DD') - l.return_due_date > 365*5
	group by c.collection_id, collection) open5 on c.collection_id = open5.collection_id
left join (select c.collection_id, collection, count(*) numOpenOD10
        from loan l, trans t, collection c
        where l.transaction_id = t.transaction_id
        and t.collection_id = c.collection_id
        and (loan_status like '%open%' or closed_date > to_date('#endDate#', 'YYYY-MM-DD'))
        and t.trans_date < to_date('#endDate#', 'YYYY-MM-DD')
        and to_date('#endDate#', 'YYYY-MM-DD') - l.return_due_date > 365*10
        group by c.collection_id, collection) open10 on c.collection_id = open10.collection_id
order by collection
</cfquery>

<!-- get media data -->

<cfquery name="media" datasource="uam_god">
select
	c.collection,
	i.numImagesCatItems,
	i.numImages,
	p.numPermitsTrans,
	pt.imagesPrimaryCatItems,
	st.imagesSecondaryCatItems
from 
	(select * from collection where collection_cde <> 'MCZ') c
left join (select f.collection_id, f.collection, count(distinct f.collection_object_id) numImagesCatItems, sum(total_parts) numImagesSpecimens, count(distinct m.media_id) numImages
	from media m, MEDIA_RELATIONS mr, flat f, coll_object co 
	where m.media_id = mr.media_id
	and mr.MEDIA_RELATIONSHIP = 'shows cataloged_item'
	and mr.RELATED_PRIMARY_KEY = f.collection_object_id
	and f.collection_object_id = co.collection_object_id
	group by f.collection_id, f.collection) i on c.collection_id = i.collection_id
left join (select c.collection_id, c.collection, count(distinct transaction_id) numPermitsTrans 
	from trans t, collection c where transaction_id in
	(select transaction_id from permit_trans where PERMIT_ID in
	(select related_primary_key from MEDIA_RELATIONS where media_relationship like '%permit'))
	and t.collection_id = c.collection_id
	group by c.collection_id, collection) p on c.collection_id = p.collection_id
left join (select f.collection_id, f.collection, count(distinct f.collection_object_id) imagesPrimaryCatItems, sum(decode(total_parts,null, 1,total_parts)) imagesPrimarySpecimens
	from flat f, citation c, ctcitation_type_status ts
	where f.collection_object_id = c.collection_object_id
	and c.type_status = ts.type_status
	and ts.CATEGORY in ('Primary')
	and f.collection_object_id in
	(select related_primary_key from MEDIA_RELATIONS where media_relationship='shows cataloged_item')
	group by f.collection_id, f.collection) pt on c.collection_id = pt.collection_id
left join (select f.collection_id, f.collection, count(distinct f.collection_object_id) imagesSecondaryCatItems, sum(decode(total_parts,null, 1,total_parts)) imagesSecondarySpecimens
        from flat f, citation c, ctcitation_type_status ts
        where f.collection_object_id = c.collection_object_id
        and c.type_status = ts.type_status
        and ts.CATEGORY in ('Secondary')
        and f.collection_object_id in
        (select related_primary_key from MEDIA_RELATIONS where media_relationship='shows cataloged_item')
        group by f.collection_id, f.collection) st on c.collection_id = st.collection_id

order by collection
</cfquery>

<!-- get georeference data -->

<cfquery name="georefs" datasource="uam_god">
select
	c.collection,
	l.numLocalities,
	gl.numGeoRefdLocalities,
	vgl.numVerGRLocalities,
	gl.numGeoRefdCatItems
from
(select * from collection where collection_cde<>'MCZ') c
left join (select collection_id, collection, count(distinct locality_id) numLocalities 
	from flat
	group by collection_id, collection) l on c.collection_id = l.collection_id
left join (select f.collection_id, f.collection, count(distinct f.collection_object_id) numGeoRefdCatItems, sum(total_parts) numGeoRefdSpecimens, count(distinct locality_id) numGeoRefdLocalities
	from flat f, coll_object co
	where dec_lat is not null and dec_long is not null
	and f.collection_object_id = co.collection_object_id
	group by f.collection_id, f.collection) gl on c.collection_id = gl.collection_id
left join (select f.collection_id, f.collection, count(distinct f.collection_object_id) numVerGRCatItems, sum(total_parts) numVerGRSpecimens, count(distinct locality_id) numVerGRLocalities
        from flat f, coll_object co
        where dec_lat is not null and dec_long is not null
        and f.collection_object_id = co.collection_object_id
	and f.VERIFICATIONSTATUS like 'verified%'
        group by f.collection_id, f.collection) vgl on c.collection_id = vgl.collection_id
</cfquery>

<!-- get citation data -->
<cfquery name="citations" datasource="uam_god">

select
	c.collection,
	cit.numCitations,
	cit.numCitationCatItems
from
(select * from collection where collection_cde <> 'MCZ') c
left join (select coll.collection_id, coll.collection, count(distinct f.collection_object_id) numCitationCatItems, count(*) numCitations 
	from coll_object co,  flat f,  citation c,  publication p, collection coll
	where f.collection_object_id = co.collection_object_id
	and f.collection_object_id = c.collection_object_id 
	and c.publication_id = p.publication_id
	and f.collection_cde = coll.collection_cde
	and p.publication_title not like '%Placeholder%'
	group by coll.collection_id, coll.collection) cit on c.collection_id = cit.collection_id
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
							<td>#holdings#</td>
							<td>#NumberFormat((catalogeditems/holdings)*100, '9.99')#%</td>
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
			<div class="col-12 mt-3">
                                <h1 class="h2 px-2">Basic Collections Metrics (cont.)</h1>
                                <table class="table table-responsive table-striped d-lg-table" id="t">
                                        <thead>
                                                <tr>
                                                        <th>
                                                                <strong>Collection</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Acquired Cataloged Items</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Acquired Specimens</strong>
                                                        </th>
                                                        <th>
                                                                <strong>New Records Entered in MCZbase - Cataloged Items</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Number of Genetic Samples added To Cryo</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Number of Cataloged Items with NCBI numbers</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Number of NCBI numbers added</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Number of Accessions</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Items received but not Cataloged at and of Year</strong>
                                                        </th>
                                                </tr>
                                        </thead>
                                        <tbody>
                                                <cfloop query="totals">
                                                <tr>
                                                        <td>#collection#</td>
                                                        <td>#receivedCatItems#</td>
                                                        <td>#receivedSpecimens#</td>
                                                        <td>#enteredCatItems#</td>
                                                        <td>&nbsp;</td>
                                                        <td>#ncbiCatItems#</td>
                                                        <td>&nbsp;</td>
                                                        <td>#numAccns#</td>
                                                        <td>&nbsp;</td>
                                                </tr>
                                                </cfloop>
                                        </tbody>
                                </table>
                        </div>
 			<div class="col-12 mt-3">
                                <h1 class="h2 px-2">Loan Stats</h1>
                                <table class="table table-responsive table-striped d-lg-table" id="t">
                                        <thead>
                                                <tr>
                                                        <th>
                                                                <strong>Collection</strong>
                                                        </th>
							<th>
                                                                <strong>Outgoing Loans</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Closed Loans</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Closed Overdue (>5 years) Loans</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Closed Overdue (>10 years) Loans</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Incoming loans (=Borrows)</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Number of Open Loans</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Number of Open Loans overdue
> 5 years</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Number of Open Loans overdue
> 10 year</strong>
                                                        </th>
                                                </tr>
                                        </thead>
                                        <tbody>
                                                <cfloop query="loans">
                                                <tr>
                                                        <td>#collection#</td>
                                                        <td>#numOutgoingLoans#</td>
                                                        <td>#numClosedLoans#</td>
                                                        <td>#num5yrLoans#</td>
                                                        <td>#num10yrLoans#</td>
                                                        <td>#numBorrows#</td>
                                                        <td>#numOpenLoans#</td>
                                                        <td>#numOpenOD5#</td>
                                                        <td>#numOpenOD10#</td>
                                                </tr>
                                                </cfloop>
                                        </tbody>
                                </table>
                        </div>
</cfoutput>
<cfoutput>
 			<div class="col-12 mt-3">
                                <h1 class="h2 px-2">Media Stats</h1>
                                <table class="table table-responsive table-striped d-lg-table" id="t">
                                        <thead>
                                                <tr>
                                                        <th>
                                                                <strong>Collection</strong>
                                                        </th>
							<th>
                                                                <strong>Number of Cataloged Items with Media</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Number of Media Items</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Number of Cataloged Items with Media added</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Number of Media Items added</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Number of Transactions with Associated "Permit" Documents</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Number of Transactions with Associated "Permit" Documents in time span</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Number of Primary Types with Images</strong>
                                                        </th>
                                                        <th>
                                                                <strong>% of Primary Types Imaged</strong>
                                                        </th>
							<th>
                                                                <strong>Number of Secondary Types with Images</strong>
                                                        </th>
                                                </tr>
                                        </thead>
                                        <tbody>
                                                <cfloop query="media">
                                                <tr>
                                                        <td>#collection#</td>
                                                        <td>#numImagesCatItems#</td>
                                                        <td>#numImages#</td>
                                                        <td>&nbsp;</td>
                                                        <td>&nbsp;</td>
                                                        <td>#numPermitsTrans#</td>
                                                        <td>&nbsp;</td>
                                                        <td>#imagesPrimaryCatItems#</td>
							<td>&nbsp;</td>
                                                        <td>#imagesSecondaryCatItems#</td>
                                                </tr>
                                                </cfloop>
                                        </tbody>
                                </table>
                        </div>
</cfoutput>
<cfoutput>
			<div class="col-12 mt-3">
                                <h1 class="h2 px-2">Georeference Stats</h1>
                                <table class="table table-responsive table-striped d-lg-table" id="t">
                                        <thead>
                                                <tr>
                                                        <th>
                                                                <strong>Collection</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Total Number of Localities</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Records Georeferenced - Localities</strong>
                                                        </th>
                                                        <th>
                                                                <strong>% of Localities Georeferenced</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Records Georeferences Verified - Localities</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Records Georeferenced Total - Cataloged Items</strong>
                                                        </th>
                                                        <th>
                                                                <strong>% of Cataloged Items Georeferenced</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Records Georeferenced in FY - Localities</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Records Georeferenced in FY - Cataloged Items</strong>
                                                        </th>
                                                </tr>
                                        </thead>
                                        <tbody>
                                                <cfloop query="georefs">
                                                <tr>
                                                        <td>#collection#</td>
                                                        <td>#numLocalities#</td>
                                                        <td>#numGeoRefdLocalities#</td>
                                                        <td>#NumberFormat((numGeoRefdLocalities/numLocalities)*100, '9.99')#%</td>
                                                        <td>#numVerGRLocalities#</td>
                                                        <td>#numGeoRefdCatItems#</td>
                                                        <td>&nbsp;</td>
                                                        <td>&nbsp;</td>
                                                        <td>&nbsp;</td>
                                                </tr>
                                                </cfloop>
                                        </tbody>
                                </table>
                        </div>

			<div class="col-12 mt-3">
                                <h1 class="h2 px-2">Publication Stats</h1>
                                <table class="table table-responsive table-striped d-lg-table" id="t">
                                        <thead>
                                                <tr>
                                                        <th>
                                                                <strong>Collection</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Total Full Citations</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Number of Cataloged Items with Full Citations</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Number of Cataloged Items with Full Citations (w/ogenetic vouchers) added</strong>
                                                        </th>
                                                        <th>
                                                                <strong>Genetic Voucher Citations added </strong>
                                                        </th>
                                                </tr>
                                        </thead>
                                        <tbody>
                                                <cfloop query="citations">
                                                <tr>
                                                        <td>#collection#</td>
                                                        <td>#numCitations#</td>
                                                        <td>#numCitationCatItems#</td>
                                                        <td>&nbsp;</td>
                                                        <td>&nbsp;</td>
                                                </tr>
                                                </cfloop>
                                        </tbody>
                                </table>
                        </div>
		</section>
	</main>
</cfoutput>

<cfoutput>Execution Time: <b>#int(getTickCount()-start)#</b> milliseconds<br></cfoutput>


<!-- dump query results for testing -->
<!-- cfdump var="#totals#" -->	


<cfinclude template="/shared/_footer.cfm">
