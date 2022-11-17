<cfset pageTitle="Bulkloaded Status">
<cfinclude template="/shared/_header.cfm">
<cf_setDataEntryGroups>
<style>
table.stat th {
	cursor: pointer;
}
</style>
<cfquery name="bulkSummary" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select 
		loaded, 
		accn, 
		enteredby, 
		institution_acronym, 
		collection_cde,
		count(*) cnt
	from 
		bulkloader
	where
		upper(institution_acronym || '_' || collection_cde) IN (#ListQualify(inAdminGroups, "'")#)
	group by
		loaded, 
		accn, 
		enteredby, 
		institution_acronym, 
		collection_cde
	order by 
		institution_acronym, 
		collection_cde,
		enteredby
</cfquery>
<cfoutput>
	<div class="container">
		<div class="row">
		<div class="col-12"
	<h3>What's In The Bulkloader:</h3>
	<table class="table" id="t">
		<thead>
			<tr>
				<th>Collection</th>
				<th>Accn</th>
				<th>Entered By</th>
				<th>Status</th>
				<th>Count</th>
			</tr>
		</thead>
		<tbody>
		<cfloop query="bulkSummary">
			<tr>
				<td nowrap="nowrap">#institution_acronym# #collection_cde#</td>
				<td>#accn#</td>
				<td>#EnteredBy#</td>
				<td>#Loaded#</td>
				<td>#cnt#</td>
			</tr>
		</cfloop>
		</tbody>
	</table>
	<script>
		$('th').click(function(){
			var table = $(this).parents('table.stat').eq(0)
			var rows = table.find('tr:gt(0)').toArray().sort(comparer($(this).index()))
			this.asc = !this.asc
			if (!this.asc){rows = rows.reverse()}
			for (var i = 0; i < rows.length; i++){table.append(rows[i])}
		})
		function comparer(index) {
			return function(a, b) {
				var valA = getCellValue(a, index), valB = getCellValue(b, index)
				return $.isNumeric(valA) && $.isNumeric(valB) ? valA - valB : valA.toString().localeCompare(valB)
			}
		}
		function getCellValue(row, index){ return $(row).children('td').eq(index).text() }$('th').click(function(){
			var table = $(this).parents('table.stat').eq(0)
			var rows = table.find('tr:gt(0)').toArray().sort(comparer($(this).index()))
			this.asc = !this.asc
			if (!this.asc){rows = rows.reverse()}
			for (var i = 0; i < rows.length; i++){table.append(rows[i])}
		})
		function comparer(index) {
			return function(a, b) {
				var valA = getCellValue(a, index), valB = getCellValue(b, index)
				return $.isNumeric(valA) && $.isNumeric(valB) ? valA - valB : valA.toString().localeCompare(valB)
			}
		}
		function getCellValue(row, index){ return $(row).children('td').eq(index).text() }
	</script>
<p>&nbsp;</p>
<hr style="height:15px; background-color:red">
<p>&nbsp;</p>
<cfquery name="failures" datasource="uam_god">
	select bulkloader.collection_object_id,
		loaded,
		collection_cde,
		institution_acronym
	from
		bulkloader,
		bulkloader_attempts		
	where
		bulkloader.collection_object_id = B_COLLECTION_OBJECT_ID AND
		loaded <> 'spiffification complete' and
		upper(bulkloader.institution_acronym || '_' || bulkloader.collection_cde) IN (#ListQualify(inAdminGroups, "'")#)
	group by
		bulkloader.collection_object_id,
		loaded,
		collection_cde,
		institution_acronym
	order by
		collection_cde,
		institution_acronym,
		bulkloader.collection_object_id
</cfquery>

	<h3>Failures:</h3> (Loaded="waiting approval" indicates records which have failed to load and then viewed/fixed in the Data Entry application.)
	<table class="table">
		<thead>
			<tr>
				<th>
					Bulkloader ID
				</th>
				<th>Loaded</th>
			</tr>
		</thead>
		<tbody>
			<cfloop query="failures">
				<tr>
					<td>
						<a href="/DataEntry.cfm?ImAGod=yes&action=editEnterData&pMode=edit&collection_object_id=#collection_object_id#">
							#collection_object_id#
						</a>
						 (#institution_acronym# #collection_cde#)
					</td>
					<td>#loaded#</td>
				</tr>
			</cfloop>
		</tbody>
	</table>
<cfquery name="success" datasource="uam_god">
	select bulkloader_attempts.collection_object_id,
		cataloged_item.cat_num,
		collection.collection_cde,
		collection.institution_acronym
	from
		bulkloader_deletes,
		bulkloader_attempts,
		cataloged_item,
		collection	
	where
		bulkloader_deletes.collection_object_id = B_COLLECTION_OBJECT_ID AND
		bulkloader_attempts.collection_object_id = cataloged_item.collection_object_id AND
		cataloged_item.collection_id = collection.collection_id AND
		TSTAMP > ('#dateformat(now()-5,"yyyy-mm-dd")#') and
		upper(bulkloader_deletes.institution_acronym || '_' || bulkloader_deletes.collection_cde) IN (#ListQualify(inAdminGroups, "'")#)
	group by
		bulkloader_attempts.collection_object_id,
		cataloged_item.cat_num,
		collection.collection_cde,
		collection.institution_acronym
	order by
		collection.institution_acronym,
		collection.collection_cde,
		cataloged_item.cat_num
</cfquery>
<p>&nbsp;</p>
<hr style="height:15px; background-color:red">
<p>&nbsp;</p>
<cfset idList = valuelist(success.collection_object_id)>
	<h3>Successfully Loaded in the last Five days:<br>
	<a href="/SpecimenResults.cfm?collection_object_id=#idList#">See All in SpecimenResults</a></h3>
	<table class="table">
		<thead>
			<tr>
				<th>Item</th>
			</tr>
		</thead>
		<tbody>
			<cfloop query="success">
				<tr>
					<td>
						<a href="/SpecimenDetail.cfm?collection_object_id=#collection_object_id#">
							#institution_acronym# #collection_cde# #cat_num#
						</a>
					</td>
				</tr>
			</cfloop>
		</tbody>
	</table>

</cfoutput>
<cfinclude template="/shared/_footer.cfm">