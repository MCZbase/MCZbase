<cfinclude template="/includes/_header.cfm">
<cfoutput>
    <div style="width: 100%;">
        <div style="width: 54em;margin:0 auto;padding: 1em 0 5em 0;">
<cfset title="Recently Georeferenced Localities">
	<h2>Recently Georeferenced Localities</h2>
	<cfquery name="newgeorefs" datasource="uam_god">
		select l.locality_id, l.spec_locality, f.collection_cde, f.collection_id, to_char(l.GEOREF_UPDATED_DATE, 'YYYY-MM-DD') as GEOREF_UPDATED_DATE, count(*) as cnt
		from locality l, flat f, COLL_OBJECT co
		where l.locality_id = f.locality_id
		and f.collection_object_id = co.collection_object_id
		and GEOREF_UPDATED_DATE is not null and GEOREF_UPDATED_DATE > sysdate - 7
		and GEOREF_UPDATED_DATE - CO.COLL_OBJECT_ENTERED_DATE > 1
		group by l.locality_id, l.spec_locality,f.collection_cde,f.collection_id,l.GEOREF_UPDATED_DATE
	</cfquery>
	<cfquery name="localities" dbtype="query">
		select distinct locality_id, spec_locality,GEOREF_UPDATED_DATE from newgeorefs order by GEOREF_UPDATED_DATE asc
	</cfquery>


	<cfloop query="localities">
	<h4>Locality ID: <a href="../editLocality.cfm?locality_id=#locality_id#">#locality_id#</a><br>
	Specific Locality: #spec_locality#<br>(Georef Date: #GEOREF_UPDATED_DATE#)</h4>
	<cfquery name="colls" dbtype="query">
		select * from newgeorefs where locality_id = #localities.locality_id#
	</cfquery>
	<table border>
			<tr>
				<th>Collection</th>
				<th>## of cataloged items</th>
			</tr>
		<cfloop query="colls">
			<tr>
				<td>#collection_cde#</td>
				<td><a href="../SpecimenResults.cfm?locality_id=#locality_id#&collection_id=#collection_id#">#cnt#</a></td>
			</tr>
		</cfloop>
	</table>
	</cfloop>
</cfoutput>
    </div></div>
<cfinclude template="/includes/_footer.cfm">
